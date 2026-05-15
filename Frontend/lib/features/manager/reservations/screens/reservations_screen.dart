import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../providers/reservations_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/widgets/dc_status_badge.dart';

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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.reservas.length,
            itemBuilder: (context, index) {
              try {
                final reserva = provider.reservas[index];
                final reservaIdShort = reserva.id.length >= 8 ? reserva.id.substring(0, 8) : reserva.id;
                
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
                              'Reserva #$reservaIdShort',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DCStatusBadge(status: reserva.status, label: reserva.status),
                          ],
                        ),
                        const Divider(),
                        Text('Cliente: ${reserva.cliente?.nomeCompleto ?? "N/A"}'),
                        Text('Veículo: ${reserva.veiculo?.modelo?.marca ?? ""} ${reserva.veiculo?.modelo?.nome ?? ""} (${reserva.veiculo?.placa ?? "N/A"})'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Symbols.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text('${reserva.dataInicio != null ? dateFormat.format(reserva.dataInicio) : "N/A"} - ${reserva.dataFim != null ? dateFormat.format(reserva.dataFim) : "N/A"}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (reserva.status == 'PENDENTE_PAGAMENTO')
                              TextButton(
                                onPressed: () => _updateStatus(context, reserva.id, 'RESERVADA'),
                                child: const Text('Confirmar Pagamento'),
                              ),
                            if (reserva.status == 'RESERVADA')
                              TextButton(
                                onPressed: () => _updateStatus(context, reserva.id, 'ATIVA'),
                                child: const Text('Iniciar Aluguel'),
                              ),
                            if (reserva.status == 'ATIVA')
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(120, 40),
                                ),
                                onPressed: () => _updateStatus(context, reserva.id, 'FINALIZADA'),
                                child: const Text('Finalizar'),
                              ),
                          ],
                        )
                      ],
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
