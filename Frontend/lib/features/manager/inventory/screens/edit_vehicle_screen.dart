import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import '../../../../core/models/filial.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_text_field.dart';
import '../providers/inventory_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../calls/filial.call.dart';
import '../../../../calls/frota.call.dart';

class EditVehicleScreen extends StatefulWidget {
  final Veiculo veiculo;
  const EditVehicleScreen({super.key, required this.veiculo});

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _placaController;
  late final TextEditingController _anoController;
  late final TextEditingController _corController;
  
  int? _selectedModeloId;
  String? _selectedFilialId;
  String? _selectedStatus;
  
  List<Modelo> _modelos = [];
  List<Filial> _filiais = [];

  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _placaController = TextEditingController(text: widget.veiculo.placa);
    _anoController = TextEditingController(text: widget.veiculo.ano.toString());
    _corController = TextEditingController(text: widget.veiculo.cor);
    _selectedModeloId = widget.veiculo.modeloId;
    _selectedFilialId = widget.veiculo.filialId;
    _selectedStatus = widget.veiculo.status;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    
    int loadedCount = 0;
    void checkDone() {
      loadedCount++;
      if (loadedCount == 2) setState(() => _isLoadingData = false);
    }

    await FrotaCall.listarModelos(
      onSuccess: (data) {
        setState(() => _modelos = data.map((m) => Modelo.fromJson(m)).toList());
        checkDone();
      },
      onError: (msg) => checkDone(),
    );

    await FilialCall.listar(
      onSuccess: (data) {
        setState(() => _filiais = data.map((f) => Filial.fromJson(f)).toList());
        checkDone();
      },
      onError: (msg) => checkDone(),
    );
  }

  @override
  void dispose() {
    _placaController.dispose();
    _anoController.dispose();
    _corController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<InventoryProvider>();
      final success = await provider.updateVehicle(
        widget.veiculo.id,
        modeloId: _selectedModeloId,
        filialId: _selectedFilialId,
        placa: _placaController.text,
        ano: int.parse(_anoController.text),
        cor: _corController.text,
        status: _selectedStatus,
      );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo atualizado com sucesso!')),
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
        title: const Text('Editar Veículo'),
      ),
      body: _isLoadingData 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                items: _filiais.map<DropdownMenuItem<String>>((f) {
                  return DropdownMenuItem<String>(value: f.id, child: Text(f.nome ?? ''));
                }).toList(),
                onChanged: (val) => setState(() => _selectedFilialId = val),
                validator: (val) => val == null ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DCTextField(
                      label: 'Placa',
                      controller: _placaController,
                      validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DCTextField(
                      label: 'Ano',
                      controller: _anoController,
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DCTextField(
                label: 'Cor',
                controller: _corController,
                validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'DISPONIVEL', child: Text('Disponível')),
                  DropdownMenuItem(value: 'ALUGADO', child: Text('Alugado')),
                  DropdownMenuItem(value: 'MANUTENCAO', child: Text('Manutenção')),
                ],
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
              const SizedBox(height: 32),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(provider.error!, style: const TextStyle(color: Colors.red)),
                ),
              DCButton(
                label: 'Salvar Alterações',
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
