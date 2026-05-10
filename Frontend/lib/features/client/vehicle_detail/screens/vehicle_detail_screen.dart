import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../booking/providers/booking_provider.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Veiculo veiculo;

  const VehicleDetailScreen({super.key, required this.veiculo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                'https://placehold.co/800x600/png?text=${veiculo.modelo?.nome}',
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Symbols.favorite),
                style: IconButton.styleFrom(backgroundColor: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                icon: const Icon(Symbols.share),
                style: IconButton.styleFrom(backgroundColor: Colors.white),
              ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            veiculo.modelo?.marca ?? 'Marca',
                            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            veiculo.modelo?.nome ?? 'Modelo',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'R\$ ${veiculo.modelo?.tipoCarro?.precoBaseDiaria ?? 0}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('/dia', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Especificações', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _buildSpecItem(context, Symbols.calendar_today, 'Ano', '${veiculo.ano}'),
                      _buildSpecItem(context, Symbols.settings_input_component, 'Câmbio', 'Automático'),
                      _buildSpecItem(context, Symbols.local_gas_station, 'Combustível', 'Flex'),
                      _buildSpecItem(context, Symbols.group, 'Assentos', '5 Lugares'),
                      _buildSpecItem(context, Symbols.palette, 'Cor', veiculo.cor ?? 'N/A'),
                      _buildSpecItem(context, Symbols.category, 'Categoria', veiculo.modelo?.tipoCarro?.nome ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Sobre o veículo', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Este ${veiculo.modelo?.nome} oferece o máximo em conforto e segurança para sua viagem. Equipado com tecnologia de ponta e revisado rigorosamente para garantir sua tranquilidade.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 100), // Espaço para o botão fixo
                ],
              ),
            ),
          ),
        ],
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
            label: 'Alugar Agora',
            onPressed: () {
              context.read<BookingProvider>().selectVehicle(veiculo);
              context.push('/booking-period');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(BuildContext context, IconData icon, String title, String value) {
    return DCCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
