import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../calls/api_core.dart';
import '../widgets/edit_profile_dialog.dart';
import '../../../../core/feedback/app_feedback.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfile(BuildContext context, dynamic user) {
    if (user == null) return;
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(user: user),
    );
  }

  Future<void> _pickImage(BuildContext context, AuthProvider authProvider) async {
    final picker = ImagePicker();

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.photo_camera),
              title: const Text('Tirar Foto'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Symbols.image),
              title: const Text('Escolher da Galeria'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (authProvider.user?.imagemUrl != null)
              ListTile(
                leading: const Icon(Symbols.delete, color: Colors.red),
                title: const Text('Remover Foto Atual', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
          ],
        ),
      ),
    );

    if (action == null) return;

    if (action == 'remove') {
      try {
        await authProvider.removeProfilePhoto();
        if (context.mounted) {
          AppFeedback.showSuccess('Foto removida com sucesso!');
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(e, fallback: 'Erro ao remover foto.');
        }
      }
      return;
    }

    final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final image = await picker.pickImage(source: source, imageQuality: 70);

    if (image != null) {
      try {
        // AuthProvider.updateProfilePhoto espera File em algumas implementações, 
        // mas o image_picker retorna XFile. Convertemos para File.
        await authProvider.updateProfilePhoto(File(image.path));
        if (context.mounted) {
          AppFeedback.showSuccess('Foto atualizada com sucesso!');
        }
      } catch (e) {
        if (context.mounted) {
          AppFeedback.showError(e, fallback: 'Erro ao atualizar foto.');
        }
      }
    }
  }

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
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user?.imagemUrl != null
                      ? CachedNetworkImageProvider(
                          '$apiBaseUrl/usuarios/me/foto?v=${user!.imagemUrl}',
                          headers: authHeaders,
                        )
                      : null,
                  child: user?.imagemUrl == null
                      ? Icon(Symbols.person, size: 40, color: theme.colorScheme.onPrimaryContainer)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Symbols.photo_camera, size: 18, color: Colors.white),
                      onPressed: () => _pickImage(context, authProvider),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.nome ?? 'Usuário',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(user?.email ?? 'email@exemplo.com', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 32),
            
            _buildProfileItem(Symbols.person, 'Dados Pessoais', () => _showEditProfile(context, user)),
            _buildProfileItem(Symbols.credit_card, 'Métodos de Pagamento', () {}),
            _buildProfileItem(Symbols.history, 'Histórico de Aluguéis', () => context.push('/my-reservations')),
            _buildProfileItem(Symbols.help, 'Ajuda e Suporte', () {}),
            _buildProfileItem(Symbols.settings, 'Configurações', () => context.push('/profile/settings')),
            
            const SizedBox(height: 24),
            _buildProfileItem(
              Symbols.logout, 
              'Sair da Conta', 
              () async {
                await authProvider.logout();
                if (context.mounted) context.go('/login');
              },
              color: Colors.orange,
            ),
            _buildProfileItem(
              Symbols.delete_forever, 
              'Excluir Conta', 
              () => _confirmDeleteAccount(context, authProvider),
              color: theme.colorScheme.error,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/explore');
              break;
            case 2:
              context.go('/my-reservations');
              break;
          }
        },
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

  void _confirmDeleteAccount(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Tem certeza que deseja desativar sua conta? '
          'Você perderá o acesso ao aplicativo e aos dados vinculados a este perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              try {
                await authProvider.deleteAccount();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  context.go('/login');
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppFeedback.showError(e, fallback: 'Erro ao excluir conta.');
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
