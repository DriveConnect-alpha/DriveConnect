import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../widgets/manager_scaffold.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Clientes',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.group, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Lista de Clientes em desenvolvimento'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Adicionar Novo Cliente'),
            ),
          ],
        ),
      ),
    );
  }
}
