import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/admin_provider.dart';
import '../models/admin_user.dart';
import '../../manager/widgets/manager_scaffold.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário atualizado com sucesso')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuário desativado com sucesso')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
                  );
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
    return ManagerScaffold(
      title: 'Administração de Usuários',
      actions: [
        TextButton.icon(
          onPressed: () => context.go('/manager'),
          icon: const Icon(Symbols.dashboard),
          label: const Text('Visão de Gerente'),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
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

          final users = provider.users;

          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }

          return RefreshIndicator(
            onRefresh: provider.fetchUsers,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
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
                      child: Icon(icon, color: iconColor),
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
          );
        },
      ),
    );
  }
}
