import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/reservations_provider.dart';
import '../../../../calls/frota.call.dart';
import '../../../../core/models/reserva.dart';
import '../../../../core/models/veiculo.dart';

class EditReservationModal extends StatefulWidget {
  final Reserva reserva;

  const EditReservationModal({super.key, required this.reserva});

  @override
  State<EditReservationModal> createState() => _EditReservationModalState();
}

class _EditReservationModalState extends State<EditReservationModal> {
  DateTimeRange? _selectedDateRange;
  dynamic _selectedVehicle; // Can be Veiculo model or Map from selection
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: widget.reserva.dataInicio,
      end: widget.reserva.dataFim,
    );
    _selectedVehicle = widget.reserva.veiculo;
  }

  String _getVehicleLabel() {
    if (_selectedVehicle == null) return 'Selecionar Veículo';
    if (_selectedVehicle is Veiculo) {
      return '${_selectedVehicle.placa} - ${_selectedVehicle.modelo?.nome ?? ""}';
    }
    // Caso seja o Map retornado pela FrotaCall
    return '${_selectedVehicle['placa']} - ${_selectedVehicle['modelo']['nome']}';
  }

  void _selectDates() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _selectedVehicle = null;
      });
    }
  }

  void _pickVehicle() {
    if (_selectedDateRange == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SelectionList(
          title: 'Selecionar Veículo Disponível',
          fetchData: (onSuccess, onError) => FrotaCall.listarDisponiveis(
            filialId: widget.reserva.filialRetiradaId ?? "",
            dataInicio: _selectedDateRange!.start.toIso8601String(),
            dataFim: _selectedDateRange!.end.toIso8601String(),
            onSuccess: onSuccess,
            onError: onError,
          ),
          itemBuilder: (item) => ListTile(
            leading: const Icon(Symbols.directions_car),
            title: Text('${item['modelo']['marca']} ${item['modelo']['nome']}'),
            subtitle: Text('Placa: ${item['placa']} | Cor: ${item['cor']}'),
            onTap: () {
              setState(() => _selectedVehicle = item);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _save() async {
    final vehicleId = _selectedVehicle is Veiculo ? _selectedVehicle.id : _selectedVehicle?['id'];
    
    final result = await context.read<ReservationsProvider>().updateReservation(
      reservaId: widget.reserva.id,
      veiculoId: vehicleId,
      dataInicio: _selectedDateRange?.start.toIso8601String(),
      dataFim: _selectedDateRange?.end.toIso8601String(),
    );

    if (result != null && mounted) {
      final link = result['linkPagamento'];
      Navigator.pop(context);
      _showNewLinkDialog(link);
    }
  }

  void _showNewLinkDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reserva Atualizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A reserva foi atualizada. O novo link de pagamento é:'),
            const SizedBox(height: 12),
            SelectableText(link, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado!')));
            },
            child: const Text('Copiar'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUpdating = context.watch<ReservationsProvider>().isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Editar Reserva', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Symbols.close)),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildPickerField(
            context,
            label: _selectedDateRange == null 
              ? 'Selecionar Datas' 
              : '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}',
            icon: Symbols.calendar_month,
            onTap: _selectDates,
          ),
          const SizedBox(height: 16),
          
          _buildPickerField(
            context,
            label: _getVehicleLabel(),
            icon: Symbols.directions_car,
            onTap: _pickVehicle,
            isEnabled: _selectedDateRange != null,
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: isUpdating ? null : _save,
              child: isUpdating 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Salvar Alterações'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerField(BuildContext context, {
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
            Expanded(child: Text(label, style: TextStyle(color: isEnabled ? colorScheme.onSurface : colorScheme.outline))),
            Icon(Symbols.arrow_drop_down, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

// Re-implementing SelectionList but public
class SelectionList extends StatefulWidget {
  final String title;
  final void Function(void Function(List<Map<String, dynamic>>), void Function(String)) fetchData;
  final Widget Function(Map<String, dynamic>) itemBuilder;

  const SelectionList({super.key, required this.title, required this.fetchData, required this.itemBuilder});

  @override
  State<SelectionList> createState() => _SelectionListState();
}

class _SelectionListState extends State<SelectionList> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.fetchData((data) {
      if (mounted) setState(() { _items = data; _filtered = data; _loading = false; });
    }, (err) {
      if (mounted) setState(() { _error = err; _loading = false; });
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
              onChanged: (val) => setState(() {
                _filtered = _items.where((item) => item.values.join(' ').toLowerCase().contains(val.toLowerCase())).toList();
              }),
            ),
          ),
          Expanded(
            child: _loading ? const Center(child: CircularProgressIndicator()) :
                   _error != null ? Center(child: Text(_error!)) :
                   ListView.builder(
                     itemCount: _filtered.length,
                     itemBuilder: (context, index) => widget.itemBuilder(_filtered[index]),
                   ),
          ),
        ],
      ),
    );
  }
}
