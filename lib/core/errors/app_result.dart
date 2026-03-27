import 'package:colmeia/core/errors/app_failure.dart';
import 'package:result_dart/result_dart.dart';

typedef AppResult<S extends Object> = ResultDart<S, AppFailure>;
