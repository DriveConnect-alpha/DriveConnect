import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../providers/reservations_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/widgets/dc_status_badge.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationsProvider>().fetchReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ManagerScaffold(
      title: 'Gestão de Reservas',
      child: Consumer<ReservationsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.reservas.length,
            itemBuilder: (context, index) {
              final reserva = provider.reservas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reserva #${reserva.id.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DCStatusBadge(status: reserva.status, label: reserva.status),
                        ],
                      ),
                      const Divider(),
                      Text('Cliente: ${reserva.cliente?.nomeCompleto ?? "N/A"}'),
                      Text('Veículo: ${reserva.veiculo?.modelo?.marca} ${reserva.veiculo?.modelo?.nome} (${reserva.veiculo?.placa})'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Symbols.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text('${dateFormat.format(reserva.dataInicio)} - ${dateFormat.format(reserva.dataFim)}'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (reserva.status == 'PENDENTE')
                            TextButton(
                              onPressed: () => _updateStatus(context, reserva.id, 'CONFIRMADA'),
                              child: const Text('Confirmar'),
                            ),
                          if (reserva.status == 'CONFIRMADA')
                            TextButton(
                              onPressed: () => _updateStatus(context, reserva.id, 'ATIVA'),
                              child: const Text('Iniciar Aluguel'),
                            ),
                          if (reserva.status == 'ATIVA')
                            ElevatedButton(
                              onPressed: () => _updateStatus(context, reserva.id, 'FINALIZADA'),
                              child: const Text('Finalizar'),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
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
