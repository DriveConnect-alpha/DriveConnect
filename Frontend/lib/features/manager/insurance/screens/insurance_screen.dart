import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../widgets/manager_scaffold.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Planos de Seguro',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.shield, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Configuração de Seguros em desenvolvimento'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Novo Plano de Seguro'),
            ),
          ],
        ),
      ),
    );
  }
}
