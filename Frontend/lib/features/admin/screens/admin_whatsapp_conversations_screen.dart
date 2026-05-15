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
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  int _currentOffset = 0;
  static const int _pageSize = 50; // Carregar 50 mensagens por página
  final ScrollController _messagesScrollController = ScrollController();
  final TextEditingController _messageInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _messagesScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messagesScrollController.removeListener(_onScroll);
    _messagesScrollController.dispose();
    _messageInputController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_messagesScrollController.hasClients) return;

    final target = _messagesScrollController.position.maxScrollExtent;
    if (target <= 0) return;

    _messagesScrollController.jumpTo(target);
  }

  void _onScroll() {
    // Se scrollou para bem perto do topo e tem mais mensagens
    if (_messagesScrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMoreMessages &&
        !_isLoading) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() => _isLoadingMore = true);

    final completer = Completer<List<Map<String, dynamic>>>();

    await GerenteCall.listarMensagensWhatsapp(
      conversationId: widget.conversation.id,
      limit: _pageSize,
      offset: _currentOffset + _pageSize,
      onSuccess: completer.complete,
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    try {
      final raw = await completer.future;
      if (!mounted) return;

      if (raw.isEmpty) {
        // Nenhuma mensagem nova = chegou ao fim
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      final newMessages = raw.map(WhatsAppMessage.fromJson).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        // Adicionar no início (mensagens mais antigas)
        _messages = [...newMessages, ..._messages];
        _currentOffset += _pageSize;
        _isLoadingMore = false;

        // Se carregou menos que o esperado = fim das mensagens
        if (raw.length < _pageSize) {
          _hasMoreMessages = false;
        }
      });

      // Manter scroll position após carregar mais
      if (_messagesScrollController.hasClients) {
        final newHeight = _messagesScrollController.position.maxScrollExtent -
            _messagesScrollController.position.viewportDimension;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messagesScrollController.hasClients && mounted) {
            _messagesScrollController.jumpTo(newHeight * 0.5);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar mensagens antigas: $e')),
      );
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentOffset = 0;
      _hasMoreMessages = true;
    });

    final completer = Completer<List<Map<String, dynamic>>>();

    await GerenteCall.listarMensagensWhatsapp(
      conversationId: widget.conversation.id,
      limit: _pageSize,
      offset: 0,
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
        _currentOffset = _pageSize;
        // Se carregou menos que o esperado = não há mais mensagens
        _hasMoreMessages = raw.length >= _pageSize;
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

  Future<void> _sendMessageFromInput() async {
    final text = _messageInputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _isActionLoading = true);

    await GerenteCall.sendManagerMessage(
      conversationId: widget.conversation.id,
      text: text,
      phone: widget.conversation.phone,
      onSuccess: (data) {
        if (mounted) {
          _messageInputController.clear();
          setState(() => _isActionLoading = false);
          _loadMessages();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mensagem enviada com sucesso.')),
          );
        }
      },
      onError: (msg) {
        if (mounted) {
          setState(() => _isActionLoading = false);
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
    return '${two(local.hour)}:${two(local.minute)}';
  }

  String _formatDateSeparator(DateTime date) {
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
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Indicador de carregar mais no topo
                    if (index == 0 && _hasMoreMessages) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _isLoadingMore
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : InkWell(
                                  onTap: _loadMoreMessages,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Carregar mensagens mais antigas',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      );
                    }

                    // Índice ajustado se tem botão de carregar mais
                    final messageIndex =
                        _hasMoreMessages ? index - 1 : index;
                    if (messageIndex < 0) return const SizedBox();

                    final message = _messages[messageIndex];
                    final isIncoming = message.direction == 'IN';
                    
                    // Verificar se deve mostrar separador de data
                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final prevDate = DateTime(
                        _messages[index - 1].createdAt.year,
                        _messages[index - 1].createdAt.month,
                        _messages[index - 1].createdAt.day,
                      );
                      final currentDate = DateTime(
                        message.createdAt.year,
                        message.createdAt.month,
                        message.createdAt.day,
                      );
                      showDateSeparator = !prevDate.isAtSameMomentAs(currentDate);
                    }

                    return Column(
                      children: [
                        if (showDateSeparator)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              _formatDateSeparator(message.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        Align(
                          alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: isIncoming ? MainAxisAlignment.start : MainAxisAlignment.end,
                              children: [
                                if (isIncoming)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: CircleAvatar(
                                      radius: 16,
                                      child: Text(
                                        message.direction == 'IN' ? 'C' : 'B',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                Flexible(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isIncoming
                                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                                          : Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(isIncoming ? 4 : 18),
                                        bottomRight: Radius.circular(isIncoming ? 18 : 4),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.text.isNotEmpty
                                              ? message.text
                                              : '(mensagem sem texto)',
                                          style: TextStyle(
                                            color: isIncoming
                                                ? Theme.of(context).colorScheme.onSurface
                                                : Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatTime(message.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isIncoming
                                                    ? Theme.of(context).colorScheme.outline
                                                    : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                                              ),
                                            ),
                                            if (!isIncoming) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                _getStatusIcon(message.status),
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
                                if (!isIncoming)
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
                        ),
                      ],
                    );
                  },
                ),
              ),
            // Input field - WhatsApp style
            Container(
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
                                controller: _messageInputController,
                                decoration: const InputDecoration(
                                  hintText: 'Mensagem...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                maxLines: null,
                                minLines: 1,
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
                      child: IconButton(
                        icon: Icon(
                          Symbols.send,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20,
                        ),
                        onPressed: _isActionLoading ? null : _sendMessageFromInput,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
