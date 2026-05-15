import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../calls/gerente.call.dart';
import '../../manager/widgets/manager_scaffold.dart';
import '../models/whatsapp_conversation.dart';
import '../models/whatsapp_message.dart';

class AdminWhatsAppConversationsScreen extends StatefulWidget {
  const AdminWhatsAppConversationsScreen({super.key});

  @override
  State<AdminWhatsAppConversationsScreen> createState() => _AdminWhatsAppConversationsScreenState();
}

class _AdminWhatsAppConversationsScreenState extends State<AdminWhatsAppConversationsScreen> {
  final TextEditingController _phoneFilterController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<WhatsAppConversation> _conversations = const [];
  String _statusFilter = 'ALL';
  String _directionFilter = 'ALL';
  String _periodFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _phoneFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final completer = Completer<List<Map<String, dynamic>>>();

    await GerenteCall.listarConversasWhatsapp(
      limit: 50,
      phone: _phoneFilterController.text,
      onSuccess: completer.complete,
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    try {
      final raw = await completer.future;
      if (!mounted) return;
      setState(() {
        _conversations = raw.map(WhatsAppConversation.fromJson).toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openConversation(WhatsAppConversation conversation) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ConversationMessagesSheet(conversation: conversation),
    );

    if (mounted) {
      await _loadConversations();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  List<WhatsAppConversation> _filteredConversations() {
    final now = DateTime.now();

    return _conversations.where((conversation) {
      // Filtro por status
      if (_statusFilter != 'ALL' && conversation.status.toUpperCase() != _statusFilter) {
        return false;
      }

      // Filtro por direção da última mensagem
      final direction = (conversation.lastMessageDirection ?? '').toUpperCase();
      if (_directionFilter != 'ALL' && direction != _directionFilter) {
        return false;
      }

      // Filtro por período de atividade
      final referenceDate = conversation.lastMessageAt ?? conversation.createdAt;
      if (_periodFilter == 'TODAY') {
        if (referenceDate.year != now.year || referenceDate.month != now.month || referenceDate.day != now.day) {
          return false;
        }
      } else if (_periodFilter == '7D') {
        if (referenceDate.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_periodFilter == '30D') {
        if (referenceDate.isBefore(now.subtract(const Duration(days: 30)))) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredConversations();

    return ManagerScaffold(
      title: 'Atendimentos',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneFilterController,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por telefone',
                          hintText: 'Ex.: 5511999999999',
                          prefixIcon: Icon(Symbols.search),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _loadConversations(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _loadConversations,
                      icon: const Icon(Symbols.search),
                      label: const Text('Buscar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _statusFilter,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _statusFilter = value);
                        },
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Status: Todos')),
                          DropdownMenuItem(value: 'OPEN', child: Text('Status: Abertos')),
                          DropdownMenuItem(value: 'CLOSED', child: Text('Status: Fechados')),
                        ],
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _directionFilter,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _directionFilter = value);
                        },
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Última msg: Todas')),
                          DropdownMenuItem(value: 'IN', child: Text('Última msg: Cliente')),
                          DropdownMenuItem(value: 'OUT', child: Text('Última msg: Bot')),
                        ],
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _periodFilter,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _periodFilter = value);
                        },
                        items: const [
                          DropdownMenuItem(value: 'ALL', child: Text('Período: Todos')),
                          DropdownMenuItem(value: 'TODAY', child: Text('Período: Hoje')),
                          DropdownMenuItem(value: '7D', child: Text('Período: 7 dias')),
                          DropdownMenuItem(value: '30D', child: Text('Período: 30 dias')),
                        ],
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _statusFilter = 'ALL';
                            _directionFilter = 'ALL';
                            _periodFilter = 'ALL';
                            _phoneFilterController.clear();
                          });
                          _loadConversations();
                        },
                        icon: const Icon(Symbols.filter_alt_off),
                        label: const Text('Limpar filtros'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erro ao carregar atendimentos: $_error', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadConversations,
                      icon: const Icon(Symbols.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          else if (filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('Nenhum atendimento encontrado com os filtros atuais.'),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadConversations,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final isIncoming = conversation.lastMessageDirection == 'IN';
                    return Card(
                      child: ListTile(
                        onTap: () => _openConversation(conversation),
                        leading: CircleAvatar(
                          child: Icon(isIncoming ? Symbols.call_received : Symbols.smart_toy),
                        ),
                        title: Text(conversation.phone),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              conversation.lastMessageText?.trim().isNotEmpty == true
                                  ? conversation.lastMessageText!
                                  : 'Sem mensagem de texto',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text('Última atividade: ${_formatDate(conversation.lastMessageAt)}'),
                          ],
                        ),
                        trailing: const Icon(Symbols.chevron_right),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationMessagesSheet extends StatefulWidget {
  final WhatsAppConversation conversation;

  const _ConversationMessagesSheet({required this.conversation});

  @override
  State<_ConversationMessagesSheet> createState() => _ConversationMessagesSheetState();
}

class _ConversationMessagesSheetState extends State<_ConversationMessagesSheet> {
  bool _isLoading = true;
  String? _error;
  List<WhatsAppMessage> _messages = const [];
  bool _isActionLoading = false;
  final ScrollController _messagesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messagesScrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_messagesScrollController.hasClients) return;

    final target = _messagesScrollController.position.maxScrollExtent;
    if (target <= 0) return;

    _messagesScrollController.jumpTo(target);
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final completer = Completer<List<Map<String, dynamic>>>();

    await GerenteCall.listarMensagensWhatsapp(
      conversationId: widget.conversation.id,
      limit: 200,
      onSuccess: completer.complete,
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    try {
      final raw = await completer.future;
      if (!mounted) return;
      final sorted = raw.map(WhatsAppMessage.fromJson).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      setState(() {
        _messages = sorted;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToLatest();
            }
          });
        }
      }
    }
  }

  Future<void> _togglePauseResume() async {
    setState(() => _isActionLoading = true);

    final isCurrent = widget.conversation.paused;

    if (isCurrent) {
      await GerenteCall.resumeAttendance(
        conversationId: widget.conversation.id,
        onSuccess: (data) {
          if (mounted) {
            setState(() => _isActionLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Atendimento retomado.')),
            );
            Navigator.of(context).pop();
          }
        },
        onError: (msg) {
          if (mounted) {
            setState(() => _isActionLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao retomar: $msg')),
            );
          }
        },
      );
    } else {
      await GerenteCall.pauseAttendance(
        conversationId: widget.conversation.id,
        onSuccess: (data) {
          if (mounted) {
            setState(() => _isActionLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Atendimento pausado. O bot não responderá.')),
            );
            Navigator.of(context).pop();
          }
        },
        onError: (msg) {
          if (mounted) {
            setState(() => _isActionLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao pausar: $msg')),
            );
          }
        },
      );
    }
  }

  void _showSendMessageDialog() {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enviar Mensagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Digite a mensagem...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !isSubmitting,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSubmitting ? null : () => _sendMessage(textController, ctx),
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(TextEditingController controller, BuildContext dialogContext) async {
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma mensagem.')),
      );
      return;
    }

    // Update dialog state
    if (mounted) {
      (dialogContext as Element).markNeedsBuild();
    }

    await GerenteCall.sendManagerMessage(
      conversationId: widget.conversation.id,
      text: text,
      phone: widget.conversation.phone,
      onSuccess: (data) {
        if (mounted) {
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensagem enviada com sucesso.')),
          );
          _loadMessages(); // Reload messages to show the new one
        }
      },
      onError: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar: $msg')),
          );
        }
      },
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)} ${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final conversation = widget.conversation;
    
    return SafeArea(
      child: SizedBox(
        height: media.size.height * 0.86,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Symbols.chat),
              title: Text('Atendimento: ${conversation.phone}'),
              subtitle: Text('Status: ${conversation.status}${conversation.paused ? ' (PAUSADO)' : ''}'),
              trailing: IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Divider(height: 1),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _isActionLoading ? null : _togglePauseResume,
                    icon: Icon(conversation.paused ? Symbols.play_arrow : Symbols.pause),
                    label: Text(conversation.paused ? 'Retomar' : 'Pausar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isActionLoading ? null : _showSendMessageDialog,
                    icon: const Icon(Symbols.send),
                    label: const Text('Enviar Mensagem'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro ao carregar mensagens: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadMessages,
                        icon: const Icon(Symbols.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_messages.isEmpty)
              const Expanded(child: Center(child: Text('Sem mensagens nesta conversa.')))
            else
              Expanded(
                child: ListView.builder(
                  controller: _messagesScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isIncoming = message.direction == 'IN';
                    final align = isIncoming ? Alignment.centerLeft : Alignment.centerRight;
                    final color = isIncoming
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primaryContainer;

                    return Align(
                      alignment: align,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Card(
                          color: color,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.text.isNotEmpty ? message.text : '(mensagem sem texto)',
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${isIncoming ? 'Cliente' : 'Bot'} • ${_formatTime(message.createdAt)} • ${message.status}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
