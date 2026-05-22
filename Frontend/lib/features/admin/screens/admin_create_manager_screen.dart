import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/admin_provider.dart';
import '../../filial/services/ifilial_service.dart';
import '../../filial/models/filial.dart';
import '../../manager/widgets/manager_scaffold.dart';
import '../../../core/feedback/app_feedback.dart';

class AdminCreateManagerScreen extends StatefulWidget {
  const AdminCreateManagerScreen({super.key});

  @override
  State<AdminCreateManagerScreen> createState() => _AdminCreateManagerScreenState();
}

class _AdminCreateManagerScreenState extends State<AdminCreateManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedFilialId;
  List<Filial> _filiais = [];
  bool _isLoadingFiliais = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadFiliais();
  }

  Future<void> _loadFiliais() async {
    try {
      final filiais = await context.read<IFilialService>().listFiliais();
      if (mounted) {
        setState(() {
          _filiais = filiais;
          _isLoadingFiliais = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(e, fallback: 'Erro ao carregar filiais.');
        setState(() => _isLoadingFiliais = false);
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFilialId == null) {
      AppFeedback.showWarning('Selecione uma filial.');
      return;
    }

    try {
      await context.read<AdminProvider>().registerManager(
        nomeCompleto: _nomeController.text,
        email: _emailController.text,
        password: _passwordController.text,
        filialId: _selectedFilialId!,
      );

      if (mounted) {
        AppFeedback.showSuccess('Gerente cadastrado com sucesso!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(e, fallback: 'Erro ao cadastrar gerente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AdminProvider>().isLoading;

    return ManagerScaffold(
      title: 'Cadastrar Gerente',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Nova Conta de Gerente',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Preencha os dados abaixo para criar um novo acesso de gerente.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          prefixIcon: Icon(Symbols.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Symbols.mail),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null || !value.contains('@') ? 'E-mail inválido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Symbols.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Symbols.visibility : Symbols.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) => value == null || value.length < 6 ? 'Mínimo de 6 caracteres' : null,
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingFiliais)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ))
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedFilialId,
                          decoration: const InputDecoration(
                            labelText: 'Filial Responsável',
                            prefixIcon: Icon(Symbols.store),
                            border: OutlineInputBorder(),
                          ),
                          items: _filiais.map((f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.nome),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedFilialId = value),
                          validator: (value) => value == null ? 'Selecione uma filial' : null,
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: isLoading || _isLoadingFiliais ? null : _submit,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Cadastrar Gerente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
