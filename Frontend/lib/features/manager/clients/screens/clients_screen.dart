import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/clients_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../calls/api_core.dart';
import '../../../../core/models/cliente.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientsProvider>().fetchClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Cliente> _filteredClientes(List<Cliente> clientes) {
    if (_searchQuery.isEmpty) return clientes;
    final query = _searchQuery.toLowerCase();
    return clientes.where((cliente) {
      final name = cliente.nomeCompleto.toLowerCase();
      final cpf = cliente.cpf.toLowerCase();
      final email = cliente.usuario?.email.toLowerCase() ?? '';
      return name.contains(query) || cpf.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ManagerScaffold(
      title: 'Gestão de Clientes',
      child: Consumer<ClientsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.clientes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.clientes.isEmpty) {
            return Center(child: Text(provider.error!));
          }

          final filtered = _filteredClientes(provider.clientes);
          final total = provider.clientes.length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.28)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.8,
                        children: [
                          _StatChip(label: 'Cadastros', value: total.toString(), icon: Symbols.groups),
                          _StatChip(label: 'Filtrados', value: filtered.length.toString(), icon: Symbols.person_search),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Buscar clientes',
                                  hintText: 'Nome, CPF ou E-mail',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  prefixIcon: const Icon(Symbols.search, size: 20),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => setState(() => _searchQuery = _searchController.text),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Filtrar'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Symbols.filter_alt_off, size: 18),
                              tooltip: 'Limpar filtros',
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.surfaceVariant,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Symbols.person_off, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'Nenhum cliente cadastrado' : 'Nenhum resultado para a busca',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchClients(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final cliente = filtered[index];
                            final imageUrl = cliente.usuario?.imagemUrl;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: imageUrl != null
                                      ? CachedNetworkImageProvider(
                                          '$apiBaseUrl/storage/perfil/$imageUrl',
                                          headers: vehicleImageHeaders,
                                        )
                                      : null,
                                  child: imageUrl == null ? const Icon(Symbols.person) : null,
                                ),
                                title: Text(cliente.nomeCompleto),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cliente.usuario?.email ?? 'Sem e-mail'),
                                    Text('CPF: ${cliente.cpf}'),
                                  ],
                                ),
                                trailing: const Icon(Symbols.chevron_right),
                                onTap: () {
                                  context.push(
                                    '/manager/clients/reservations',
                                    extra: {
                                      'clienteId': cliente.id,
                                      'clienteNome': cliente.nomeCompleto,
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onPrimary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.84),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
