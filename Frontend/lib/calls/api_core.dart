import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
// api_core.dart
//
// Core configurations for the Dio HTTP client.
// Manages headers required by the DriveConnect backend (x-usuario-id, x-tipo, x-filial-id)
// and handles global error interceptors.
// ─────────────────────────────────────────────────────────────────────────────

final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

// ── Identity store (in-memory) ────────────────────────────────────────────────
String? _usuarioId;
String? _tipo;
String? _filialId;
String? _apiKey = dotenv.env['API_KEY'];

/// Sets the authenticated user identity headers required by the backend.
void setIdentity({
  required String usuarioId,
  required String tipo,
  String? filialId,
}) {
  _usuarioId = usuarioId;
  _tipo = tipo;
  _filialId = filialId;
}

/// Sets the API Key for routes that require it (e.g. storage, payment).
void setApiKey(String apiKey) {
  _apiKey = apiKey;
}

/// Clears current identity (e.g., on logout or session expiration).
void clearIdentity() {
  _usuarioId = null;
  _tipo = null;
  _filialId = null;
}

void Function()? onSessionExpired;

// ── Main Dio client with Interceptor ──────────────────────────────────────────
final Dio dioClient = () {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // The backend `auth.ts` extracts identity from these headers:
        if (_usuarioId != null && _tipo != null) {
          options.headers['x-usuario-id'] = _usuarioId;
          options.headers['x-tipo'] = _tipo;
        }
        if (_filialId != null) {
          options.headers['x-filial-id'] = _filialId;
        }
        if (_apiKey != null) {
          options.headers['x-api-key'] = _apiKey;
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          clearIdentity();
          onSessionExpired?.call();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}();

// ── Helper centralizado para tratar erros do Dio ────────────────────────────
void handleApiError(DioException e, void Function(String) onError) {
  String message = 'Ocorreu um erro inesperado.';

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      message =
          'O servidor demorou muito para responder. Verifique sua conexão.';
      break;
    case DioExceptionType.connectionError:
      message =
          'Não foi possível conectar ao servidor. Verifique se você está conectado à internet.';
      break;
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      if (data is Map) {
        // Tenta pegar a mensagem específica enviada pelo backend
        message = data['erro'] ?? data['error'] ?? data['message'] ?? message;
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
      break;
    case DioExceptionType.cancel:
      message = 'A requisição foi cancelada.';
      break;
    default:
      message = 'Erro na comunicação com o servidor.';
  }

  onError(message);
}
