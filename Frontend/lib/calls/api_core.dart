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
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      onError('Tempo de conexão esgotado. Verifique sua internet.');
      break;
    case DioExceptionType.connectionError:
      onError('Sem conexão com o servidor. Verifique sua internet.');
      break;
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      final serverMsg = body is Map
          ? (body['erro'] ?? body['error'] ?? body['message'])?.toString()
          : null;
          
      switch (statusCode) {
        case 400:
          onError(serverMsg ?? 'Dados inválidos. Verifique os campos e tente novamente.');
          break;
        case 401:
          onError(serverMsg ?? 'Credenciais inválidas ou sessão expirada.');
          break;
        case 403:
          onError(serverMsg ?? 'Sem permissão para acessar este recurso.');
          break;
        case 404:
          onError(serverMsg ?? 'Recurso não encontrado.');
          break;
        default:
          onError(serverMsg ?? 'Erro inesperado (código $statusCode).');
      }
      break;
    default:
      onError('Erro inesperado na requisição.');
  }
}
