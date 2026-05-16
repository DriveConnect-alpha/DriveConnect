import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/reservations_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/widgets/dc_status_badge.dart';
import '../../../../core/widgets/dc_card.dart';
import '../widgets/edit_reservation_modal.dart';

class ReservationsScreen extends StatefulWidget {
  final String? clienteId;
  final String? clienteNome;

  const ReservationsScreen({
    super.key,
    this.clienteId,
    this.clienteNome,
  });

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsProvider>().fetchReservations(clienteId: widget.clienteId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filteredReservas(List<dynamic> reservas) {
    if (_searchQuery.isEmpty) return reservas;
    final query = _searchQuery.toLowerCase();
    return reservas.where((reserva) {
      final name = reserva.cliente?.nomeCompleto?.toLowerCase() ?? '';
      final id = reserva.id.toLowerCase();
      final placa = reserva.veiculo?.placa?.toLowerCase() ?? '';
      return name.contains(query) || id.contains(query) || placa.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ManagerScaffold(
      title: widget.clienteNome != null 
          ? 'Reservas de ${widget.clienteNome}' 
          : 'Gestão de Reservas',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/manager/reservations/create'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Symbols.add, size: 28),
      ),
      child: Consumer<ReservationsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          // Calcula estatísticas
          final total = provider.reservas.length;
          final pendentes = provider.reservas.where((r) => r.status == 'PENDENTE_PAGAMENTO').length;
          final ativas = provider.reservas.where((r) => r.status == 'ATIVA').length;
          final finalizadas = provider.reservas.where((r) => r.status == 'FINALIZADA').length;

          final filtered = _filteredReservas(provider.reservas);

          return Column(
            children: [
              // Cabeçalho fixo com estatísticas e busca
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
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
                        childAspectRatio: 2.8,
                        children: [
                          _StatChip(label: 'Total', value: total.toString(), icon: Symbols.list),
                          _StatChip(label: 'Ativas', value: ativas.toString(), icon: Symbols.check_circle),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Buscar reservas',
                                  hintText: 'Nome, ID ou Placa',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  prefixIcon: const Icon(Symbols.search, size: 20),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => setState(() => _searchQuery = _searchController.text),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Filtrar'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Symbols.filter_alt_off, size: 18),
                              tooltip: 'Limpar filtros',
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.surfaceVariant,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Lista com scroll
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Symbols.inbox, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty ? 'Nenhuma reserva encontrada' : 'Nenhum resultado para a busca',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchReservations(clienteId: widget.clienteId),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            try {
                              final reserva = filtered[index];
                              final reservaIdShort = reserva.id.length >= 8 ? reserva.id.substring(0, 8) : reserva.id;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DCCard(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(0.12),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Reserva #$reservaIdShort',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              DCStatusBadge(status: reserva.status, label: reserva.status),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          _ReservaInfo(
                                            icon: Symbols.person,
                                            label: 'Cliente',
                                            value: reserva.cliente?.nomeCompleto ?? 'N/A',
                                            textTheme: theme.textTheme,
                                            colorScheme: colorScheme,
                                          ),
                                          const SizedBox(height: 8),
                                          _ReservaInfo(
                                            icon: Symbols.directions_car,
                                            label: 'Veículo',
                                            value: '${reserva.veiculo?.modelo?.marca ?? ""} ${reserva.veiculo?.modelo?.nome ?? ""} (${reserva.veiculo?.placa ?? "N/A"})',
                                            textTheme: theme.textTheme,
                                            colorScheme: colorScheme,
                                          ),
                                          const SizedBox(height: 8),
                                          _ReservaInfo(
                                            icon: Symbols.calendar_today,
                                            label: 'Período',
                                            value: '${reserva.dataInicio != null ? dateFormat.format(reserva.dataInicio!) : "N/A"} - ${reserva.dataFim != null ? dateFormat.format(reserva.dataFim!) : "N/A"}',
                                            textTheme: theme.textTheme,
                                            colorScheme: colorScheme,
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              if (reserva.status == 'PENDENTE_PAGAMENTO' || reserva.status == 'RESERVADA')
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: _ActionButton(
                                                    label: 'Cancelar',
                                                    onPressed: () => _confirmCancel(context, reserva.id),
                                                    isDanger: true,
                                                  ),
                                                ),
                                              if (reserva.status == 'PENDENTE_PAGAMENTO') ...[
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: _ActionButton(
                                                    label: 'Editar',
                                                    onPressed: () => _showEditModal(context, reserva),
                                                  ),
                                                ),
                                                _ActionButton(
                                                  label: 'Confirmar',
                                                  onPressed: () => _updateStatus(context, reserva.id, 'RESERVADA'),
                                                  isPrimary: true,
                                                ),
                                              ] else if (reserva.status == 'RESERVADA')
                                                _ActionButton(
                                                  label: 'Iniciar',
                                                  onPressed: () => _updateStatus(context, reserva.id, 'ATIVA'),
                                                  isPrimary: true,
                                                )
                                              else if (reserva.status == 'ATIVA')
                                                _ActionButton(
                                                  label: 'Finalizar',
                                                  onPressed: () => _updateStatus(context, reserva.id, 'FINALIZADA'),
                                                  isPrimary: true,
                                                ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            } catch (e) {
                              return Card(
                                child: ListTile(
                                  title: const Text('Erro ao exibir reserva'),
                                  subtitle: Text(e.toString()),
                                ),
                              );
                            }
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String id, String status) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final success = await context.read<ReservationsProvider>().updateStatus(id, status);
    
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text(success ? 'Status atualizado' : 'Erro ao atualizar')),
    );
  }

  void _confirmCancel(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva?'),
        content: const Text('Esta ação não pode ser desfeita. Você deseja realmente cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = this.context.read<ReservationsProvider>();
              final success = await provider.cancelReservation(id);
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Reserva cancelada com sucesso' : (provider.error ?? 'Erro ao cancelar reserva')),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirmar Cancelamento'),
          ),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context, dynamic reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: EditReservationModal(reserva: reserva),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  fontSize: 16,
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

class _ReservaInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _ReservaInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDanger;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? colorScheme.primary : (isDanger ? Colors.red.shade50 : null),
        foregroundColor: isPrimary ? Colors.white : (isDanger ? Colors.red : null),
        side: isDanger ? BorderSide(color: Colors.red.shade200) : null,
        minimumSize: const Size(100, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        elevation: isDanger ? 0 : null,
      ),
      child: Text(label),
    );
  }
}
