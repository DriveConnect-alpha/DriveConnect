import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_status_badge.dart';
import '../../../../core/widgets/dc_button.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Reserva reserva;

  const ReservationDetailScreen({super.key, required this.reserva});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Reserva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status e ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Código da Reserva', style: theme.textTheme.labelSmall),
                    Text(reserva.id, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                DCStatusBadge(status: reserva.status, label: reserva.status),
              ],
            ),
            const SizedBox(height: 24),

            // Veículo
            Text('Veículo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DCCard(
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage('https://placehold.co/200x150/png?text=Car'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva.veiculo?.modelo?.nome ?? 'Modelo',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${reserva.veiculo?.modelo?.marca} • ${reserva.veiculo?.placa}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Datas e Locais
            Text('Retirada e Devolução', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DCCard(
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    Symbols.calendar_today,
                    'Início',
                    dateFormat.format(reserva.dataInicio),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    Symbols.event_available,
                    'Fim',
                    dateFormat.format(reserva.dataFim),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pagamento
            Text('Resumo Financeiro', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DCCard(
              child: Column(
                children: [
                  _buildPriceRow('Valor das Diárias', reserva.valorTotal != null ? (reserva.valorTotal! - (reserva.valorSeguro ?? 0)) : 0),
                  _buildPriceRow('Seguro (${reserva.planoSeguroId ?? "N/A"})', reserva.valorSeguro ?? 0),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'R\$ ${reserva.valorTotal?.toStringAsFixed(2) ?? '0,00'}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            if (reserva.status == 'PENDENTE_PAGAMENTO' && reserva.linkPagamento != null)
              DCButton(
                label: 'Pagar Agora',
                onPressed: () {
                  // Abrir link de pagamento
                },
              ),
              
            if (reserva.status == 'RESERVADA')
              DCButton(
                label: 'Cancelar Reserva',
                onPressed: () {},
                backgroundColor: Colors.red.shade50,
                textColor: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text('R\$ ${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
