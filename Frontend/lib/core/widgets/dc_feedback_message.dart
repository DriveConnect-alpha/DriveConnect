import 'package:flutter/material.dart';
import '../feedback/app_feedback.dart';

class DCFeedbackMessage extends StatelessWidget {
  final String message;
  final AppFeedbackType type;
  final EdgeInsets padding;
  final bool dense;

  const DCFeedbackMessage({
    super.key,
    required this.message,
    this.type = AppFeedbackType.error,
    this.padding = const EdgeInsets.all(12),
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _FeedbackStyle.fromTheme(theme, type);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: dense ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(colors.icon, color: colors.foreground, size: dense ? 18 : 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackStyle {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const _FeedbackStyle({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  factory _FeedbackStyle.fromTheme(ThemeData theme, AppFeedbackType type) {
    switch (type) {
      case AppFeedbackType.success:
        return _FeedbackStyle(
          background: const Color(0xFFE8F5E9),
          border: const Color(0xFFC8E6C9),
          foreground: const Color(0xFF2E7D32),
          icon: Icons.check_circle,
        );
      case AppFeedbackType.warning:
        return _FeedbackStyle(
          background: const Color(0xFFFFF8E1),
          border: const Color(0xFFFFECB3),
          foreground: const Color(0xFFF9A825),
          icon: Icons.warning_amber_rounded,
        );
      case AppFeedbackType.info:
        return _FeedbackStyle(
          background: theme.colorScheme.primaryContainer,
          border: theme.colorScheme.primary.withAlpha(60),
          foreground: theme.colorScheme.onPrimaryContainer,
          icon: Icons.info_outline,
        );
      case AppFeedbackType.error:
        return _FeedbackStyle(
          background: theme.colorScheme.errorContainer,
          border: theme.colorScheme.error.withAlpha(70),
          foreground: theme.colorScheme.onErrorContainer,
          icon: Icons.error_outline,
        );
    }
  }
}
