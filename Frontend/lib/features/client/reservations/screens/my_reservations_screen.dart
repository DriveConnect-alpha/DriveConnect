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
              : provider.reservas.isEmpty
                  ? _buildEmptyState(context)
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 2) return;
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/explore');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Symbols.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Symbols.search), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Symbols.calendar_month), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Symbols.person), label: 'Perfil'),
        ],
      ),
    );
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.calendar_today,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma reserva encontrada',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Você ainda não possui reservas. Explore nossos veículos e encontre o carro ideal para sua próxima viagem!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go('/explore'),
            icon: const Icon(Symbols.search),
            label: const Text('Explorar Veículos'),
          ),
        ],
      ),
    );
  }
}
