import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class AuthException extends ApiException {
  AuthException(super.message, [super.statusCode]);
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class ApiErrorHandler {
  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Tempo limite de conexão esgotado');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] ?? 'Erro no servidor';
          if (statusCode == 401 || statusCode == 403) {
            return AuthException(message, statusCode);
          }
          return ApiException(message, statusCode);
        case DioExceptionType.cancel:
          return ApiException('Requisição cancelada');
        default:
          return NetworkException('Erro de conexão com o servidor');
      }
    }
    return ApiException('Ocorreu um erro inesperado');
  }
}
