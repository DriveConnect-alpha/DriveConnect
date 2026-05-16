import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/booking_provider.dart';
import '../../../../calls/api_core.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_loading.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.read<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final veiculo = bookingProvider.selectedVehicle;
    final clienteId = authProvider.user?.perfilId ?? 'guest';

    if (veiculo == null || bookingProvider.startDate == null || bookingProvider.endDate == null) {
      return const Scaffold(body: Center(child: Text('Erro: Dados da reserva incompletos')));
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
                      image: veiculo.imagemUrl != null
                          ? DecorationImage(
                              image: NetworkImage(
                                '$apiBaseUrl/storage/carros/${veiculo.imagemUrl}',
                                headers: vehicleImageHeaders,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: veiculo.imagemUrl == null
                        ? Icon(Symbols.directions_car, color: theme.colorScheme.onSurfaceVariant, size: 32)
                        : null,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Symbols.credit_card, color: Color(0xFF00628b)),
                    title: const Text('Cartão de Crédito (via InfinitePay)'),
                    subtitle: const Text('Pagamento seguro e rápido'),
                    trailing: Radio<String>(
                      value: 'INFINITEPAY',
                      groupValue: bookingProvider.paymentMethod,
                      onChanged: (v) => bookingProvider.setPaymentMethod(v!),
                    ),
                    onTap: () => bookingProvider.setPaymentMethod('INFINITEPAY'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Symbols.payments, color: Colors.green),
                    title: const Text('Dinheiro (Pagamento na Retirada)'),
                    subtitle: const Text('Pague diretamente na filial'),
                    trailing: Radio<String>(
                      value: 'DINHEIRO',
                      groupValue: bookingProvider.paymentMethod,
                      onChanged: (v) => bookingProvider.setPaymentMethod(v!),
                    ),
                    onTap: () => bookingProvider.setPaymentMethod('DINHEIRO'),
                  ),
                ],
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
            label: bookingProvider.paymentMethod == 'DINHEIRO' ? 'Confirmar Reserva' : 'Confirmar e Pagar',
            isLoading: bookingProvider.isLoading,
            onPressed: () async {
              final success = await bookingProvider.initiatePayment(clienteId);
              if (success && context.mounted) {
                if (bookingProvider.paymentMethod == 'DINHEIRO') {
                  context.go('/my-reservations');
                } else {
                  _showPaymentModal(context);
                }
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    
    // Abre o link automaticamente se disponível
    if (provider.paymentLink != null) {
      final uri = Uri.parse(provider.paymentLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    // Polling real de status através do provider
    bool isPaid = false;
    while (mounted && !isPaid) {
      await provider.pollPaymentStatus();
      if (provider.paymentStatus == 'RESERVADA') {
        isPaid = true;
        break;
      }
      await Future.delayed(const Duration(seconds: 4));
    }

    if (mounted && isPaid) {
      context.go('/my-reservations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<BookingProvider>();
    final veiculo = provider.selectedVehicle;
    
    // Calcula total novamente para o preview (ou poderia vir do provider se salvo)
    final dias = provider.endDate!.difference(provider.startDate!).inDays;
    final totalDiarias = (veiculo?.modelo?.tipoCarro?.precoBaseDiaria ?? 0) * dias;
    const taxaServico = 45.00;
    const planoProtecao = 80.00;
    final totalGeral = totalDiarias + taxaServico + planoProtecao;

    return Container(
      padding: const EdgeInsets.all(24),
      height: 600, // Aumentado para o preview
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.credit_score, size: 60, color: Color(0xFF00628b)),
          const SizedBox(height: 16),
          Text(
            'Link de Pagamento Gerado!',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Preview Card
          DCCard(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(veiculo?.modelo?.nome ?? 'Veículo', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('R\$ ${totalGeral.toStringAsFixed(2)}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Symbols.calendar_month, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd/MM').format(provider.startDate!)} até ${DateFormat('dd/MM').format(provider.endDate!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          if (provider.paymentLink != null) ...[
            DCButton(
              label: 'Pagar Agora (Abrir Link)',
              onPressed: () async {
                final uri = Uri.parse(provider.paymentLink!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: provider.paymentLink!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copiado para a área de transferência!'), behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Symbols.content_copy, size: 20),
              label: const Text('Copiar Link de Pagamento'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const DCLoading(message: 'Aguardando confirmação automática...'),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar e revisar', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
