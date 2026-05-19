import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../calls/api_core.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/loading/app_loading.dart';

class ManagerSettingsScreen extends StatefulWidget {
  const ManagerSettingsScreen({super.key});

  @override
  State<ManagerSettingsScreen> createState() => _ManagerSettingsScreenState();
}

class _ManagerSettingsScreenState extends State<ManagerSettingsScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isEditingPassword = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final authProvider = context.read<AuthProvider>();

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
        if (mounted) {
          AppFeedback.showSuccess('Foto de perfil removida!');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(e, fallback: 'Erro ao remover foto.');
        }
      }
      return;
    }

    final source = action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final image = await picker.pickImage(source: source, imageQuality: 70);

    if (image != null) {
      if (!mounted) return;
      try {
        await AppLoading.wrap(
          () => authProvider.updateProfilePhoto(File(image.path)),
          message: 'Atualizando foto de perfil...',
        );
        if (mounted) {
          AppFeedback.showSuccess('Foto de perfil atualizada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(e, fallback: 'Erro ao atualizar foto.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;
    final prefs = user?.preferencias ?? {};

    return ManagerScaffold(
      title: 'Configurações',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perfil Section
            Text(
              'Perfil do Gerente',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: colorScheme.primaryContainer,
                          backgroundImage: user?.imagemUrl != null
                              ? CachedNetworkImageProvider(
                                  '$apiBaseUrl/usuarios/me/foto?v=${user!.imagemUrl}',
                                  headers: authHeaders,
                                )
                              : null,
                          child: user?.imagemUrl == null
                              ? Icon(Symbols.person, size: 30, color: colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: IconButton(
                              icon: const Icon(Symbols.edit_square, size: 18, color: Colors.white),
                              onPressed: _pickAndUploadImage,
                              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email.split('@')[0].toUpperCase() ?? 'GERENTE',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              user?.tipo ?? 'GERENTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              'Preferências do Sistema',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Tema
            ListTile(
              leading: const Icon(Symbols.dark_mode),
              title: const Text('Tema Escuro'),
              subtitle: const Text('Alternar entre tema claro e escuro'),
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (val) {
                  themeProvider.toggleTheme(val);
                  authProvider.updatePreferences({'tema': val ? 'dark' : 'light'});
                },
              ),
            ),
            const Divider(),

            // Notificações
            ListTile(
              leading: const Icon(Symbols.notifications),
              title: const Text('Notificações Push'),
              subtitle: const Text('Receber alertas de novas reservas'),
              trailing: Switch(
                value: prefs['notificacoes'] ?? true,
                onChanged: (val) {
                  authProvider.updatePreferences({'notificacoes': val});
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                'Tipos de notificação',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            SwitchListTile(
              title: const Text('Novas reservas'),
              subtitle: const Text('Quando uma reserva é criada'),
              value: prefs['notificacao_reserva_nova'] ?? true,
              onChanged: (val) => authProvider.updatePreferences({'notificacao_reserva_nova': val}),
            ),
            SwitchListTile(
              title: const Text('Cancelamentos'),
              subtitle: const Text('Quando uma reserva é cancelada'),
              value: prefs['notificacao_reserva_cancelada'] ?? true,
              onChanged: (val) => authProvider.updatePreferences({'notificacao_reserva_cancelada': val}),
            ),
            SwitchListTile(
              title: const Text('Pagamentos confirmados'),
              subtitle: const Text('Quando um pagamento é aprovado'),
              value: prefs['notificacao_pagamento_aprovado'] ?? true,
              onChanged: (val) => authProvider.updatePreferences({'notificacao_pagamento_aprovado': val}),
            ),
            SwitchListTile(
              title: const Text('Mensagens do WhatsApp'),
              subtitle: const Text('Novas mensagens de clientes'),
              value: prefs['notificacao_whatsapp'] ?? true,
              onChanged: (val) => authProvider.updatePreferences({'notificacao_whatsapp': val}),
            ),
            SwitchListTile(
              title: const Text('Atrasos'),
              subtitle: const Text('Reservas com devolução em atraso'),
              value: prefs['notificacao_atraso'] ?? true,
              onChanged: (val) => authProvider.updatePreferences({'notificacao_atraso': val}),
            ),
            SwitchListTile(
              title: const Text('Manutenção de veículos'),
              subtitle: const Text('Mudança para status de manutenção'),
              value: prefs['notificacao_manutencao'] ?? true,
              onChanged: (val) => authProvider.updatePreferences({'notificacao_manutencao': val}),
            ),
            const Divider(),

            // Segurança
            ListTile(
              leading: const Icon(Symbols.lock),
              title: const Text('Segurança'),
              subtitle: const Text('Alterar minha senha de acesso'),
              trailing: TextButton(
                onPressed: () => setState(() => _isEditingPassword = !_isEditingPassword),
                child: Text(_isEditingPassword ? 'Cancelar' : 'Alterar'),
              ),
            ),

            if (_isEditingPassword) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha Atual',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nova Senha',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          try {
                            await authProvider.changePassword(
                              _newPasswordController.text,
                            );
                            if (mounted) {
                              setState(() => _isEditingPassword = false);
                              _oldPasswordController.clear();
                              _newPasswordController.clear();
                              AppFeedback.showSuccess('Senha alterada com sucesso!');
                            }
                          } catch (e) {
                            if (mounted) {
                              AppFeedback.showError(e, fallback: 'Erro ao alterar senha.');
                            }
                          }
                        },
                        child: const Text('Confirmar Alteração'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (mounted) context.go('/login');
                },
                icon: const Icon(Symbols.logout, color: Colors.red),
                label: const Text('Sair da Conta', style: TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Drive Connect v1.2.0',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
