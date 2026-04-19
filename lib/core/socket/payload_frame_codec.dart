import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';

/// Result of encoding a logical JSON value into a [PayloadFrame].
class PayloadFrameEncodeResult {
  const PayloadFrameEncodeResult({
    required this.frame,
    required this.encoded,
  });

  /// The wire envelope.
  final PayloadFrame frame;

  /// JSON UTF-8 bytes **before** any gzip pass. Useful for tests and metrics.
  final Uint8List encoded;
}

/// Strict failure surfaced by [PayloadFrameCodec.decodeJson]. The dispatcher
/// (PR-L) maps it to a transient `SocketDispatchException`.
class PayloadFrameDecodeException implements Exception {
  const PayloadFrameDecodeException(this.code, this.message);

  /// Stable identifier consumable by metrics / Sentry breadcrumbs without
  /// leaking payload bytes.
  final String code;

  final String message;

  @override
  String toString() => 'PayloadFrameDecodeException($code): $message';
}

/// Encode/decode pipeline for [PayloadFrame] aligned with the hub contract
/// described in `plug_server/docs/socket_client_sdk.md`:
///
/// - JSON UTF-8 below `compressionThresholdBytes` is emitted with `cmp: none`.
/// - Above the threshold, gzip is attempted and only kept when the resulting
///   bytes are **strictly smaller** than the raw JSON ("auto" mode used by
///   both the hub and the agent).
/// - Inbound frames are validated against `maxPayloadBytes` and a max
///   inflation ratio, mirroring `PAYLOAD_FRAME_MAX_INFLATION_RATIO` on the
///   server.
///
/// Defaults match the production hub:
///
/// - 1 KiB compression threshold (`COMPRESSION_THRESHOLD` snippet).
/// - 10 MiB hard cap on both compressed and decoded sizes.
/// - 20× inflation ceiling for gzip payloads.
class PayloadFrameCodec {
  const PayloadFrameCodec({
    this.compressionThresholdBytes = defaultCompressionThresholdBytes,
    this.maxPayloadBytes = defaultMaxPayloadBytes,
    this.maxInflationRatio = defaultMaxInflationRatio,
    this.signer,
  });

  /// When non-null, [encodeJson] populates `frame.signature` by running
  /// the resulting wire-bytes through this signer. Mirrors the hub's
  /// `PAYLOAD_SIGN_OUTBOUND` switch — leaving it `null` keeps the
  /// envelope unsigned, which is the default the hub also accepts when
  /// `PAYLOAD_SIGNING_KEY` is not configured.
  ///
  /// A caller-supplied `signature` (passed directly to [encodeJson])
  /// always wins over the codec-level signer so tests / one-off
  /// fixtures can inject deterministic values.
  final PayloadFrameSigner? signer;

  /// 1 KiB — same value as the snippet bundled with the hub docs.
  static const int defaultCompressionThresholdBytes = 1024;

  /// 10 MiB — server-side cap on compressed and decoded sizes.
  static const int defaultMaxPayloadBytes = 10 * 1024 * 1024;

  /// 20× — server-side gzip inflation guard.
  static const int defaultMaxInflationRatio = 20;

  final int compressionThresholdBytes;
  final int maxPayloadBytes;
  final int maxInflationRatio;

  /// Encodes [data] with auto-gzip selection.
  ///
  /// Throws [PayloadFrameDecodeException] (`code: payload_too_large`) when the
  /// JSON UTF-8 byte size exceeds [maxPayloadBytes]. Compression is only
  /// activated when it strictly reduces the byte count past
  /// [compressionThresholdBytes].
  PayloadFrameEncodeResult encodeJson(
    Object? data, {
    String? requestId,
    String? traceId,
    PayloadFrameSignature? signature,
  }) {
    final encoded = Uint8List.fromList(utf8.encode(jsonEncode(data)));
    if (encoded.length > maxPayloadBytes) {
      throw PayloadFrameDecodeException(
        'payload_too_large',
        'JSON UTF-8 size ${encoded.length} exceeds cap $maxPayloadBytes',
      );
    }

    var wire = encoded;
    var cmp = PayloadFrame.compressionNone;
    if (encoded.length >= compressionThresholdBytes) {
      final compressed = Uint8List.fromList(gzip.encode(encoded));
      if (compressed.length < encoded.length) {
        wire = compressed;
        cmp = PayloadFrame.compressionGzip;
      }
    }

    // Sign **after** the gzip pass so the HMAC covers the exact bytes
    // the hub will ingest — `validateFrameSignature` on the hub side
    // hashes the wire payload, not the JSON. Caller-provided signature
    // (e.g. tests with a deterministic value) always wins over the
    // codec-level signer.
    final resolvedSignature = signature ??
        signer?.sign(
          metadata: PayloadFrameSignatureMetadata(
            schemaVersion: PayloadFrame.supportedSchemaVersion,
            enc: PayloadFrame.supportedEncoding,
            cmp: cmp,
            contentType: PayloadFrame.supportedContentType,
            originalSize: encoded.length,
            compressedSize: wire.length,
            traceId: traceId,
            requestId: requestId,
          ),
          binaryPayload: wire,
        );

    return PayloadFrameEncodeResult(
      frame: PayloadFrame(
        payload: wire,
        originalSize: encoded.length,
        compressedSize: wire.length,
        cmp: cmp,
        requestId: requestId,
        traceId: traceId,
        signature: resolvedSignature,
      ),
      encoded: encoded,
    );
  }

  /// Validates [frame] and returns the decoded JSON value (`Map`, `List`,
  /// `String`, `num`, `bool`, `null`).
  ///
  /// Throws [PayloadFrameDecodeException] when:
  ///
  /// - schema fields disagree with the supported contract;
  /// - sizes exceed [maxPayloadBytes];
  /// - reported sizes do not match actual byte lengths (defence against
  ///   tampering / truncated transfers);
  /// - gzip output exceeds [maxInflationRatio] times the compressed size;
  /// - the inner UTF-8 stream is not valid JSON.
  Object? decodeJson(PayloadFrame frame) {
    if (frame.schemaVersion != PayloadFrame.supportedSchemaVersion) {
      throw PayloadFrameDecodeException(
        'unsupported_schema_version',
        'expected ${PayloadFrame.supportedSchemaVersion}, '
            'got ${frame.schemaVersion}',
      );
    }
    if (frame.enc != PayloadFrame.supportedEncoding) {
      throw PayloadFrameDecodeException(
        'unsupported_encoding',
        'expected ${PayloadFrame.supportedEncoding}, got ${frame.enc}',
      );
    }
    if (frame.contentType != PayloadFrame.supportedContentType) {
      throw PayloadFrameDecodeException(
        'unsupported_content_type',
        'expected ${PayloadFrame.supportedContentType}, '
            'got ${frame.contentType}',
      );
    }
    if (frame.cmp != PayloadFrame.compressionNone &&
        frame.cmp != PayloadFrame.compressionGzip) {
      throw PayloadFrameDecodeException(
        'unsupported_compression',
        'expected none|gzip, got ${frame.cmp}',
      );
    }
    if (frame.compressedSize != frame.payload.length) {
      throw PayloadFrameDecodeException(
        'compressed_size_mismatch',
        'reported ${frame.compressedSize}, '
            'actual ${frame.payload.length}',
      );
    }
    if (frame.compressedSize > maxPayloadBytes) {
      throw PayloadFrameDecodeException(
        'payload_too_large',
        'compressed size ${frame.compressedSize} exceeds cap $maxPayloadBytes',
      );
    }
    if (frame.originalSize > maxPayloadBytes) {
      throw PayloadFrameDecodeException(
        'payload_too_large',
        'original size ${frame.originalSize} exceeds cap $maxPayloadBytes',
      );
    }

    Uint8List jsonBytes;
    if (frame.cmp == PayloadFrame.compressionGzip) {
      if (frame.compressedSize > 0 &&
          frame.originalSize / frame.compressedSize > maxInflationRatio) {
        throw PayloadFrameDecodeException(
          'inflation_ratio_exceeded',
          'ratio ${frame.originalSize / frame.compressedSize} '
              '> max $maxInflationRatio',
        );
      }
      try {
        jsonBytes = Uint8List.fromList(gzip.decode(frame.payload));
      } on FormatException catch (e) {
        throw PayloadFrameDecodeException(
          'gzip_decode_failed',
          e.message,
        );
      } on Object catch (e) {
        throw PayloadFrameDecodeException(
          'gzip_decode_failed',
          e.toString(),
        );
      }
      if (jsonBytes.length != frame.originalSize) {
        throw PayloadFrameDecodeException(
          'original_size_mismatch',
          'reported ${frame.originalSize}, actual ${jsonBytes.length}',
        );
      }
    } else {
      if (frame.payload.length != frame.originalSize) {
        throw PayloadFrameDecodeException(
          'original_size_mismatch',
          'reported ${frame.originalSize}, actual ${frame.payload.length}',
        );
      }
      jsonBytes = frame.payload;
    }

    try {
      return jsonDecode(utf8.decode(jsonBytes));
    } on FormatException catch (e) {
      throw PayloadFrameDecodeException('json_decode_failed', e.message);
    }
  }
}
