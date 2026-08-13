import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_signer.dart';

/// Long-lived isolate that runs gzip/JSON/HMAC jobs for PayloadFrameCodec.
///
/// Spawn is lazy ([ensureStarted]); [dispose] kills the isolate and is
/// idempotent. If spawn fails, jobs throw [PayloadFrameCodecWorkerUnavailable]
/// so the codec can fall back to `compute()` / sync.
class PayloadFrameCodecWorker {
  PayloadFrameCodecWorker({Uint8List? hmacKey, String? hmacKeyId})
    : _hmacKey = hmacKey,
      _hmacKeyId = hmacKeyId;

  final Uint8List? _hmacKey;
  final String? _hmacKeyId;

  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _replies;
  StreamSubscription<dynamic>? _replySub;
  Future<void>? _start;
  var _disposed = false;
  var _nextJobId = 0;
  var _jobsSubmitted = 0;
  final Map<int, Completer<Object?>> _pending = <int, Completer<Object?>>{};

  /// Number of jobs submitted since construction (tests / metrics).
  int get jobsSubmitted => _jobsSubmitted;

  bool get isAlive => !_disposed && _commands != null;

  Future<void> ensureStarted() {
    if (_disposed) {
      return Future<void>.error(
        const PayloadFrameCodecWorkerUnavailable('worker is disposed'),
      );
    }
    return _start ??= _startIsolate();
  }

  Future<Uint8List> gzipEncode(Uint8List raw) {
    return _submit<Uint8List>(_WorkerJobKind.gzipEncode, <String, Object?>{
      'bytes': raw,
    });
  }

  Future<Uint8List> gzipDecode(Uint8List compressed) {
    return _submit<Uint8List>(_WorkerJobKind.gzipDecode, <String, Object?>{
      'bytes': compressed,
    });
  }

  Future<Object?> jsonDecodeUtf8(Uint8List jsonBytes) {
    return _submit<Object?>(_WorkerJobKind.jsonDecodeUtf8, <String, Object?>{
      'bytes': jsonBytes,
    });
  }

  Future<Uint8List> jsonEncodeUtf8(Object? data) {
    return _submit<Uint8List>(_WorkerJobKind.jsonEncodeUtf8, <String, Object?>{
      'data': data,
    });
  }

  Future<PayloadFrameSignature> hmacSign({
    required PayloadFrameSignatureMetadata metadata,
    required Uint8List binaryPayload,
  }) async {
    if (_hmacKey == null) {
      throw const PayloadFrameCodecWorkerUnavailable(
        'worker has no HMAC key',
      );
    }
    final map = await _submit<Map<Object?, Object?>>(
      _WorkerJobKind.hmacSign,
      <String, Object?>{
        'metadata': _metadataToMap(metadata),
        'bytes': binaryPayload,
      },
    );
    return PayloadFrameSignature(
      algorithm: map['algorithm']!.toString(),
      value: map['value']!.toString(),
      keyId: map['keyId']?.toString(),
    );
  }

  Future<PayloadFrameSignatureVerification> hmacVerify({
    required PayloadFrameSignatureMetadata metadata,
    required Uint8List binaryPayload,
    required PayloadFrameSignature? signature,
  }) async {
    if (_hmacKey == null) {
      throw const PayloadFrameCodecWorkerUnavailable(
        'worker has no HMAC key',
      );
    }
    final code = await _submit<String>(
      _WorkerJobKind.hmacVerify,
      <String, Object?>{
        'metadata': _metadataToMap(metadata),
        'bytes': binaryPayload,
        'signature': signature == null
            ? null
            : <String, Object?>{
                'algorithm': signature.algorithm,
                'value': signature.value,
                'keyId': signature.keyId,
              },
      },
    );
    return PayloadFrameSignatureVerification.values.firstWhere(
      (value) => value.code == code,
      orElse: () => PayloadFrameSignatureVerification.invalid,
    );
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _start = null;
    _commands = null;
    final replySub = _replySub;
    _replySub = null;
    if (replySub != null) {
      unawaited(replySub.cancel());
    }
    _replies?.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    final pending = List<Completer<Object?>>.of(_pending.values);
    _pending.clear();
    for (final completer in pending) {
      completer.completeError(
        const PayloadFrameCodecWorkerUnavailable('worker disposed'),
      );
    }
  }

  Future<void> _startIsolate() async {
    final replies = ReceivePort();
    _replies = replies;
    final handshake = Completer<SendPort>();
    _replySub = replies.listen((message) {
      if (!handshake.isCompleted && message is SendPort) {
        handshake.complete(message);
        return;
      }
      _onReply(message);
    });
    try {
      final isolate = await Isolate.spawn(
        _payloadFrameCodecWorkerMain,
        replies.sendPort,
      );
      _isolate = isolate;
      _commands = await handshake.future;
    } on Object {
      await _replySub?.cancel();
      _replySub = null;
      replies.close();
      _replies = null;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _commands = null;
      _start = null;
      rethrow;
    }
  }

  void _onReply(Object? raw) {
    if (raw is! Map) {
      return;
    }
    final id = raw['id'];
    if (id is! int) {
      return;
    }
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) {
      return;
    }
    if (raw['ok'] == true) {
      completer.complete(raw['value']);
      return;
    }
    final type = raw['errorType']?.toString();
    final message = raw['error']?.toString() ?? 'worker job failed';
    if (type == 'FormatException') {
      completer.completeError(FormatException(message));
      return;
    }
    completer.completeError(PayloadFrameCodecWorkerUnavailable(message));
  }

  Future<T> _submit<T>(
    _WorkerJobKind kind,
    Map<String, Object?> payload,
  ) async {
    if (_disposed) {
      throw const PayloadFrameCodecWorkerUnavailable('worker is disposed');
    }
    try {
      await ensureStarted();
    } on Object {
      throw const PayloadFrameCodecWorkerUnavailable('worker failed to spawn');
    }
    final commands = _commands;
    if (commands == null) {
      throw const PayloadFrameCodecWorkerUnavailable('worker is not running');
    }
    final id = _nextJobId++;
    _jobsSubmitted += 1;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    try {
      commands.send(<String, Object?>{
        'id': id,
        'kind': kind.name,
        'hmacKey': _hmacKey,
        'hmacKeyId': _hmacKeyId,
        ...payload,
      });
    } on Object catch (error) {
      _pending.remove(id);
      throw PayloadFrameCodecWorkerUnavailable(
        'worker job is not isolate-sendable: $error',
      );
    }
    final value = await completer.future;
    return value as T;
  }

  static Map<String, Object?> _metadataToMap(
    PayloadFrameSignatureMetadata metadata,
  ) {
    return <String, Object?>{
      'schemaVersion': metadata.schemaVersion,
      'enc': metadata.enc,
      'cmp': metadata.cmp,
      'contentType': metadata.contentType,
      'originalSize': metadata.originalSize,
      'compressedSize': metadata.compressedSize,
      'traceId': metadata.traceId,
      'requestId': metadata.requestId,
    };
  }
}

/// Thrown when the persistent worker cannot run a job.
class PayloadFrameCodecWorkerUnavailable implements Exception {
  const PayloadFrameCodecWorkerUnavailable(this.message);

  final String message;

  @override
  String toString() => 'PayloadFrameCodecWorkerUnavailable: $message';
}

enum _WorkerJobKind {
  gzipEncode,
  gzipDecode,
  jsonDecodeUtf8,
  jsonEncodeUtf8,
  hmacSign,
  hmacVerify,
}

void _payloadFrameCodecWorkerMain(SendPort handshake) {
  final incoming = ReceivePort();
  handshake.send(incoming.sendPort);
  incoming.listen((raw) {
    if (raw is! Map) {
      return;
    }
    final id = raw['id'];
    final kindName = raw['kind']?.toString();
    if (id is! int || kindName == null) {
      return;
    }
    try {
      final value = _runWorkerJob(kindName, raw);
      handshake.send(<String, Object?>{
        'id': id,
        'ok': true,
        'value': value,
      });
    } on FormatException catch (error) {
      handshake.send(<String, Object?>{
        'id': id,
        'ok': false,
        'errorType': 'FormatException',
        'error': error.message,
      });
    } on Object catch (error) {
      handshake.send(<String, Object?>{
        'id': id,
        'ok': false,
        'errorType': error.runtimeType.toString(),
        'error': error.toString(),
      });
    }
  });
}

Object? _runWorkerJob(String kindName, Map<Object?, Object?> message) {
  final kind = _WorkerJobKind.values.firstWhere(
    (value) => value.name == kindName,
  );
  switch (kind) {
    case _WorkerJobKind.gzipEncode:
      return Uint8List.fromList(gzip.encode(_requireBytes(message['bytes'])));
    case _WorkerJobKind.gzipDecode:
      return Uint8List.fromList(gzip.decode(_requireBytes(message['bytes'])));
    case _WorkerJobKind.jsonDecodeUtf8:
      return jsonDecode(utf8.decode(_requireBytes(message['bytes'])));
    case _WorkerJobKind.jsonEncodeUtf8:
      return Uint8List.fromList(utf8.encode(jsonEncode(message['data'])));
    case _WorkerJobKind.hmacSign:
      return _hmacSignJob(message);
    case _WorkerJobKind.hmacVerify:
      return _hmacVerifyJob(message);
  }
}

Uint8List _requireBytes(Object? raw) {
  if (raw is Uint8List) {
    return raw;
  }
  if (raw is List<int>) {
    return Uint8List.fromList(raw);
  }
  throw const FormatException('worker job is missing bytes');
}

PayloadFrameSignatureMetadata _metadataFromMap(Object? raw) {
  if (raw is! Map) {
    throw const FormatException('worker job is missing metadata');
  }
  final map = raw.map(
    (key, value) => MapEntry<String, Object?>(key.toString(), value),
  );
  final originalSize = map['originalSize'];
  final compressedSize = map['compressedSize'];
  if (originalSize is! num || compressedSize is! num) {
    throw const FormatException('worker job metadata is missing sizes');
  }
  return PayloadFrameSignatureMetadata(
    schemaVersion: map['schemaVersion']!.toString(),
    enc: map['enc']!.toString(),
    cmp: map['cmp']!.toString(),
    contentType: map['contentType']!.toString(),
    originalSize: originalSize.toInt(),
    compressedSize: compressedSize.toInt(),
    traceId: map['traceId']?.toString(),
    requestId: map['requestId']?.toString(),
  );
}

Map<String, Object?> _hmacSignJob(Map<Object?, Object?> message) {
  final key = _requireBytes(message['hmacKey']);
  final keyId = message['hmacKeyId']?.toString();
  final signer = Hmac256PayloadFrameSigner(key: key, keyId: keyId);
  final signature = signer.sign(
    metadata: _metadataFromMap(message['metadata']),
    binaryPayload: _requireBytes(message['bytes']),
  );
  return <String, Object?>{
    'algorithm': signature.algorithm,
    'value': signature.value,
    'keyId': signature.keyId,
  };
}

String _hmacVerifyJob(Map<Object?, Object?> message) {
  final key = _requireBytes(message['hmacKey']);
  final keyId = message['hmacKeyId']?.toString();
  final verifier = Hmac256PayloadFrameSignatureVerifier(
    key: key,
    expectedKeyId: keyId,
  );
  final rawSignature = message['signature'];
  PayloadFrameSignature? signature;
  if (rawSignature is Map) {
    signature = PayloadFrameSignature(
      algorithm: rawSignature['algorithm']!.toString(),
      value: rawSignature['value']!.toString(),
      keyId: rawSignature['keyId']?.toString(),
    );
  }
  return verifier
      .verify(
        metadata: _metadataFromMap(message['metadata']),
        binaryPayload: _requireBytes(message['bytes']),
        signature: signature,
      )
      .code;
}
