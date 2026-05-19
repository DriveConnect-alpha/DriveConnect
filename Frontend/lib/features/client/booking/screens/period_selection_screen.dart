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
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/widgets/dc_feedback_message.dart';

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
          AppFeedback.showError(msg, fallback: 'Erro ao carregar filiais.');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingProvider = context.watch<BookingProvider>();

    // Inicializa IDs locais a partir do provider se ainda não estiverem setados nesta tela
    if (_pickupBranchId == null && bookingProvider.pickupBranchId != null) {
      _pickupBranchId = bookingProvider.pickupBranchId;
    }
    if (_returnBranchId == null && bookingProvider.returnBranchId != null) {
      _returnBranchId = bookingProvider.returnBranchId;
    }

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
            
            // Retirada Travada
            Opacity(
              opacity: 0.7,
              child: _buildBranchSelector(
                label: 'Retirada (Obrigatório)',
                value: _pickupBranchId,
                onChanged: null, // Desabilitado: carro já está lá
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(
                'Nota: A retirada deve ser feita na filial atual do veículo.',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Devolução Livre
            _buildBranchSelector(
              label: 'Devolução',
              value: _returnBranchId,
              onChanged: (val) => setState(() => _returnBranchId = val),
            ),
            const SizedBox(height: 40),
            if (bookingProvider.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DCFeedbackMessage(
                  message: bookingProvider.error!,
                  type: AppFeedbackType.error,
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
    required ValueChanged<String?>? onChanged,
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
    final bookingProvider = context.read<BookingProvider>();
    
    // Mostra um loading rápido se necessário
    if (bookingProvider.selectedVehicle?.id != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      await bookingProvider.loadOccupiedDates(bookingProvider.selectedVehicle!.id!);
      if (mounted) Navigator.pop(context); // Fecha o loading
    }

    final occupied = bookingProvider.occupiedDates;

    if (!mounted) return;

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      selectableDayPredicate: (day, start, end) {
        // Bloqueia dias que já estão ocupados por outras reservas
        final dateToCheck = DateTime(day.year, day.month, day.day);
        for (final interval in occupied) {
          final occupiedStart = DateTime(interval.start.year, interval.start.month, interval.start.day);
          final occupiedEnd = DateTime(interval.end.year, interval.end.month, interval.end.day);
          
          if (dateToCheck.isAfter(occupiedStart.subtract(const Duration(seconds: 1))) && 
              dateToCheck.isBefore(occupiedEnd.add(const Duration(days: 1)))) {
            return false;
          }
        }
        return true;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF00628b),
            ),
          ),
          child: child!,
        );
      },
    );

    if (range != null) {
      // Validação de limite de 1 mês (30 dias)
      final duration = range.end.difference(range.start).inDays;
      if (duration > 30) {
        if (mounted) {
          AppFeedback.showWarning('A reserva inicial não pode ultrapassar 30 dias. Você poderá renová-la depois.');
        }
        return;
      }

      // Verificação extra se o intervalo selecionado "pula" por cima de datas bloqueadas
      // (O picker nativo às vezes permite selecionar o início antes e o fim depois de um bloco)
      bool hasOverlap = false;
      for (final interval in occupied) {
        if (range.start.isBefore(interval.end) && range.end.isAfter(interval.start)) {
          hasOverlap = true;
          break;
        }
      }

      if (hasOverlap) {
        if (mounted) {
          AppFeedback.showWarning('O período selecionado contém datas já reservadas.');
        }
        return;
      }

      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  void _handleCheckAvailability() async {
    if (_startDate == null || _endDate == null || _pickupBranchId == null || _returnBranchId == null) {
      AppFeedback.showWarning('Por favor, preencha todos os campos.');
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
