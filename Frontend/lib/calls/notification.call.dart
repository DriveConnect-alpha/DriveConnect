import 'package:dio/dio.dart';
import './api_core.dart';

/// Sends the FCM device token to the backend.
Future<void> saveFcmToken({
  required String token,
  String? plataforma,
  String? deviceId,
  void Function(String)? onError,
  void Function()? onSuccess,
}) async {
  try {
    final response = await dioClient.post(
      '/notificacoes/token',
      data: {
        'token': token,
        'plataforma': plataforma,
        'deviceId': deviceId,
      },
    );

    if (response.statusCode == 200) {
      onSuccess?.call();
    }
  } on DioException catch (e) {
    handleApiError(e, onError ?? (_) {});
  }
}

/// Removes the FCM device token from the backend.
Future<void> removeFcmToken({
  required String token,
  void Function(String)? onError,
  void Function()? onSuccess,
}) async {
  try {
    final response = await dioClient.delete(
      '/notificacoes/token',
      data: {
        'token': token,
      },
    );

    if (response.statusCode == 200) {
      onSuccess?.call();
    }
  } on DioException catch (e) {
    handleApiError(e, onError ?? (_) {});
  }
}
