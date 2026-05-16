import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/dc_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.currentUser;

    // Preferências locais
    final Map<String, dynamic> prefs = Map.from(user?.preferencias ?? {
      'notifications': {'email': true, 'push': true, 'whatsapp': true},
      'theme': 'light'
    });

    final notifications = prefs['notifications'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, 'Aparência'),
          DCCard(
            child: SwitchListTile(
              secondary: const Icon(Symbols.dark_mode),
              title: const Text('Modo Escuro'),
              subtitle: const Text('Alternar entre tema claro e escuro'),
              value: themeProvider.isDarkMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) {
                themeProvider.toggleTheme(val);
                // Sincroniza com o backend se desejar
                final newPrefs = Map<String, dynamic>.from(prefs);
                newPrefs['theme'] = val ? 'dark' : 'light';
                authProvider.updatePreferences(newPrefs);
              },
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle(context, 'Notificações'),
          DCCard(
            child: Column(
              children: [
                _buildSwitchItem(
                  'E-mail',
                  'Receber atualizações por e-mail',
                  notifications['email'] ?? true,
                  (val) => _updateNotif(context, authProvider, prefs, 'email', val),
                ),
                const Divider(indent: 16, endIndent: 16),
                _buildSwitchItem(
                  'Push Notifications',
                  'Notificações diretas no seu dispositivo',
                  notifications['push'] ?? true,
                  (val) => _updateNotif(context, authProvider, prefs, 'push', val),
                ),
                const Divider(indent: 16, endIndent: 16),
                _buildSwitchItem(
                  'WhatsApp',
                  'Receber comunicados via WhatsApp',
                  notifications['whatsapp'] ?? true,
                  (val) => _updateNotif(context, authProvider, prefs, 'whatsapp', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionTitle(context, 'Segurança'),
          DCCard(
            onTap: () => _showChangePassword(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Symbols.lock_reset, color: Color(0xFF00628b)),
                  SizedBox(width: 16),
                  Text('Alterar Senha'),
                  Spacer(),
                  Icon(Symbols.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateNotif(BuildContext context, AuthProvider provider, Map<String, dynamic> currentPrefs, String key, bool value) {
    final newPrefs = Map<String, dynamic>.from(currentPrefs);
    final newNotifs = Map<String, dynamic>.from(newPrefs['notifications']);
    newNotifs[key] = value;
    newPrefs['notifications'] = newNotifs;
    provider.updatePreferences(newPrefs);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  void _showChangePassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar Senha'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Nova Senha'),
              obscureText: true,
              validator: (v) => (v?.length ?? 0) < 8 ? 'Mínimo 8 caracteres' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              decoration: const InputDecoration(labelText: 'Confirmar Senha'),
              obscureText: true,
              validator: (v) => v != _passwordController.text ? 'Senhas não conferem' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Alterar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().changePassword(_passwordController.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
