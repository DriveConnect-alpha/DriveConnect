import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/dc_card.dart';
import '../../../../calls/gerente.call.dart';
import '../../../../calls/frota.call.dart';
import '../../../../calls/filial.call.dart';
import '../../../../calls/seguro.call.dart';
import '../providers/reservations_provider.dart';
import '../../widgets/manager_scaffold.dart';

class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() => _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');

  // Form selections
  Map<String, dynamic>? _selectedClient;
  Map<String, dynamic>? _selectedVehicle;
  Map<String, dynamic>? _selectedFilialRetirada;
  Map<String, dynamic>? _selectedFilialDevolucao;
  Map<String, dynamic>? _selectedSeguro;
  DateTimeRange? _selectedDateRange;
  String _metodoPagamento = 'INFINITEPAY'; // Default is Link

  bool _isCustomMetodo = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Optionally load default filial if manager
  }

  void _selectDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedVehicle = null; // Reset vehicle choice when dates change
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null || _selectedVehicle == null || _selectedDateRange == null || _selectedFilialRetirada == null || _selectedFilialDevolucao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios')),
      );
      return;
    }

    final successData = await context.read<ReservationsProvider>().createReservation(
      veiculoId: _selectedVehicle!['id'],
      clienteId: _selectedClient!['id'],
      filialRetiradaId: _selectedFilialRetirada!['id'],
      filialDevolucaoId: _selectedFilialDevolucao!['id'],
      dataInicio: _selectedDateRange!.start.toIso8601String(),
      dataFim: _selectedDateRange!.end.toIso8601String(),
      planoSeguroId: _selectedSeguro?['id'],
      metodoPagamento: _metodoPagamento,
    );

    if (successData != null && mounted) {
      final reservaId = successData['reservaId'];
      final linkPagamento = successData['linkPagamento'];

      if (linkPagamento != null) {
        _showSuccessWithLink(linkPagamento);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva criada com sucesso!')),
        );
        context.pop();
      }
    } else if (mounted) {
      final error = context.read<ReservationsProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Erro ao criar reserva')),
      );
    }
  }

  void _showSuccessWithLink(String link) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Reserva Criada!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('O link de pagamento foi gerado. Deseja copiar o link agora?'),
            const SizedBox(height: 16),
            SelectableText(
              link,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard logic could go here
              Navigator.pop(context);
              GoRouter.of(this.context).pop();
            },
            child: const Text('OK'),
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
      title: 'Nova Reserva',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Cliente'),
              _buildPickerField(
                label: _selectedClient == null ? 'Selecionar Cliente' : _selectedClient!['nome_completo'],
                icon: Symbols.person,
                onTap: _pickClient,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Período'),
              _buildPickerField(
                label: _selectedDateRange == null 
                  ? 'Selecionar Datas' 
                  : '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}',
                icon: Symbols.calendar_month,
                onTap: _selectDates,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Filiais'),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerField(
                      label: _selectedFilialRetirada == null ? 'Retirada' : _selectedFilialRetirada!['nome'],
                      icon: Symbols.location_on,
                      onTap: () => _pickFilial(isDevolucao: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerField(
                      label: _selectedFilialDevolucao == null ? 'Devolução' : _selectedFilialDevolucao!['nome'],
                      icon: Symbols.keyboard_return,
                      onTap: () => _pickFilial(isDevolucao: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Veículo'),
              _buildPickerField(
                label: _selectedVehicle == null ? 'Selecionar Veículo' : '${_selectedVehicle!['placa']} - ${_selectedVehicle!['modelo']['nome']}',
                icon: Symbols.directions_car,
                onTap: _pickVehicle,
                isEnabled: _selectedDateRange != null && _selectedFilialRetirada != null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Outros Detalhes'),
              _buildPickerField(
                label: _selectedSeguro == null ? 'Escolha o Seguro (Opcional)' : _selectedSeguro!['nome'],
                icon: Symbols.shield,
                onTap: _pickSeguro,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Pagamento'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'INFINITEPAY', label: Text('Link'), icon: Icon(Symbols.link)),
                  ButtonSegment(value: 'DINHEIRO', label: Text('Dinheiro'), icon: Icon(Symbols.payments)),
                ],
                selected: {_metodoPagamento},
                onSelectionChanged: (newVal) {
                  setState(() => _metodoPagamento = newVal.first);
                },
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: context.watch<ReservationsProvider>().isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: context.watch<ReservationsProvider>().isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Criar Reserva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(isEnabled ? 0.3 : 0.1)),
          color: isEnabled ? null : colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isEnabled ? colorScheme.primary : colorScheme.outline),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isEnabled ? colorScheme.onSurface : colorScheme.outline,
                  fontWeight: isEnabled ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Symbols.arrow_drop_down, color: isEnabled ? colorScheme.outline : colorScheme.outline.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  void _pickClient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SelectionList(
          title: 'Selecionar Cliente',
          fetchData: (onSuccess, onError) => GerenteCall.listarClientes(onSuccess: onSuccess, onError: onError),
          itemBuilder: (item) => ListTile(
            title: Text(item['nome_completo']),
            subtitle: Text(item['cpf']),
            onTap: () {
              setState(() => _selectedClient = item);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _pickFilial({required bool isDevolucao}) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _SelectionList(
          title: 'Selecionar Filial',
          fetchData: (onSuccess, onError) => FilialCall.listar(
            onSuccess: (list) => onSuccess(list), 
            onError: onError,
          ),
          itemBuilder: (item) => ListTile(
            title: Text(item['nome']),
            subtitle: Text('${item['cidade']} - ${item['uf']}'),
            onTap: () {
              setState(() {
                if (isDevolucao) {
                  _selectedFilialDevolucao = item;
                } else {
                  _selectedFilialRetirada = item;
                  if (_selectedFilialDevolucao == null) _selectedFilialDevolucao = item;
                  _selectedVehicle = null; // Re-filter vehicles
                }
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _pickVehicle() {
    if (_selectedDateRange == null || _selectedFilialRetirada == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SelectionList(
          title: 'Veículos Disponíveis',
          // Note: In a real scenario we'd use a more specific availability check
          fetchData: (onSuccess, onError) => FrotaCall.listarVeiculos(
            filialId: _selectedFilialRetirada!['id'],
            onSuccess: (list) {
              // Simple filter for available status, the backend will do final check
              final available = list.where((v) => v['status'] == 'DISPONIVEL' || v['status'] == 'ALUGADO').toList();
              onSuccess(available);
            },
            onError: onError,
          ),
          itemBuilder: (item) => ListTile(
            leading: const Icon(Symbols.directions_car),
            title: Text('${item['modelo']['marca']} ${item['modelo']['nome']}'),
            subtitle: Text('Placa: ${item['placa']} | Ano: ${item['ano']}'),
            trailing: Text(item['status'], style: TextStyle(
              color: item['status'] == 'DISPONIVEL' ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            )),
            onTap: () {
              setState(() => _selectedVehicle = item);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _pickSeguro() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _SelectionList(
          title: 'Planos de Seguro',
          fetchData: (onSuccess, onError) => SeguroCall.listar(onSuccess: (l) => onSuccess(l), onError: onError),
          itemBuilder: (item) => ListTile(
            title: Text(item['nome']),
            subtitle: Text('${item['percentual']}% do valor da diária'),
            onTap: () {
              setState(() => _selectedSeguro = item);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}

class _SelectionList extends StatefulWidget {
  final String title;
  final void Function(void Function(List<Map<String, dynamic>>), void Function(String)) fetchData;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  const _SelectionList({
    required this.title,
    required this.fetchData,
    required this.itemBuilder,
  });

  @override
  State<_SelectionList> createState() => _SelectionListState();
}

class _SelectionListState extends State<_SelectionList> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.fetchData(
      (data) {
        if (mounted) {
          setState(() {
            _items = data;
            _filtered = data;
            _loading = false;
          });
        }
      },
      (err) {
        if (mounted) {
          setState(() {
            _error = err;
            _loading = false;
          });
        }
      },
    );
  }

  void _onSearch(String val) {
    setState(() {
      _filtered = _items.where((item) {
        final searchString = item.values.join(' ').toLowerCase();
        return searchString.contains(val.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Symbols.close)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Symbols.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(child: Text(_error!))
                : _filtered.isEmpty
                  ? const Center(child: Text('Nenhum resultado encontrado'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) => widget.itemBuilder(_filtered[index]),
                    ),
          ),
        ],
      ),
    );
  }
}
