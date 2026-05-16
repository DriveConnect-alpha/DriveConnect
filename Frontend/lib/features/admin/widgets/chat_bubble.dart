import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }

  IconData _getStatusIcon(String value) {
    switch (value.toLowerCase()) {
      case 'sent':
        return Symbols.done;
      case 'delivered':
      case 'read':
        return Symbols.done_all;
      default:
        return Symbols.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOutgoing) ...[
              CircleAvatar(
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
              const SizedBox(width: 10),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                  border: isOutgoing ? null : Border.all(color: colorScheme.outlineVariant.withOpacity(0.75)),
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
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 6),
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
            if (isOutgoing) ...[
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 17,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Symbols.smart_toy,
                  size: 19,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DateSeparator extends StatelessWidget {
  final DateTime date;

  const DateSeparator({super.key, required this.date});

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(local.year, local.month, local.day);

    if (messageDate == today) {
      return 'Hoje';
    }
    if (messageDate == yesterday) {
      return 'Ontem';
    }

    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}';
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
  late final FocusNode _focusNode;

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.12)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Escreva uma resposta...',
                  hintStyle: TextStyle(color: colorScheme.outline.withOpacity(0.7)),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withOpacity(0.15),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!widget.isLoading) {
                    widget.onSendPressed();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onSendPressed,
                  borderRadius: BorderRadius.circular(20),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Icon(Symbols.send, size: 18, color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
