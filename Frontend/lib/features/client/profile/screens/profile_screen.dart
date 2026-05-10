import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/dc_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driveconnect'),
            ),
            const SizedBox(height: 16),
            Text(
              user?.nome ?? 'Usuário',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(user?.email ?? 'email@exemplo.com', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 32),
            
            _buildProfileItem(Symbols.person, 'Dados Pessoais', () {}),
            _buildProfileItem(Symbols.credit_card, 'Métodos de Pagamento', () {}),
            _buildProfileItem(Symbols.history, 'Histórico de Aluguéis', () {}),
            _buildProfileItem(Symbols.help, 'Ajuda e Suporte', () {}),
            _buildProfileItem(Symbols.settings, 'Configurações', () {}),
            
            const SizedBox(height: 24),
            _buildProfileItem(
              Symbols.logout, 
              'Sair da Conta', 
              () => authProvider.logout(),
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.bottom(12),
      child: DCCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF00628b)),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Symbols.chevron_right, size: 20, color: color?.withAlpha(128) ?? Colors.grey),
          ],
        ),
      ),
    );
  }
}
