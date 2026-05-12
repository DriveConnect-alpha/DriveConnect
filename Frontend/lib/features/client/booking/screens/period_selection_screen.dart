import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../../../../core/widgets/dc_button.dart';
import '../../../../core/widgets/dc_card.dart';
import '../../../../calls/filial.call.dart';
import '../../../../core/models/filial.dart';

class PeriodSelectionScreen extends StatefulWidget {
  const PeriodSelectionScreen({super.key});

  @override
  State<PeriodSelectionScreen> createState() => _PeriodSelectionScreenState();
}

class _PeriodSelectionScreenState extends State<PeriodSelectionScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _pickupBranchId;
  String? _returnBranchId;

  List<Filial> _filiais = [];
  bool _isLoadingFiliais = true;

  @override
  void initState() {
    super.initState();
    _loadFiliais();
  }

  Future<void> _loadFiliais() async {
    await FilialCall.listar(
      onSuccess: (data) {
        if (mounted) {
          setState(() {
            _filiais = data.map((f) => Filial.fromJson(f)).toList();
            _isLoadingFiliais = false;
          });
        }
      },
      onError: (msg) {
        if (mounted) {
          setState(() => _isLoadingFiliais = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Período e Local'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quando você precisa do carro?',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DCCard(
              onTap: _selectDateRange,
              child: Row(
                children: [
                  const Icon(Symbols.calendar_month, color: Color(0xFF00628b)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Período de Locação', style: theme.textTheme.labelSmall),
                      Text(
                        _startDate == null 
                            ? 'Selecionar datas' 
                            : '${DateFormat('dd/MM').format(_startDate!)} - ${DateFormat('dd/MM').format(_endDate!)}',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Symbols.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Onde você vai retirar e devolver?',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBranchSelector(
              label: 'Retirada',
              value: _pickupBranchId,
              onChanged: (val) => setState(() => _pickupBranchId = val),
            ),
            const SizedBox(height: 12),
            _buildBranchSelector(
              label: 'Devolução',
              value: _returnBranchId,
              onChanged: (val) => setState(() => _returnBranchId = val),
            ),
            const SizedBox(height: 40),
            if (bookingProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  bookingProvider.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            DCButton(
              label: 'Verificar Disponibilidade',
              isLoading: bookingProvider.isLoading,
              onPressed: _handleCheckAvailability,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchSelector({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DCCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _isLoadingFiliais 
        ? const Center(child: Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ))
        : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('Selecione a filial de $label'),
              isExpanded: true,
              items: _filiais.map<DropdownMenuItem<String>>((f) {
                return DropdownMenuItem<String>(
                  value: f.id ?? '',
                  child: Text(f.nome ?? ''),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
    );
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  void _handleCheckAvailability() async {
    if (_startDate == null || _endDate == null || _pickupBranchId == null || _returnBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    final provider = context.read<BookingProvider>();
    provider.setDates(_startDate!, _endDate!);
    provider.setBranches(_pickupBranchId!, _returnBranchId!);

    await provider.checkAvailability();

    if (mounted && provider.error == null) {
      context.push('/checkout');
    }
  }
}
