import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_loading.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingProvider = context.watch<BookingProvider>();
    final veiculo = bookingProvider.selectedVehicle;

    if (veiculo == null) {
      return const Scaffold(body: Center(child: Text('Erro: Nenhum veículo selecionado')));
    }

    final dias = bookingProvider.endDate!.difference(bookingProvider.startDate!).inDays;
    final totalDiarias = (veiculo.modelo?.tipoCarro?.precoBaseDiaria ?? 0) * dias;
    const taxaServico = 45.00;
    const planoProtecao = 80.00;
    final totalGeral = totalDiarias + taxaServico + planoProtecao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo da Reserva'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo Veículo
            DCCard(
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 80,
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
                        Text(veiculo.modelo?.nome ?? 'Modelo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${veiculo.modelo?.marca} • ${veiculo.ano}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Valores', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DCCard(
              child: Column(
                children: [
                  _buildPriceRow('Diárias ($dias dias)', totalDiarias),
                  _buildPriceRow('Taxa de Serviço', taxaServico),
                  _buildPriceRow('Plano Proteção (Básico)', planoProtecao),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text('Total Geral', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        'R\$ ${totalGeral.toStringAsFixed(2)}',
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
            const SizedBox(height: 24),

            Text('Forma de Pagamento', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DCCard(
              child: ListTile(
                leading: const Icon(Symbols.credit_card, color: Color(0xFF00628b)),
                title: const Text('Cartão de Crédito (via InfinitePay)'),
                subtitle: const Text('Pagamento seguro e rápido'),
                trailing: Radio(value: true, groupValue: true, onChanged: (_) {}),
              ),
            ),
            const SizedBox(height: 40),

            if (bookingProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  bookingProvider.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: DCButton(
            label: 'Confirmar e Pagar',
            isLoading: bookingProvider.isLoading,
            onPressed: () async {
              final success = await bookingProvider.initiatePayment();
              if (success && context.mounted) {
                _showPaymentModal(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text('R\$ ${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _PaymentProcessingSheet(),
    );
  }
}

class _PaymentProcessingSheet extends StatefulWidget {
  const _PaymentProcessingSheet();

  @override
  State<_PaymentProcessingSheet> createState() => _PaymentProcessingSheetState();
}

class _PaymentProcessingSheetState extends State<_PaymentProcessingSheet> {
  @override
  void initState() {
    super.initState();
    // Iniciar polling do status de pagamento aqui
    _startPolling();
  }

  void _startPolling() async {
    final provider = context.read<BookingProvider>();
    // Simulação de polling
    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      // No mundo real, verificaríamos o status via provider
      context.go('/my-reservations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DCLoading(message: 'Aguardando confirmação do pagamento...'),
          const SizedBox(height: 24),
          const Text(
            'Estamos processando seu pagamento via InfinitePay. Por favor, não feche esta tela.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar Pagamento'),
          ),
        ],
      ),
    );
  }
}
