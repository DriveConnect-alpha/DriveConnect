import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_status_badge.dart';
import '../providers/my_reservations_provider.dart';
import '../../../../core/widgets/dc_loading.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyReservationsProvider>().fetchMyReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<MyReservationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
      ),
      body: provider.isLoading
          ? const Center(child: DCLoading())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.reservas.length,
                  itemBuilder: (context, index) {
                    final reserva = provider.reservas[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DCCard(
                        onTap: () => context.push('/my-reservations/detail', extra: reserva),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Reserva #${reserva.id.substring(0, 8)}', style: theme.textTheme.labelSmall),
                                DCStatusBadge(status: reserva.status, label: reserva.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                    image: const DecorationImage(
                                      image: NetworkImage('https://placehold.co/100x100/png?text=Car'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(reserva.veiculo?.modelo?.nome ?? 'Veículo',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                      Text('${reserva.dataInicio.day} Out - ${reserva.dataFim.day} Out',
                                          style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ),
                                const Icon(Symbols.chevron_right, color: Colors.grey),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pago', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(
                                  'R\$ ${reserva.valorTotal?.toStringAsFixed(2) ?? '0,00'}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
