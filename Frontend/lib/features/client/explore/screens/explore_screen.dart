import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../providers/explore_provider.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_chip.dart';
import '../../../../core/widgets/dc_loading.dart';
import '../../../../calls/api_core.dart';
import 'package:intl/intl.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedType = 'Todos';

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchVeiculos();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exploreProvider = context.watch<ExploreProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Veículos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar marca ou modelo...',
                    prefixIcon: Icon(Symbols.search, color: theme.colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      context.read<ExploreProvider>().setSearchQuery(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Todos', 'SUV', 'Sedan', 'Hatch', 'Luxo'].map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: DCChip(
                          label: type,
                          isSelected: selectedType == type,
                          onSelected: () {
                            setState(() => selectedType = type);
                            context.read<ExploreProvider>().setCategory(type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: exploreProvider.loading
          ? const DCLoading(message: 'Buscando veículos...')
          : exploreProvider.veiculos.isEmpty
              ? const Center(child: Text('Nenhum veículo encontrado'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exploreProvider.veiculos.length,
                  itemBuilder: (context, index) {
                    final veiculo = exploreProvider.veiculos[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DCCard(
                        padding: EdgeInsets.zero,
                        onTap: () => context.push('/vehicle-detail', extra: veiculo),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceVariant,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                                      ? Center(
                                                  child: Icon(Symbols.directions_car, size: 48, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: theme.cardTheme.color ?? theme.colorScheme.surface,
                                              shape: BoxShape.circle,
                                            ),
                                    child: Icon(
                                      Symbols.favorite,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${veiculo.modelo?.marca ?? 'Marca'} • ${veiculo.modelo?.tipoCarro?.nome ?? 'Categoria'}',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                          Text(
                                            veiculo.modelo?.nome ?? 'Modelo',
                                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          if (veiculo.filial != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  Icon(Symbols.location_on, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    veiculo.filial?.nome ?? '',
                                                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: NumberFormat.currency(symbol: 'R\$', decimalDigits: 2).format(veiculo.modelo?.tipoCarro?.precoBaseDiaria ?? 0),
                                              style: theme.textTheme.titleLarge?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '/dia', style: theme.textTheme.labelSmall),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSpec(Symbols.calendar_today, '${veiculo.ano}'),
                                      _buildSpec(Symbols.settings_input_component, 'Auto'),
                                      _buildSpec(Symbols.local_gas_station, 'Flex'),
                                      _buildSpec(Symbols.group, '5'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 2:
              context.go('/my-reservations');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Symbols.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Symbols.search), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Symbols.calendar_month), label: 'Reservas'),
          BottomNavigationBarItem(icon: Icon(Symbols.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildSpec(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
