import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/admin_provider.dart';
import '../models/admin_user.dart';
import '../../manager/widgets/manager_scaffold.dart';
import '../../../calls/api_core.dart';
import '../../../core/feedback/app_feedback.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminUser> _filteredUsers(List<AdminUser> users) {
    if (_searchQuery.isEmpty) return users;
    final query = _searchQuery.toLowerCase();
    return users.where((user) {
      final nome = user.nome.toLowerCase();
      final email = user.email.toLowerCase();
      final tipo = user.tipo.toLowerCase();
      return nome.contains(query) || email.contains(query) || tipo.contains(query);
    }).toList();
  }

  void _showEditDialog(BuildContext context, AdminUser user) {
    final nomeController = TextEditingController(text: user.nome);
    final emailController = TextEditingController(text: user.email);
    final senhaController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: senhaController,
              decoration: const InputDecoration(
                labelText: 'Resetar Senha (Opcional)',
                hintText: 'Deixe vazio para manter a atual',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await context.read<AdminProvider>().updateUser(
                  user.id,
                  nome: nomeController.text,
                  email: emailController.text,
                  novaSenha: senhaController.text.isNotEmpty ? senhaController.text : null,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  AppFeedback.showSuccess('Usuário atualizado com sucesso');
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppFeedback.showError(e, fallback: 'Erro ao atualizar usuário.');
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, AdminUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar Usuário'),
        content: Text('Tem certeza que deseja desativar o usuário ${user.nome}? Ele perderá o acesso ao sistema.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await context.read<AdminProvider>().deleteUser(user.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppFeedback.showSuccess('Usuário desativado com sucesso');
                }
              } catch (e) {
                if (ctx.mounted) {
                  AppFeedback.showError(e, fallback: 'Erro ao desativar usuário.');
                }
              }
            },
            child: const Text('Desativar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ManagerScaffold(
      title: 'Administração de Usuários',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/manager'),
          icon: const Icon(Symbols.dashboard),
          label: const Text('Gerência'),
          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/manager/admin/create-manager'),
        icon: const Icon(Symbols.person_add),
        label: const Text('Novo Gerente'),
      ),
      child: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Erro ao carregar usuários: ${provider.error}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchUsers(),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          final filtered = _filteredUsers(provider.users);
          final total = provider.users.length;
          final admins = provider.users.where((u) => u.tipo == 'ADMIN').length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            Color.lerp(colorScheme.primary, colorScheme.primaryContainer, 0.28)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.8,
                        children: [
                          _StatChip(label: 'Total Usuários', value: total.toString(), icon: Symbols.shield_person),
                          _StatChip(label: 'Administradores', value: admins.toString(), icon: Symbols.admin_panel_settings),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  labelText: 'Buscar usuários',
                                  hintText: 'Nome, E-mail ou Tipo',
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  prefixIcon: const Icon(Symbols.search, size: 20),
                                  filled: true,
                                  fillColor: colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => setState(() => _searchQuery = _searchController.text),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Filtrar'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Symbols.filter_alt_off, size: 18),
                              tooltip: 'Limpar filtros',
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.surfaceVariant,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Symbols.person_off, size: 48, color: colorScheme.outline.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'Nenhum usuário encontrado' : 'Nenhum resultado para a busca',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: provider.fetchUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final user = filtered[index];
                            IconData icon;
                            Color iconColor;

                            switch (user.tipo) {
                              case 'ADMIN':
                                icon = Symbols.admin_panel_settings;
                                iconColor = Colors.red;
                                break;
                              case 'GERENTE':
                                icon = Symbols.manage_accounts;
                                iconColor = Colors.blue;
                                break;
                              default:
                                icon = Symbols.person;
                                iconColor = Colors.green;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: iconColor.withAlpha(40),
                                  backgroundImage: user.imagemUrl != null
                                      ? CachedNetworkImageProvider(
                                          '$apiBaseUrl/storage/perfil/${user.imagemUrl}',
                                          headers: vehicleImageHeaders,
                                        )
                                      : null,
                                  child: user.imagemUrl == null 
                                    ? Icon(icon, color: iconColor)
                                    : null,
                                ),
                                title: Text(user.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: iconColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.tipo,
                                        style: TextStyle(fontSize: 10, color: iconColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Symbols.edit, size: 20),
                                      onPressed: () => _showEditDialog(context, user),
                                      tooltip: 'Editar',
                                    ),
                                    if (user.tipo != 'ADMIN')
                                      IconButton(
                                        icon: const Icon(Symbols.delete, size: 20, color: Colors.red),
                                        onPressed: () => _confirmDeactivate(context, user),
                                        tooltip: 'Desativar',
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.onPrimary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.84),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
