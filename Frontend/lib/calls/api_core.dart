import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
// api_core.dart
//
// Core configurations for the Dio HTTP client.
// Uses JWT (Authorization: Bearer) for authentication and x-api-key for
// API-level access control. Both are required by the DriveConnect backend.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';

String get _defaultBaseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

String get _actualBaseUrl {
  String url = dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    // Se o usuário colocou 'localhost' no .env, trocamos por '10.0.2.2' para o Android Emulator
    return url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
  }
  return url;
}

/// Returns the dynamic base URL configured for the current environment.
String get apiBaseUrl => _actualBaseUrl;

// ── Identity store (in-memory) ────────────────────────────────────────────────
String? _jwtToken;
String? _usuarioId;
String? _tipo;
String? _perfilId;
String? _filialId;
String? _apiKey; // Se nulo, tentará pegar do dotenv no interceptor

/// Sets the authenticated user identity.
/// Called after successful login with the JWT token from backend.
void setIdentity({
  required String token,
  required String usuarioId,
  required String tipo,
  String? perfilId,
  String? filialId,
}) {
  _jwtToken = token;
  _usuarioId = usuarioId;
  _tipo = tipo;
  _perfilId = perfilId;
  _filialId = filialId;
}

/// Getters for identity data (used by providers/screens)
String? get currentUserId => _usuarioId;
String? get currentUserTipo => _tipo;
String? get currentPerfilId => _perfilId;
String? get currentFilialId => _filialId;
bool get isAuthenticated => _jwtToken != null;

/// Sets the API Key for routes that require it.
void setApiKey(String apiKey) {
  _apiKey = apiKey;
}

/// Clears current identity (e.g., on logout or session expiration).
void clearIdentity() {
  _jwtToken = null;
  _usuarioId = null;
  _tipo = null;
  _perfilId = null;
  _filialId = null;
}

void Function()? onSessionExpired;

// ── Main Dio client with Interceptor ──────────────────────────────────────────
final Dio dioClient = () {
  final dio = Dio(
    BaseOptions(
      // baseUrl será definida dinamicamente no interceptor para evitar race condition com dotenv.load()
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Configura Base URL dinamicamente
        options.baseUrl = _actualBaseUrl;

        // JWT-based auth: send Bearer token
        if (_jwtToken != null) {
          options.headers['Authorization'] = 'Bearer $_jwtToken';
        }

        // API Key: pega do store ou do dotenv (carregado via main.dart)
        final apiKey = _apiKey ?? dotenv.env['API_KEY'];
        if (apiKey != null) {
          options.headers['x-api-key'] = apiKey;
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
