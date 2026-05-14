import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_status_badge.dart';
import '../../../../core/widgets/dc_button.dart';
import '../providers/my_reservations_provider.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Reserva reserva;

  const ReservationDetailScreen({super.key, required this.reserva});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final provider = context.watch<MyReservationsProvider>();

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
                    Text(reserva.id.length > 8 ? reserva.id.substring(0, 8) : reserva.id, 
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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

            // Dados do Cliente
            if (reserva.cliente != null) ...[
              Text('Dados do Locatário', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DCCard(
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      Symbols.person,
                      'Nome',
                      reserva.cliente!.nomeCompleto,
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Symbols.email,
                      'E-mail',
                      reserva.cliente!.usuario?.email ?? 'N/A',
                    ),
                    if (reserva.cliente!.cpf != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Symbols.badge,
                        'CPF',
                        reserva.cliente!.cpf,
                      ),
                    ],
                    if (reserva.cliente!.telefone != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Symbols.phone,
                        'Telefone',
                        reserva.cliente!.telefone!,
                      ),
                    ],
                    if (reserva.cliente!.rg != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Symbols.badge,
                        'RG',
                        reserva.cliente!.rg!,
                      ),
                    ],
                    if (reserva.cliente!.cnh != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        Symbols.drive_eta,
                        'CNH',
                        reserva.cliente!.cnh!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

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
                isLoading: provider.isLoading,
                onPressed: () {
                  // Abrir link de pagamento
                },
              ),

            if (reserva.status == 'RESERVADA' || reserva.status == 'ATIVA')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DCButton(
                  label: 'Renovar Locação',
                  isLoading: provider.isLoading,
                  onPressed: () => _handleRenew(context),
                ),
              ),

            if (reserva.status == 'RESERVADA' || reserva.status == 'PENDENTE_PAGAMENTO')
              DCButton(
                label: 'Cancelar Reserva',
                isLoading: provider.isLoading,
                onPressed: () => _handleCancel(context),
                isPrimary: false, 
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  void _handleRenew(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: reserva.dataFim.add(const Duration(days: 1)),
      firstDate: reserva.dataFim.add(const Duration(days: 1)),
      lastDate: reserva.dataFim.add(const Duration(days: 30)),
      helpText: 'Selecione a nova data de devolução',
    );

    if (picked != null && context.mounted) {
      final success = await context.read<MyReservationsProvider>().estenderReserva(reserva.id, picked);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva renovada com sucesso!')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<MyReservationsProvider>().error ?? 'Erro ao renovar reserva.')),
          );
        }
      }
    }
  }

  void _handleCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva?'),
        content: const Text('Tem certeza que deseja cancelar esta reserva? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sim, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<MyReservationsProvider>().cancelarReserva(reserva.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva cancelada com sucesso.')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<MyReservationsProvider>().error ?? 'Erro ao cancelar reserva.')),
          );
        }
      }
    }
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
