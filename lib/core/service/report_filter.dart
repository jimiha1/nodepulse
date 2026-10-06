import 'dart:io';

import 'package:dio/dio.dart';
import 'package:nodepulse/data/model/app/error.dart';

/// Whether an error is a defect in this app, or the network's or the user's
/// account's doing: a host that does not answer, credentials it refuses.
abstract final class ReportFilter {
  static bool isDefect(Object error) => switch (error) {
    SocketException() || HandshakeException() => false,
    DioException(:final type) => !_dioNetwork.contains(type),
    RemoteBackupPasswordMissing() => false,
    _ => true,
  };

  static const _dioNetwork = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.badCertificate,
  };
}
