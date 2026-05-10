import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DCStatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const DCStatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    String displayLabel = label ?? status;

    switch (status.toUpperCase()) {
      case 'DISPONIVEL':
        color = AppTheme.statusDisponivel;
        if (label == null) displayLabel = 'Disponível';
        break;
      case 'ALUGADO':
      case 'ATIVA':
        color = AppTheme.statusAlugado;
        if (label == null) displayLabel = status == 'ATIVA' ? 'Ativa' : 'Alugado';
        break;
      case 'MANUTENCAO':
        color = AppTheme.statusManutencao;
        if (label == null) displayLabel = 'Manutenção';
        break;
      case 'PENDENTE':
      case 'PENDENTE_PAGAMENTO':
        color = AppTheme.statusPendente;
        if (label == null) displayLabel = 'Pendente';
        break;
      case 'FINALIZADA':
      case 'RESERVADA':
        color = status == 'RESERVADA' ? AppTheme.statusDisponivel : AppTheme.statusFinalizada;
        if (label == null) displayLabel = status == 'RESERVADA' ? 'Reservada' : 'Finalizada';
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
