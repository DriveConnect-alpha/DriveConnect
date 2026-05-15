import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../calls/api_core.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../explore/providers/explore_provider.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../core/widgets/dc_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchVeiculos();
    });
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    switch (index) {
      case 0:
        break; // Já na home
      case 1:
        context.push('/explore');
        break;
      case 2:
        context.push('/my-reservations');
        break;
      case 3:
        context.push('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final exploreProvider = context.watch<ExploreProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => exploreProvider.fetchVeiculos(),
          child: CustomScrollView(
            slivers: [
              // Header com saudação
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, ${user?.nome.split(' ')[0] ?? 'Visitante'}!',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pronto para sua próxima viagem?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Symbols.person, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),

              // Banner de Busca
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: DCCard(
                    color: theme.colorScheme.primary,
                    onTap: () => context.push('/explore'),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Encontre o carro perfeito',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore mais de 100 veículos disponíveis hoje.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Symbols.search, color: Colors.white, size: 40),
                      ],
                    ),
                  ),
                ),
              ),

              // Categorias
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Text(
                        'Categorias',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildCategoryItem(context, 'SUV', Symbols.directions_car),
                          _buildCategoryItem(context, 'Sedan', Symbols.minor_crash),
                          _buildCategoryItem(context, 'Hatch', Symbols.airport_shuttle),
                          _buildCategoryItem(context, 'Luxo', Symbols.diamond),
                          _buildCategoryItem(context, 'Econômico', Symbols.eco),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Veículos em Destaque
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Veículos em Destaque',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              if (exploreProvider.loading)
                const SliverFillRemaining(
                  child: DCLoading(message: 'Carregando destaques...'),
                )
              else if (exploreProvider.veiculos.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text('Nenhum veículo disponível')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final veiculo = exploreProvider.veiculos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildFeaturedCard(context, veiculo),
                        );
                      },
                      childCount: exploreProvider.veiculos.take(3).length,
                    ),
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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
  }

  Widget _buildCategoryItem(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, dynamic veiculo) {
    final theme = Theme.of(context);
    return DCCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/vehicle-detail', extra: veiculo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              image: veiculo.imagemUrl != null
                  ? DecorationImage(
                      image: NetworkImage(
                        '$apiBaseUrl/storage/carros/${veiculo.imagemUrl}',
                        headers: vehicleImageHeaders,
                      ),
                      fit: BoxFit.cover,
                    )
                  : const DecorationImage(
                      image: NetworkImage('https://placehold.co/600x400/png?text=Veiculo'),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      veiculo.modelo?.nome ?? 'Modelo',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      veiculo.modelo?.marca ?? 'Marca',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  'R\$ ${veiculo.modelo?.tipoCarro?.precoBaseDiaria ?? 0}/dia',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
