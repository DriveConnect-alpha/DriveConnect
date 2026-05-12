import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/veiculo.dart';
import '../../../../core/models/modelo.dart';
import '../../../../core/models/filial.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_text_field.dart';
import '../providers/inventory_provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../calls/filial.call.dart';
import '../../../../calls/frota.call.dart';

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
  final _precoController = TextEditingController();
  
  int? _selectedModeloId;
  String? _selectedFilialId;
  
  List<Modelo> _modelos = [];
  List<Filial> _filiais = [];
  List<Map<String, dynamic>> _opcionais = [];
  final List<String> _selectedOpcionaisIds = [];

  bool _isLoadingData = true;

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    
    int loadedCount = 0;
    void checkDone() {
      loadedCount++;
      if (loadedCount == 3) setState(() => _isLoadingData = false);
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

    await FrotaCall.listarOpcionais(
      onSuccess: (data) {
        setState(() => _opcionais = data);
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
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
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

      final success = await provider.addVehicle(
        novoVeiculo,
        images: _selectedImages,
        precoDiaria: _precoController.text.isNotEmpty ? double.parse(_precoController.text) : null,
        itensIds: _selectedOpcionaisIds,
      );
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veículo adicionado com sucesso!')),
        );
        context.pop();
      }
    }
  }

  void _showAddModelDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    int? selectedTypeId;
    List<Map<String, dynamic>> types = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          if (types.isEmpty) {
            FrotaCall.listarCategorias(
              onSuccess: (data) => setDialogState(() => types = data),
              onError: (_) {},
            );
          }

          return AlertDialog(
            title: const Text('Novo Modelo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Marca')),
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Modelo')),
                  DropdownButtonFormField<int>(
                    value: selectedTypeId,
                    hint: const Text('Categoria'),
                    items: types.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'] as int,
                        child: Text(t['nome'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => selectedTypeId = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty && brandController.text.isNotEmpty && selectedTypeId != null) {
                    FrotaCall.registrarModelo(
                      nome: nameController.text,
                      marca: brandController.text,
                      tipoCarroId: selectedTypeId!,
                      onSuccess: (_) {
                        Navigator.pop(context);
                        _loadInitialData();
                      },
                      onError: (msg) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                      },
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showAddBranchDialog() {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    final ufController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Filial'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nome da Filial')),
              TextField(controller: cityController, decoration: const InputDecoration(labelText: 'Cidade')),
              TextField(controller: ufController, decoration: const InputDecoration(labelText: 'UF')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  FilialCall.registrar(
                    nome: nameController.text,
                    cidade: cityController.text,
                    uf: ufController.text,
                    onSuccess: (_) {
                      Navigator.pop(context);
                      _loadInitialData();
                    },
                    onError: (msg) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                    },
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Veículo'),
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedModeloId,
                      decoration: const InputDecoration(labelText: 'Modelo'),
                      items: _modelos.map((m) {
                        return DropdownMenuItem(value: m.id, child: Text('${m.marca} ${m.nome}'));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedModeloId = val),
                      validator: (val) => val == null ? 'Obrigatório' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.add_circle, color: Colors.blue),
                    onPressed: _showAddModelDialog,
                    tooltip: 'Adicionar Modelo',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilialId,
                      decoration: const InputDecoration(labelText: 'Filial'),
                      items: _filiais.map<DropdownMenuItem<String>>((f) {
                        return DropdownMenuItem<String>(value: f.id, child: Text(f.nome ?? ''));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedFilialId = val),
                      validator: (val) => val == null ? 'Obrigatório' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Symbols.add_location, color: Colors.green),
                    onPressed: _showAddBranchDialog,
                    tooltip: 'Adicionar Filial',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DCTextField(
                      label: 'Placa',
                      hint: 'AAA-0000',
                      controller: _placaController,
                      validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DCTextField(
                      label: 'Ano',
                      hint: 'Ex: 2023',
                      controller: _anoController,
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DCTextField(
                      label: 'Cor',
                      hint: 'Ex: Branco',
                      controller: _corController,
                      validator: (val) => val!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DCTextField(
                      label: 'Preço Diária (Opcional)',
                      hint: r'R$ 0.00',
                      controller: _precoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Itens do Veículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _opcionais.map((item) {
                  final id = item['id'];
                  final nome = item['nome'];
                  final isSelected = _selectedOpcionaisIds.contains(id);
                  return FilterChip(
                    label: Text(nome, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedOpcionaisIds.add(id);
                        } else {
                          _selectedOpcionaisIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Imagens do Veículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Symbols.close, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Symbols.add_a_photo),
                label: const Text('Selecionar Imagens'),
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
