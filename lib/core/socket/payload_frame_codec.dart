import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec_worker.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';
import 'package:flutter/foundation.dart' show compute;

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
///   bytes are **strictly smaller** than the raw JSON and stay inside the
///   negotiated inflation guard ("auto" mode used by both the hub and the
///   agent).
/// - Inbound frames are validated against `maxPayloadBytes` and a max
///   inflation ratio, mirroring `PAYLOAD_FRAME_MAX_INFLATION_RATIO` on the
///   server.
/// - [decodeJsonAsync] can offload **gzip decode**, large **gzip encode**
///   ([encodeJsonAsync]), and large **jsonDecode** to worker isolates (see
///   [workerIsolatesEnabled] and the `*IsolateThresholdBytes` fields).
///
/// Defaults match the production hub:
///
/// - 4096-byte compression threshold (`COMPRESSION_THRESHOLD` snippet).
/// - 10 MiB hard cap on both compressed and decoded sizes.
/// - 10x inflation ceiling for gzip payloads.
///
/// Large payloads may use [decodeJsonAsync] / [encodeJsonAsync] so gzip and
/// JSON parsing can run off the UI isolate when thresholds are met and
/// [workerIsolatesEnabled] is true.
class PayloadFrameCodec {
  const PayloadFrameCodec({
    this.compressionThresholdBytes = defaultCompressionThresholdBytes,
    this.maxPayloadBytes = defaultMaxPayloadBytes,
    this.maxInflationRatio = defaultMaxInflationRatio,
    this.minGzipSavingsBytes = defaultMinGzipSavingsBytes,
    this.workerIsolatesEnabled = true,
    this.gzipDecodeIsolateThresholdBytes =
        defaultGzipDecodeIsolateThresholdBytes,
    this.gzipEncodeIsolateThresholdBytes =
        defaultGzipEncodeIsolateThresholdBytes,
    this.jsonDecodeIsolateThresholdBytes =
        defaultJsonDecodeIsolateThresholdBytes,
    this.signer,
    this.verifier,
    this.requireSignature = false,
    this.worker,
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

  /// When non-null, [decodeJson] validates `frame.signature` against
  /// this verifier. Behavior matrix:
  ///
  /// * `verifier == null`            → signature ignored (legacy
  ///   transparent mode; current hub default).
  /// * verifier set, no signature    → accepted UNLESS
  ///   [requireSignature] is `true`.
  /// * verifier set, signature OK    → accepted.
  /// * verifier set, signature bad   → throws
  ///   [PayloadFrameDecodeException] with the verifier code
  ///   (`signature_invalid`, `signature_key_id_mismatch`, etc.) so
  ///   the dispatcher can map it to a transient socket error.
  final PayloadFrameSignatureVerifier? verifier;

  /// Strict mode: when `true` and a [verifier] is configured, frames
  /// without a `signature` block are rejected with
  /// `signature_required`. Use this on builds connecting to hubs that
  /// run with `PAYLOAD_SIGN_OUTBOUND=true` and trust nothing else.
  final bool requireSignature;

  /// Persistent isolate used by async encode/decode above the configured
  /// thresholds. Null keeps the `compute()` / sync fallbacks.
  final PayloadFrameCodecWorker? worker;

  /// 4096 bytes - same value as the snippet bundled with the hub docs.
  static const int defaultCompressionThresholdBytes = 4096;

  /// 10 MiB — server-side cap on compressed and decoded sizes.
  static const int defaultMaxPayloadBytes = 10 * 1024 * 1024;

  /// 10x - server-side gzip inflation guard.
  static const int defaultMaxInflationRatio = 10;

  /// Hub `PAYLOAD_FRAME_AUTO_GZIP_MIN_SAVINGS_BYTES` default — gzip is kept
  /// only when it saves at least this many bytes vs raw JSON UTF-8.
  static const int defaultMinGzipSavingsBytes = 64;

  /// When inbound [PayloadFrame.cmp] is gzip and `payload.length` is at or
  /// above this threshold, [decodeJsonAsync] runs `gzip.decode` via Flutter
  /// `compute` instead of blocking the UI isolate. Sync [decodeJson] always
  /// decodes on the calling isolate (handshake-sized payloads).
  static const int defaultGzipDecodeIsolateThresholdBytes = 16 * 1024;

  /// Raw JSON UTF-8 size at or above this value may use a worker isolate for
  /// outbound `gzip.encode` when [workerIsolatesEnabled] is true.
  static const int defaultGzipEncodeIsolateThresholdBytes = 64 * 1024;

  /// Materialised JSON UTF-8 size at or above this value may use a worker
  /// isolate for `jsonDecode` in [decodeJsonAsync].
  static const int defaultJsonDecodeIsolateThresholdBytes = 256 * 1024;

  final int compressionThresholdBytes;
  final int maxPayloadBytes;
  final int maxInflationRatio;

  /// Minimum byte savings required to keep gzip (`cmp: gzip`) in auto mode.
  /// Aligns with hub `PAYLOAD_FRAME_AUTO_GZIP_MIN_SAVINGS_BYTES` (default 64).
  final int minGzipSavingsBytes;

  /// When `false`, no worker-isolate paths run (gzip encode/decode, JSON
  /// decode) regardless of thresholds.
  final bool workerIsolatesEnabled;

  /// See [defaultGzipDecodeIsolateThresholdBytes].
  final int gzipDecodeIsolateThresholdBytes;

  /// See [defaultGzipEncodeIsolateThresholdBytes].
  final int gzipEncodeIsolateThresholdBytes;

  /// See [defaultJsonDecodeIsolateThresholdBytes].
  final int jsonDecodeIsolateThresholdBytes;

  /// Whether [decodeJsonAsync] would use a worker isolate for gzip inflation
  /// on this [frame], given the codec configuration (for metrics).
  bool usesWorkerIsolateForGzipDecode(PayloadFrame frame) {
    return workerIsolatesEnabled &&
        frame.cmp == PayloadFrame.compressionGzip &&
        frame.payload.length >= gzipDecodeIsolateThresholdBytes;
  }

  /// Whether [decodeJsonAsync] would use a worker isolate for `jsonDecode`
  /// after bytes are materialised (for metrics; uses [PayloadFrame.originalSize]).
  bool usesWorkerIsolateForJsonDecode(PayloadFrame frame) {
    return workerIsolatesEnabled &&
        frame.originalSize >= jsonDecodeIsolateThresholdBytes;
  }

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
      if (_shouldUseCompressed(encoded, compressed)) {
        wire = compressed;
        cmp = PayloadFrame.compressionGzip;
      }
    }

    return _finishEncode(
      encoded: encoded,
      wire: wire,
      cmp: cmp,
      requestId: requestId,
      traceId: traceId,
      signature: signature,
    );
  }

  /// Same contract as [encodeJson], but may run `gzip.encode` on a worker
  /// isolate when the raw JSON is at least [gzipEncodeIsolateThresholdBytes]
  /// and [workerIsolatesEnabled] is true.
  Future<PayloadFrameEncodeResult> encodeJsonAsync(
    Object? data, {
    String? requestId,
    String? traceId,
    PayloadFrameSignature? signature,
  }) async {
    final encoded = await _encodeJsonUtf8MaybeOffload(data);
    if (encoded.length > maxPayloadBytes) {
      throw PayloadFrameDecodeException(
        'payload_too_large',
        'JSON UTF-8 size ${encoded.length} exceeds cap $maxPayloadBytes',
      );
    }

    var wire = encoded;
    var cmp = PayloadFrame.compressionNone;
    if (encoded.length >= compressionThresholdBytes) {
      final Uint8List compressed;
      if (workerIsolatesEnabled &&
          encoded.length >= gzipEncodeIsolateThresholdBytes) {
        compressed = await _gzipEncodeOffload(encoded);
      } else {
        compressed = Uint8List.fromList(gzip.encode(encoded));
      }
      if (_shouldUseCompressed(encoded, compressed)) {
        wire = compressed;
        cmp = PayloadFrame.compressionGzip;
      }
    }

    return _finishEncodeAsync(
      encoded: encoded,
      wire: wire,
      cmp: cmp,
      requestId: requestId,
      traceId: traceId,
      signature: signature,
    );
  }

  PayloadFrameEncodeResult _finishEncode({
    required Uint8List encoded,
    required Uint8List wire,
    required String cmp,
    String? requestId,
    String? traceId,
    PayloadFrameSignature? signature,
  }) {
    // Sign **after** the gzip pass so the HMAC covers the exact bytes
    // the hub will ingest — `validateFrameSignature` on the hub side
    // hashes the wire payload, not the JSON. Caller-provided signature
    // (e.g. tests with a deterministic value) always wins over the
    // codec-level signer.
    final resolvedSignature =
        signature ??
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

  Future<PayloadFrameEncodeResult> _finishEncodeAsync({
    required Uint8List encoded,
    required Uint8List wire,
    required String cmp,
    String? requestId,
    String? traceId,
    PayloadFrameSignature? signature,
  }) async {
    final resolvedSignature =
        signature ??
        await _signWireMaybeOffload(
          encoded: encoded,
          wire: wire,
          cmp: cmp,
          requestId: requestId,
          traceId: traceId,
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

  bool _shouldUseCompressed(Uint8List encoded, Uint8List compressed) {
    if (compressed.isEmpty) {
      return false;
    }
    final savings = encoded.length - compressed.length;
    if (savings < minGzipSavingsBytes) {
      return false;
    }
    return encoded.length / compressed.length <= maxInflationRatio;
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
  ///
  /// Gzip inflation always runs on the **calling** isolate. For large inbound
  /// gzip frames use [decodeJsonAsync].
  Object? decodeJson(PayloadFrame frame) {
    _assertFrameDecodePreconditions(frame);
    final jsonBytes = _materializeJsonBytesSync(frame);
    return _jsonDecodeUtf8(jsonBytes);
  }

  /// Same contract as [decodeJson], but may run `gzip.decode` on a worker
  /// isolate when `cmp == gzip` and the compressed payload length is at
  /// least [gzipDecodeIsolateThresholdBytes].
  Future<Object?> decodeJsonAsync(PayloadFrame frame) async {
    _assertFrameDecodePreconditions(frame, verifySignature: false);
    await _verifySignatureIfConfiguredAsync(frame);
    final jsonBytes = await _materializeJsonBytesAsync(frame);
    if (workerIsolatesEnabled &&
        jsonBytes.length >= jsonDecodeIsolateThresholdBytes) {
      try {
        return await _jsonDecodeUtf8Offload(jsonBytes);
      } on FormatException catch (e) {
        throw PayloadFrameDecodeException('json_decode_failed', e.message);
      }
    }
    return _jsonDecodeUtf8(jsonBytes);
  }

  void _assertFrameDecodePreconditions(
    PayloadFrame frame, {
    bool verifySignature = true,
  }) {
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
    if (frame.cmp == PayloadFrame.compressionGzip) {
      if (frame.originalSize <= 0 || frame.compressedSize <= 0) {
        throw const PayloadFrameDecodeException(
          'invalid_gzip_metadata',
          'gzip frames require positive originalSize and compressedSize',
        );
      }
    }
    if (verifySignature) {
      _verifySignatureIfConfigured(frame);
    }
  }

  Uint8List _materializeJsonBytesSync(PayloadFrame frame) {
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
        final jsonBytes = Uint8List.fromList(gzip.decode(frame.payload));
        if (jsonBytes.length != frame.originalSize) {
          throw PayloadFrameDecodeException(
            'original_size_mismatch',
            'reported ${frame.originalSize}, actual ${jsonBytes.length}',
          );
        }
        return jsonBytes;
      } on FormatException catch (e) {
        throw PayloadFrameDecodeException(
          'gzip_decode_failed',
          e.message,
        );
      } on PayloadFrameDecodeException {
        rethrow;
      } on Object catch (e) {
        throw PayloadFrameDecodeException(
          'gzip_decode_failed',
          e.toString(),
        );
      }
    }
    if (frame.payload.length != frame.originalSize) {
      throw PayloadFrameDecodeException(
        'original_size_mismatch',
        'reported ${frame.originalSize}, actual ${frame.payload.length}',
      );
    }
    return frame.payload;
  }

  Future<Uint8List> _materializeJsonBytesAsync(PayloadFrame frame) async {
    if (frame.cmp != PayloadFrame.compressionGzip) {
      return _materializeJsonBytesSync(frame);
    }
    if (frame.compressedSize > 0 &&
        frame.originalSize / frame.compressedSize > maxInflationRatio) {
      throw PayloadFrameDecodeException(
        'inflation_ratio_exceeded',
        'ratio ${frame.originalSize / frame.compressedSize} '
            '> max $maxInflationRatio',
      );
    }
    final Uint8List jsonBytes;
    if (workerIsolatesEnabled &&
        frame.payload.length >= gzipDecodeIsolateThresholdBytes) {
      try {
        jsonBytes = await _gzipDecodeOffload(frame.payload);
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
    } else {
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
    }
    if (jsonBytes.length != frame.originalSize) {
      throw PayloadFrameDecodeException(
        'original_size_mismatch',
        'reported ${frame.originalSize}, actual ${jsonBytes.length}',
      );
    }
    return jsonBytes;
  }

  Object? _jsonDecodeUtf8(Uint8List jsonBytes) {
    try {
      return jsonDecode(utf8.decode(jsonBytes));
    } on FormatException catch (e) {
      throw PayloadFrameDecodeException('json_decode_failed', e.message);
    }
  }

  Future<Uint8List> _encodeJsonUtf8MaybeOffload(Object? data) async {
    if (workerIsolatesEnabled &&
        worker != null &&
        _estimateJsonUtf8Bytes(data) >= gzipEncodeIsolateThresholdBytes) {
      try {
        return await worker!.jsonEncodeUtf8(data);
      } on PayloadFrameCodecWorkerUnavailable {
        // Fall through to the calling isolate.
      }
    }
    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  Future<Uint8List> _gzipEncodeOffload(Uint8List rawJsonUtf8) async {
    final activeWorker = worker;
    if (activeWorker != null) {
      try {
        return await activeWorker.gzipEncode(rawJsonUtf8);
      } on PayloadFrameCodecWorkerUnavailable {
        // Fall through to compute().
      }
    }
    return compute(_payloadFrameCodecGzipEncode, rawJsonUtf8);
  }

  Future<Uint8List> _gzipDecodeOffload(Uint8List compressed) async {
    final activeWorker = worker;
    if (activeWorker != null) {
      try {
        return await activeWorker.gzipDecode(compressed);
      } on PayloadFrameCodecWorkerUnavailable {
        // Fall through to compute().
      }
    }
    return compute(_payloadFrameCodecGzipDecode, compressed);
  }

  Future<Object?> _jsonDecodeUtf8Offload(Uint8List jsonBytes) async {
    final activeWorker = worker;
    if (activeWorker != null) {
      try {
        return await activeWorker.jsonDecodeUtf8(jsonBytes);
      } on PayloadFrameCodecWorkerUnavailable {
        // Fall through to compute().
      }
    }
    return compute(_payloadFrameCodecJsonDecodeUtf8, jsonBytes);
  }

  Future<PayloadFrameSignature?> _signWireMaybeOffload({
    required Uint8List encoded,
    required Uint8List wire,
    required String cmp,
    String? requestId,
    String? traceId,
  }) async {
    final activeSigner = signer;
    if (activeSigner == null) {
      return null;
    }
    final metadata = PayloadFrameSignatureMetadata(
      schemaVersion: PayloadFrame.supportedSchemaVersion,
      enc: PayloadFrame.supportedEncoding,
      cmp: cmp,
      contentType: PayloadFrame.supportedContentType,
      originalSize: encoded.length,
      compressedSize: wire.length,
      traceId: traceId,
      requestId: requestId,
    );
    final activeWorker = worker;
    if (activeWorker != null &&
        workerIsolatesEnabled &&
        wire.length >= gzipEncodeIsolateThresholdBytes) {
      try {
        return await activeWorker.hmacSign(
          metadata: metadata,
          binaryPayload: wire,
        );
      } on PayloadFrameCodecWorkerUnavailable {
        // Fall through to the calling isolate.
      }
    }
    return activeSigner.sign(metadata: metadata, binaryPayload: wire);
  }

  Future<void> _verifySignatureIfConfiguredAsync(PayloadFrame frame) async {
    final activeVerifier = verifier;
    if (activeVerifier == null) {
      if (requireSignature) {
        throw const PayloadFrameDecodeException(
          'signature_required',
          'requireSignature is true but no verifier is configured',
        );
      }
      return;
    }
    final activeWorker = worker;
    if (activeWorker != null &&
        workerIsolatesEnabled &&
        frame.payload.length >= gzipDecodeIsolateThresholdBytes) {
      try {
        final outcome = await activeWorker.hmacVerify(
          metadata: PayloadFrameSignatureMetadata(
            schemaVersion: frame.schemaVersion,
            enc: frame.enc,
            cmp: frame.cmp,
            contentType: frame.contentType,
            originalSize: frame.originalSize,
            compressedSize: frame.compressedSize,
            traceId: frame.traceId,
            requestId: frame.requestId,
          ),
          binaryPayload: frame.payload,
          signature: frame.signature,
        );
        _throwIfSignatureRejected(frame, outcome);
        return;
      } on PayloadFrameCodecWorkerUnavailable {
        // Fall through to the calling isolate.
      }
    }
    _verifySignatureIfConfigured(frame);
  }

  void _throwIfSignatureRejected(
    PayloadFrame frame,
    PayloadFrameSignatureVerification outcome,
  ) {
    switch (outcome) {
      case PayloadFrameSignatureVerification.valid:
        return;
      case PayloadFrameSignatureVerification.absent:
        if (requireSignature) {
          throw const PayloadFrameDecodeException(
            'signature_required',
            'PayloadFrame is unsigned but requireSignature is true',
          );
        }
        return;
      case PayloadFrameSignatureVerification.unsupportedAlgorithm:
        throw PayloadFrameDecodeException(
          outcome.code,
          'expected ${PayloadFrameSignature.algorithmHmacSha256}, '
          'got ${frame.signature?.algorithm}',
        );
      case PayloadFrameSignatureVerification.malformed:
        throw PayloadFrameDecodeException(
          outcome.code,
          'signature value is empty or not valid base64',
        );
      case PayloadFrameSignatureVerification.keyIdMismatch:
        throw PayloadFrameDecodeException(
          outcome.code,
          'signature key_id does not match the configured expectation',
        );
      case PayloadFrameSignatureVerification.invalid:
        throw PayloadFrameDecodeException(
          outcome.code,
          'HMAC mismatch — possible tampering or key drift',
        );
    }
  }

  int _estimateJsonUtf8Bytes(Object? data) {
    final budget = gzipEncodeIsolateThresholdBytes;
    var total = 0;
    void walk(Object? value) {
      if (total >= budget) {
        return;
      }
      if (value == null) {
        total += 4;
        return;
      }
      if (value is String) {
        total += value.length + 2;
        return;
      }
      if (value is num || value is bool) {
        total += 8;
        return;
      }
      if (value is Iterable && value is! Map) {
        total += 2;
        for (final Object? item in value) {
          walk(item);
          if (total >= budget) {
            return;
          }
        }
        return;
      }
      if (value is Map) {
        total += 2;
        for (final entry in value.entries) {
          total += entry.key.toString().length + 3;
          walk(entry.value);
          if (total >= budget) {
            return;
          }
        }
        return;
      }
      total += 16;
    }

    walk(data);
    return total;
  }

  /// Runs the configured [verifier] against [frame] and turns any
  /// rejection into a [PayloadFrameDecodeException] using the stable
  /// codes from [PayloadFrameSignatureVerification]. No-op when no
  /// verifier is wired (current default — signing is opt-in on the
  /// hub).
  void _verifySignatureIfConfigured(PayloadFrame frame) {
    final activeVerifier = verifier;
    if (activeVerifier == null) {
      if (requireSignature) {
        throw const PayloadFrameDecodeException(
          'signature_required',
          'requireSignature is true but no verifier is configured',
        );
      }
      return;
    }
    final outcome = activeVerifier.verify(
      metadata: PayloadFrameSignatureMetadata(
        schemaVersion: frame.schemaVersion,
        enc: frame.enc,
        cmp: frame.cmp,
        contentType: frame.contentType,
        originalSize: frame.originalSize,
        compressedSize: frame.compressedSize,
        traceId: frame.traceId,
        requestId: frame.requestId,
      ),
      binaryPayload: frame.payload,
      signature: frame.signature,
    );
    _throwIfSignatureRejected(frame, outcome);
  }
}

/// Top-level worker for Flutter `compute` — isolate must not capture codec state.
Uint8List _payloadFrameCodecGzipDecode(Uint8List compressed) {
  return Uint8List.fromList(gzip.decode(compressed));
}

Uint8List _payloadFrameCodecGzipEncode(Uint8List rawJsonUtf8) {
  return Uint8List.fromList(gzip.encode(rawJsonUtf8));
}

Object? _payloadFrameCodecJsonDecodeUtf8(Uint8List jsonBytes) {
  return jsonDecode(utf8.decode(jsonBytes));
}
