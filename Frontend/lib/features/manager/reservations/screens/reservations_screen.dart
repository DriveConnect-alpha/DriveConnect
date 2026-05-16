import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../providers/reservations_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/widgets/dc_status_badge.dart';
import '../../../../core/widgets/dc_card.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsProvider>().fetchReservations(clienteId: widget.clienteId);
    });
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com estatísticas
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
                const SizedBox(height: 20),
                // Lista de reservas
                if (provider.reservas.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Symbols.inbox, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma reserva encontrada',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.reservas.length,
                    itemBuilder: (context, index) {
                      try {
                        final reserva = provider.reservas[index];
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
                                    if (reserva.status == 'PENDENTE_PAGAMENTO')
                                      _ActionButton(
                                        label: 'Confirmar',
                                        onPressed: () => _updateStatus(context, reserva.id, 'RESERVADA'),
                                        isPrimary: true,
                                      )
                                    else if (reserva.status == 'RESERVADA')
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
              ],
            ),
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

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? colorScheme.primary : null,
        foregroundColor: isPrimary ? Colors.white : null,
        minimumSize: const Size(100, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(label),
    );
  }
}
