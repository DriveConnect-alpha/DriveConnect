import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dc_button.dart';

class NotFoundScreen extends StatelessWidget {
  final String? location;

  const NotFoundScreen({super.key, this.location});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Ops! Não encontramos essa página.',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (location != null) ...[
                const SizedBox(height: 8),
                Text(
                  location!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              DCButton(
                label: authProvider.isAuthenticated
                    ? (authProvider.isManager ? 'Ir para o painel' : 'Ir para a Home')
                    : 'Ir para o Login',
                onPressed: () {
                  if (!authProvider.isAuthenticated) {
                    context.go('/login');
                    return;
                  }
                  context.go(authProvider.isManager ? '/manager' : '/home');
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    context.go('/');
                  }
                },
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
