import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../../../calls/filial.call.dart';
import '../../../../core/models/filial.dart';
import '../../../../core/models/gerente.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../widgets/manager_scaffold.dart';

class FiliaisScreen extends StatefulWidget {
  const FiliaisScreen({super.key});

  @override
  State<FiliaisScreen> createState() => _FiliaisScreenState();
}

class _FiliaisScreenState extends State<FiliaisScreen> {
  final List<Filial> _filiais = [];
  final List<Gerente> _gerentes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await FilialCall.listar(
      onSuccess: (data) {
        final filiais = data.map((f) => Filial.fromJson(f)).toList();
        setState(() => _filiais
          ..clear()
          ..addAll(filiais));
      },
      onError: (msg) => setState(() => _error = msg),
    );

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAdmin) {
      await FilialCall.listarGerentes(
        onSuccess: (data) {
          final gerentes = data.map((g) => Gerente.fromJson(g)).toList();
          setState(() => _gerentes
            ..clear()
            ..addAll(gerentes));
        },
        onError: (_) {},
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  List<Gerente> _gerentesDaFilial(String filialId) {
    return _gerentes.where((g) => g.filialId == filialId).toList();
  }

  Future<void> _showFilialForm({Filial? filial}) async {
    final isEditing = filial != null;
    final nomeController = TextEditingController(text: filial?.nome ?? '');
    final cepController = TextEditingController(text: filial?.cep ?? '');
    final ufController = TextEditingController(text: filial?.uf ?? '');
    final cidadeController = TextEditingController(text: filial?.cidade ?? '');
    final bairroController = TextEditingController(text: filial?.bairro ?? '');
    final ruaController = TextEditingController(text: filial?.rua ?? '');
    final numeroController = TextEditingController(text: filial?.numero ?? '');
    final complementoController = TextEditingController(text: filial?.complemento ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Editar Filial' : 'Nova Filial'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cepController,
                decoration: const InputDecoration(labelText: 'CEP'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cidadeController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: ufController,
                      decoration: const InputDecoration(labelText: 'UF'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bairroController,
                decoration: const InputDecoration(labelText: 'Bairro'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ruaController,
                decoration: const InputDecoration(labelText: 'Rua'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: numeroController,
                      decoration: const InputDecoration(labelText: 'Número'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: complementoController,
                      decoration: const InputDecoration(labelText: 'Complemento'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) return;

              if (isEditing) {
                await FilialCall.editar(
                  filialId: filial.id,
                  nome: nome,
                  cep: cepController.text,
                  uf: ufController.text,
                  cidade: cidadeController.text,
                  bairro: bairroController.text,
                  rua: ruaController.text,
                  numero: numeroController.text,
                  complemento: complementoController.text,
                  onSuccess: (_) {},
                  onError: (msg) => setState(() => _error = msg),
                );
              } else {
                await FilialCall.registrar(
                  nome: nome,
                  cep: cepController.text,
                  uf: ufController.text,
                  cidade: cidadeController.text,
                  bairro: bairroController.text,
                  rua: ruaController.text,
                  numero: numeroController.text,
                  complemento: complementoController.text,
                  onSuccess: (_) {},
                  onError: (msg) => setState(() => _error = msg),
                );
              }

              if (mounted) {
                Navigator.pop(ctx);
                await _loadData();
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDesativar(Filial filial) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAdmin) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desativar Filial'),
        content: Text('Tem certeza que deseja desativar "${filial.nome ?? 'Filial'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await FilialCall.desativar(
                filialId: filial.id,
                onSuccess: (_) {},
                onError: (msg) => setState(() => _error = msg),
              );
              if (mounted) {
                Navigator.pop(ctx);
                await _loadData();
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
    final authProvider = context.watch<AuthProvider>();

    return ManagerScaffold(
      title: 'Filiais',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: authProvider.isAdmin ? () => _showFilialForm() : null,
        label: const Text('Nova Filial'),
        icon: const Icon(Symbols.add_business),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          icon: const Icon(Symbols.refresh),
          onPressed: _loadData,
        ),
        if (authProvider.isAdmin)
          IconButton(
            tooltip: 'Cadastrar gerente',
            icon: const Icon(Symbols.person_add),
            onPressed: () => context.push('/manager/admin/create-manager'),
          ),
      ],
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (_filiais.isEmpty)
                    Center(
                      child: Text(
                        'Nenhuma filial cadastrada.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                      ),
                    )
                  else
                    ..._filiais.map((filial) {
                      final gerentes = _gerentesDaFilial(filial.id);
                      final gerenteLabel = gerentes.isEmpty
                          ? 'Sem gerente'
                          : gerentes.map((g) => g.nomeCompleto).join(', ');

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                filial.nome ?? 'Filial',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${filial.cidade ?? '-'} • ${filial.uf ?? '-'}',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Gerente: $gerenteLabel',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _showFilialForm(filial: filial),
                                    icon: const Icon(Symbols.edit),
                                    label: const Text('Editar'),
                                  ),
                                  if (authProvider.isAdmin)
                                    OutlinedButton.icon(
                                      onPressed: () => _confirmDesativar(filial),
                                      icon: const Icon(Symbols.delete, color: Colors.red),
                                      label: const Text('Desativar'),
                                    ),
                                  if (authProvider.isAdmin)
                                    OutlinedButton.icon(
                                      onPressed: () => context.push('/manager/admin/create-manager'),
                                      icon: const Icon(Symbols.person_add),
                                      label: const Text('Atribuir gerente'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
      ),
    );
  }
}
