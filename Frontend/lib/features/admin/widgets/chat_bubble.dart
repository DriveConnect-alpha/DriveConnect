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
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        constraints: const BoxConstraints(maxWidth: 350),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOutgoing)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                ),
              ),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: isOutgoing
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
                    bottomRight: Radius.circular(isOutgoing ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isNotEmpty ? text : '(mensagem sem texto)',
                      style: TextStyle(
                        color: isOutgoing
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
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
                            color: isOutgoing
                                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        if (isOutgoing) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _getStatusIcon(status),
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
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
                padding: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Symbols.smart_toy,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                          hintText: 'Mensagem...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (!widget.isLoading) {
                            widget.onSendPressed();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: widget.isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Symbols.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                      onPressed: widget.onSendPressed,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
