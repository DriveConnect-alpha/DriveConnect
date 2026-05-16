import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../calls/gerente.call.dart';
import '../../manager/widgets/manager_scaffold.dart';
import '../models/whatsapp_conversation.dart';
import '../models/whatsapp_message.dart';
import '../widgets/chat_bubble.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final openCount = _conversations.where((conversation) => conversation.status.toUpperCase() == 'OPEN').length;
    final pausedCount = _conversations.where((conversation) => conversation.paused).length;
    final incomingCount = _conversations.where((conversation) => (conversation.lastMessageDirection ?? '').toUpperCase() == 'IN').length;

    return ManagerScaffold(
      title: 'Atendimentos',
      child: Container(
        color: colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.28)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.8,
                  children: [
                    _SummaryChip(label: 'Total', value: _conversations.length.toString(), icon: Symbols.chat),
                    _SummaryChip(label: 'Pausados', value: pausedCount.toString(), icon: Symbols.pause_circle),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneFilterController,
                                  decoration: InputDecoration(
                                    labelText: 'Filtrar por telefone',
                                    hintText: 'Ex.: 5511999999999',
                                    prefixIcon: const Icon(Symbols.search),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onSubmitted: (_) => _loadConversations(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _loadConversations,
                                icon: const Icon(Symbols.search),
                                label: const Text('Buscar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _FilterDropdown<String>(
                                value: _statusFilter,
                                label: 'Status',
                                items: const [
                                  DropdownMenuItem(value: 'ALL', child: Text('Todos')),
                                  DropdownMenuItem(value: 'OPEN', child: Text('Abertos')),
                                  DropdownMenuItem(value: 'CLOSED', child: Text('Fechados')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _statusFilter = value);
                                },
                              ),
                              _FilterDropdown<String>(
                                value: _directionFilter,
                                label: 'Última mensagem',
                                items: const [
                                  DropdownMenuItem(value: 'ALL', child: Text('Todas')),
                                  DropdownMenuItem(value: 'IN', child: Text('Cliente')),
                                  DropdownMenuItem(value: 'OUT', child: Text('Bot')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _directionFilter = value);
                                },
                              ),
                              _FilterDropdown<String>(
                                value: _periodFilter,
                                label: 'Período',
                                items: const [
                                  DropdownMenuItem(value: 'ALL', child: Text('Todos')),
                                  DropdownMenuItem(value: 'TODAY', child: Text('Hoje')),
                                  DropdownMenuItem(value: '7D', child: Text('7 dias')),
                                  DropdownMenuItem(value: '30D', child: Text('30 dias')),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _periodFilter = value);
                                },
                              ),
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
                        ],
                      ),
                    ],
                  ),
                ),
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
                      Icon(Symbols.warning, size: 42, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(
                        'Erro ao carregar atendimentos',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error ?? 'Falha inesperada',
                        textAlign: TextAlign.center,
                      ),
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final conversation = filtered[index];
                      final isIncoming = conversation.lastMessageDirection == 'IN';
                      final messagePreview = conversation.lastMessageText?.trim().isNotEmpty == true
                          ? conversation.lastMessageText!.trim()
                          : 'Sem mensagem de texto';

                      return Card(
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openConversation(conversation),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isIncoming
                                          ? colorScheme.secondaryContainer
                                          : colorScheme.primaryContainer,
                                      child: Icon(
                                        isIncoming ? Symbols.call_received : Symbols.smart_toy,
                                        size: 20,
                                        color: isIncoming
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: conversation.paused ? colorScheme.tertiary : colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: colorScheme.surface, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              conversation.phone,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          _StatusPill(
                                            label: conversation.paused ? 'Pausado' : conversation.status,
                                            color: conversation.paused ? colorScheme.tertiary : colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        messagePreview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Symbols.schedule, size: 16, color: colorScheme.outline),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Última atividade: ${_formatDate(conversation.lastMessageAt)}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Symbols.chevron_right, color: colorScheme.outline),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onPrimary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.84),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({required this.value, required this.label, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<T>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items,
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
          // Scroll para o final após enviar mensagem
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToLatest();
            }
          });
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (context, scrollController) => Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.26)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white.withOpacity(0.16),
                                child: const Icon(Symbols.chat, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conversation.phone,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${conversation.status}${conversation.paused ? ' • PAUSADO' : ''}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Symbols.close, color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _StatusPill(label: conversation.paused ? 'Pausado' : 'Ativo', color: Colors.white),
                              _StatusPill(label: 'Mensagens ${_messages.length}', color: Colors.white),
                              _StatusPill(label: conversation.lastMessageDirection == 'IN' ? 'Última do cliente' : 'Última do bot', color: Colors.white),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isActionLoading ? null : _togglePauseResume,
                              icon: Icon(conversation.paused ? Symbols.play_arrow : Symbols.pause),
                              label: Text(conversation.paused ? 'Retomar' : 'Pausar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.warning, size: 42, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Erro ao carregar mensagens', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('$_error', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadMessages,
                          icon: const Icon(Symbols.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                  ),
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Symbols.chat_bubble, size: 42, color: colorScheme.outline),
                              const SizedBox(height: 12),
                              Text('Sem mensagens nesta conversa.', style: theme.textTheme.titleMedium),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                          itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_hasMoreMessages && index == _messages.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : OutlinedButton.icon(
                                          onPressed: _loadMoreMessages,
                                          icon: const Icon(Symbols.expand_less),
                                          label: const Text('Carregar mensagens antigas'),
                                        ),
                                ),
                              );
                            }

                            final message = _messages[_messages.length - 1 - index];
                            final messagePosition = _messages.length - 1 - index;
                            final previousMessage = messagePosition > 0 ? _messages[messagePosition - 1] : null;
                            final shouldShowSeparator = previousMessage == null ||
                                previousMessage.createdAt.year != message.createdAt.year ||
                                previousMessage.createdAt.month != message.createdAt.month ||
                                previousMessage.createdAt.day != message.createdAt.day;

                            return Column(
                              children: [
                                if (shouldShowSeparator) DateSeparator(date: message.createdAt),
                                ChatBubble(
                                  text: message.text,
                                  timestamp: message.createdAt,
                                  isOutgoing: message.direction != 'IN',
                                  status: message.status,
                                  senderLabel: message.direction == 'IN' ? 'Cliente' : 'Atendimento',
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
            ChatInputField(
              controller: _messageInputController,
              onSendPressed: _sendMessageFromInput,
              isLoading: _isActionLoading,
            ),
          ],
        ),
      ),
    );
  }
}
