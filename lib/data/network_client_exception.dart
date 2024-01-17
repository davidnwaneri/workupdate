import 'package:flutter/foundation.dart';

/// {@template network_client_exception}
/// Thrown when a network request fails.
/// {@endtemplate}
class NetworkClientException implements Exception {
  /// {@macro network_client_exception}
  const NetworkClientException(this.message, {this.stackTrace});

  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() => '${describeIdentity(this)}(message: $message)';
}
