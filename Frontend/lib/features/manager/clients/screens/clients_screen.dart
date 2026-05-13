import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../providers/clients_provider.dart';
import '../../widgets/manager_scaffold.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientsProvider>().fetchClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Gestão de Clientes',
      child: Consumer<ClientsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.clientes.length,
            itemBuilder: (context, index) {
              final cliente = provider.clientes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Symbols.person)),
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
          );
        },
      ),
    );
  }
}
