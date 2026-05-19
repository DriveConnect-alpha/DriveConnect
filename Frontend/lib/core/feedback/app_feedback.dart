import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../network/api_exceptions.dart';

enum AppFeedbackType { success, error, warning, info }

class AppFeedback {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void showSuccess(String message, {Duration? duration}) {
    _show(message, AppFeedbackType.success, duration: duration);
  }

  static void showInfo(String message, {Duration? duration}) {
    _show(message, AppFeedbackType.info, duration: duration);
  }

  static void showWarning(String message, {Duration? duration}) {
    _show(message, AppFeedbackType.warning, duration: duration);
  }

  static void showError(Object? error, {String? fallback, Duration? duration}) {
    final message = AppErrorMapper.map(error, fallback: fallback);
    _show(message, AppFeedbackType.error, duration: duration);
  }

  static void handleFlutterError(FlutterErrorDetails details) {
    FlutterError.presentError(details);
    showError(details.exception, fallback: 'Ocorreu um erro inesperado.');
  }

  static void handleZoneError(Object error, StackTrace stackTrace) {
    showError(error, fallback: 'Ocorreu um erro inesperado.');
  }

  static void _show(String message, AppFeedbackType type, {Duration? duration}) {
    final messenger = messengerKey.currentState;
    final context = messengerKey.currentContext;
    if (messenger == null || context == null) return;

    final theme = Theme.of(context);
    final colors = _FeedbackColors.fromTheme(theme, type);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
        backgroundColor: colors.background,
        content: Row(
          children: [
            Icon(colors.icon, color: colors.foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: colors.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppErrorMapper {
  static String map(Object? error, {String? fallback}) {
    final fallbackMessage = fallback ?? 'Ocorreu um erro inesperado.';

    if (error == null) return fallbackMessage;
    if (error is String) return error.isNotEmpty ? error : fallbackMessage;
    if (error is ApiException) return error.message;
    if (error is DioException) {
      return ApiErrorHandler.handle(error).message;
    }

    final message = error.toString().replaceAll('Exception: ', '').trim();
    return message.isNotEmpty ? message : fallbackMessage;
  }
}

class _FeedbackColors {
  final Color background;
  final Color foreground;
  final IconData icon;

  _FeedbackColors({required this.background, required this.foreground, required this.icon});

  factory _FeedbackColors.fromTheme(ThemeData theme, AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return _FeedbackColors(
          background: const Color(0xFF2E7D32),
          foreground: Colors.white,
          icon: Icons.check_circle,
        );
      case AppFeedbackType.warning:
        return _FeedbackColors(
          background: const Color(0xFFF9A825),
          foreground: Colors.black87,
          icon: Icons.warning_amber_rounded,
        );
      case AppFeedbackType.info:
        return _FeedbackColors(
          background: theme.colorScheme.primary,
          foreground: theme.colorScheme.onPrimary,
          icon: Icons.info_outline,
        );
      case AppFeedbackType.error:
        return _FeedbackColors(
          background: theme.colorScheme.error,
          foreground: theme.colorScheme.onError,
          icon: Icons.error_outline,
        );
    }
  }
}
