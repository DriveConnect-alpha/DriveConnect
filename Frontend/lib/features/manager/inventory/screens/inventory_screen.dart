import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/inventory_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/widgets/dc_status_badge.dart';
import '../../../../calls/api_core.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Inventário de Veículos',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/manager/inventory/add'),
        child: const Icon(Symbols.add),
      ),
      child: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.veiculos.length,
            itemBuilder: (context, index) {
              final veiculo = provider.veiculos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: veiculo.capaUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            '$apiBaseUrl/storage/carros/${veiculo.capaUrl}',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Symbols.directions_car, size: 40),
                          ),
                        )
                      : const Icon(Symbols.directions_car, size: 40),
                  title: Text('${veiculo.modelo?.marca} ${veiculo.modelo?.nome}'),
                  subtitle: Text('Placa: ${veiculo.placa} | Ano: ${veiculo.ano}'),
                  trailing: DCStatusBadge(
                    status: veiculo.status,
                    label: veiculo.status,
                  ),
                  onTap: () => _showStatusDialog(context, veiculo),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showStatusDialog(BuildContext context, veiculo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Disponível'),
              onTap: () => _updateStatus(context, veiculo.id, 'DISPONIVEL'),
            ),
            ListTile(
              title: const Text('Manutenção'),
              onTap: () => _updateStatus(context, veiculo.id, 'MANUTENCAO'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, String id, String status) async {
    final success = await context.read<InventoryProvider>().updateVehicleStatus(id, status);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Status atualizado' : 'Erro ao atualizar')),
      );
    }
  }
}
