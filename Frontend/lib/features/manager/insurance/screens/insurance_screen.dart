import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../core/models/plano_seguro.dart';
import '../providers/insurance_provider.dart';
import '../../widgets/manager_scaffold.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/widgets/dc_feedback_message.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsuranceProvider>().fetchPlanos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ManagerScaffold(
      title: 'Planos de Seguro',
      child: Consumer<InsuranceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: DCFeedbackMessage(
                message: provider.error!,
                type: AppFeedbackType.error,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.planos.length,
            itemBuilder: (context, index) {
              final plano = provider.planos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Symbols.shield, color: Colors.blue),
                  title: Text(plano.nome),
                  subtitle: Text('R\$ ${plano.precoDiaria.toStringAsFixed(2)} / dia'),
                  trailing: IconButton(
                    icon: const Icon(Symbols.edit),
                    onPressed: () => _showEditDialog(context, plano),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, PlanoSeguro plano) {
    final controller = TextEditingController(text: plano.percentual.toString());
    bool isActive = plano.ativo;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Editar ${plano.nome}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Percentual da Taxa (%)',
                  hintText: 'Ex: 5.0',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Plano Ativo'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                final newPercent = double.tryParse(controller.text);
                if (newPercent != null) {
                  final success = await context.read<InsuranceProvider>().updatePlano(
                    plano.id, 
                    {
                      'percentual': newPercent,
                      'ativo': isActive,
                    },
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      AppFeedback.showSuccess('Plano atualizado');
                    } else {
                      AppFeedback.showError('Erro ao atualizar plano.');
                    }
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
