import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Widget para exibir uma mensagem de chat no estilo WhatsApp
class ChatBubble extends StatelessWidget {
  final String text;
  final DateTime timestamp;
  final bool isOutgoing;
  final String status;
  final String senderLabel;

  const ChatBubble({
    super.key,
    required this.text,
    required this.timestamp,
    required this.isOutgoing,
    this.status = 'sent',
    this.senderLabel = 'Bot',
  });

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
        return Symbols.done;
      case 'delivered':
        return Symbols.done_all;
      case 'read':
        return Symbols.done_all;
      default:
        return Symbols.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outgoingGradient = isOutgoing
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.22)!,
            ],
          )
        : null;

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOutgoing)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: colorScheme.tertiaryContainer,
                  child: Text(
                    senderLabel.isNotEmpty ? senderLabel[0].toUpperCase() : 'C',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  gradient: outgoingGradient,
                  color: isOutgoing ? null : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isOutgoing ? 20 : 6),
                    bottomRight: Radius.circular(isOutgoing ? 6 : 20),
                  ),
                  border: isOutgoing ? null : Border.all(color: colorScheme.outlineVariant.withOpacity(0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (senderLabel.isNotEmpty) ...[
                      Text(
                        senderLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: isOutgoing ? colorScheme.onPrimary.withOpacity(0.82) : colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      text.isNotEmpty ? text : '(mensagem sem texto)',
                      style: TextStyle(
                        color: isOutgoing ? colorScheme.onPrimary : colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isOutgoing ? colorScheme.onPrimary.withOpacity(0.78) : colorScheme.outline,
                          ),
                        ),
                        if (isOutgoing) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _getStatusIcon(status),
                            size: 14,
                            color: colorScheme.onPrimary.withOpacity(0.78),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isOutgoing)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Symbols.smart_toy,
                    size: 19,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget para separador de data no chat
class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(local.year, local.month, local.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Hoje';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Ontem';
    } else {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(local.day)}/${two(local.month)}/${local.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: colorScheme.outline.withOpacity(0.24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: colorScheme.outline.withOpacity(0.24),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para campo de entrada de mensagem no estilo WhatsApp
class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;
  final bool isLoading;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSendPressed,
    this.isLoading = false,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          final colorScheme = Theme.of(context).colorScheme;

                          hintText: 'Mensagem...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                                  color: colorScheme.outline.withOpacity(0.16),
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                              color: colorScheme.surface,
                        onSubmitted: (_) {
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            widget.onSendPressed();
                          }
                        },
                      ),
                    ),
                  ],
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: widget.isLoading
                  ? SizedBox(
                                              decoration: InputDecoration(
                                                hintText: 'Escreva uma resposta...',
                      child: CircularProgressIndicator(
                                                hintStyle: TextStyle(color: colorScheme.outline),
                                                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Symbols.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                                  const SizedBox(width: 10),
                                  FilledButton(
                                    onPressed: widget.isLoading ? null : widget.onSendPressed,
                                    style: FilledButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(14),
                                    ),
                                    child: widget.isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Symbols.send, size: 18),
