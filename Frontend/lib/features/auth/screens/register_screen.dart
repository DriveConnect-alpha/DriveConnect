import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/dc_button.dart';
import '../../../core/widgets/dc_text_field.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // TODO: Chamar registro no AuthProvider/Service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso! Faça login.')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Preencha seus dados para começar',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                DCTextField(
                  label: 'Nome Completo',
                  hint: 'Ex: João Silva',
                  controller: _nomeController,
                  prefixIcon: Icons.person_outline,
                  validator: (value) => value!.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                DCTextField(
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) => value!.contains('@') ? null : 'E-mail inválido',
                ),
                const SizedBox(height: 16),
                DCTextField(
                  label: 'CPF',
                  hint: '000.000.000-00',
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) => value!.isEmpty ? 'Informe seu CPF' : null,
                ),
                const SizedBox(height: 16),
                DCTextField(
                  label: 'Senha',
                  hint: 'Mínimo 6 caracteres',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) => value!.length >= 6 ? null : 'Senha muito curta',
                ),
                const SizedBox(height: 16),
                DCTextField(
                  label: 'Confirmar Senha',
                  hint: 'Repita sua senha',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) => value == _passwordController.text ? null : 'As senhas não coincidem',
                ),
                const SizedBox(height: 32),
                DCButton(
                  label: 'Criar Conta',
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Já tem uma conta? Entrar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
