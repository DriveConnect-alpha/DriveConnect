import 'package:flutter/material.dart';
import '../../widgets/manager_scaffold.dart';

class ManagerSettingsScreen extends StatelessWidget {
  const ManagerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManagerScaffold(
      title: 'Ajustes do Sistema',
      child: Center(
        child: Text('Configurações do Gerente'),
      ),
    );
  }
}
