import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import '../../../../core/models/filial.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_text_field.dart';
import '../providers/inventory_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _placaController = TextEditingController();
  final _anoController = TextEditingController();
  final _corController = TextEditingController();
  
  int? _selectedModeloId;
  String? _selectedFilialId;

  // Mocks temporários para seleção (idealmente viriam de providers)
  final List<Modelo> _modelos = [
    Modelo(id: 1, nome: 'Corolla', marca: 'Toyota'),
    Modelo(id: 2, nome: 'Civic', marca: 'Honda'),
    Modelo(id: 3, nome: 'HB20', marca: 'Hyundai'),
  ];

  final List<Filial> _filiais = [
    Filial(id: '1', nome: 'São Paulo - Matriz', ativo: true, cidade: 'São Paulo', uf: 'SP'),
    Filial(id: '2', nome: 'Rio de Janeiro - Galeão', ativo: true, cidade: 'Rio de Janeiro', uf: 'RJ'),
  ];

  @override
  void dispose() {
    _placaController.dispose();
    _anoController.dispose();
    _corController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedModeloId == null || _selectedFilialId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o modelo e a filial')),
        );
        return;
      }

      final provider = context.read<InventoryProvider>();
      final novoVeiculo = Veiculo(
        id: '', // Backend gera
        modeloId: _selectedModeloId,
        filialId: _selectedFilialId,
        placa: _placaController.text,
        ano: int.parse(_anoController.text),
        cor: _corController.text,
        status: 'DISPONIVEL',
      );

      final success = await provider.addVehicle(novoVeiculo);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo adicionado com sucesso!')),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Veículo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedModeloId,
                decoration: const InputDecoration(labelText: 'Modelo'),
                items: _modelos.map((m) {
                  return DropdownMenuItem(value: m.id, child: Text('${m.marca} ${m.nome}'));
                }).toList(),
                onChanged: (val) => setState(() => _selectedModeloId = val),
                validator: (val) => val == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFilialId,
                decoration: const InputDecoration(labelText: 'Filial'),
                items: _filiais.map((f) {
                  return DropdownMenuItem(value: f.id, child: Text(f.nome ?? ''));
                }).toList(),
                onChanged: (val) => setState(() => _selectedFilialId = val),
                validator: (val) => val == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DCTextField(
                label: 'Placa',
                hint: 'AAA-0000',
                controller: _placaController,
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DCTextField(
                label: 'Ano',
                hint: 'Ex: 2023',
                controller: _anoController,
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DCTextField(
                label: 'Cor',
                hint: 'Ex: Branco',
                controller: _corController,
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 32),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
                ),
              DCButton(
                label: 'Salvar Veículo',
                isLoading: provider.isLoading,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
