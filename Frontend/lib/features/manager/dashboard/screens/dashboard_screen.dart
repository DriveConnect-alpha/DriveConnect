import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/dashboard_stats.dart';
import '../providers/dashboard_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../widgets/manager_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    return ManagerScaffold(
      title: 'Dashboard',
      child: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.stats;
          final colorScheme = theme.colorScheme;
          final greetingName = authProvider.user?.email.split('@')[0] ?? 'Gerente';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary,
                        Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.25)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Symbols.dashboard, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Olá, $greetingName!',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Resumo operacional em tempo real para acompanhar reservas, frota e atendimento.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (authProvider.isAdmin) ...[
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.16)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Symbols.admin_panel_settings, color: Colors.white),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Você está na visão de administrador.',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/manager/admin/users'),
                                style: TextButton.styleFrom(foregroundColor: Colors.white),
                                child: const Text('Abrir painel'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100
                        ? 4
                        : constraints.maxWidth > 700
                            ? 2
                            : 1;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: constraints.maxWidth > 700 ? 1.7 : 2.1,
                      children: [
                        _buildStatCard(
                          context,
                          title: 'Reservas ativas',
                          value: stats?.activeReservations.toString() ?? '-',
                          icon: Symbols.book_online,
                          accent: const Color(0xFF2563EB),
                          footer: 'Em andamento agora',
                        ),
                        _buildStatCard(
                          context,
                          title: 'Veículos disponíveis',
                          value: stats?.availableVehicles.toString() ?? '-',
                          icon: Symbols.directions_car,
                          accent: const Color(0xFF16A34A),
                          footer: 'Prontos para locação',
                        ),
                        _buildStatCard(
                          context,
                          title: 'Receita do mês',
                          value: stats == null ? '-' : 'R\$ ${stats.monthlyRevenue.toStringAsFixed(0)}',
                          icon: Symbols.payments,
                          accent: const Color(0xFFF59E0B),
                          footer: 'Faturamento acumulado',
                        ),
                        _buildStatCard(
                          context,
                          title: 'Novos clientes',
                          value: stats?.newClients.toString() ?? '-',
                          icon: Symbols.person_add,
                          accent: const Color(0xFF8B5CF6),
                          footer: 'Entradas recentes',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text(
                      'Ações rápidas',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: constraints.maxWidth > 700 ? 1.35 : 1.1,
                      children: [
                        _buildActionCard(context, 'Reservas', Symbols.list_alt, '/manager/reservations'),
                        _buildActionCard(context, 'Inventário', Symbols.inventory_2, '/manager/inventory'),
                        _buildActionCard(context, 'Clientes', Symbols.group, '/manager/clients'),
                        _buildActionCard(context, 'Seguros', Symbols.shield, '/manager/insurance'),
                        if (authProvider.isAdmin)
                          _buildActionCard(context, 'Usuários', Symbols.admin_panel_settings, '/manager/admin/users'),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required String footer,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DCCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              Icon(Symbols.trending_up, color: colorScheme.tertiary, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                footer,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, String route) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: colorScheme.onPrimaryContainer),
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Abrir módulo',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
