import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DCStatusBadge extends StatelessWidget {
  final String status;

  const DCStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = status;

    switch (status.toUpperCase()) {
      case 'DISPONIVEL':
        color = AppTheme.statusDisponivel;
        label = 'Disponível';
        break;
      case 'ALUGADO':
      case 'ATIVA':
        color = AppTheme.statusAlugado;
        label = status == 'ATIVA' ? 'Ativa' : 'Alugado';
        break;
      case 'MANUTENCAO':
        color = AppTheme.statusManutencao;
        label = 'Manutenção';
        break;
      case 'PENDENTE':
      case 'PENDENTE_PAGAMENTO':
        color = AppTheme.statusPendente;
        label = 'Pendente';
        break;
      case 'FINALIZADA':
      case 'RESERVADA':
        color = status == 'RESERVADA' ? AppTheme.statusDisponivel : AppTheme.statusFinalizada;
        label = status == 'RESERVADA' ? 'Reservada' : 'Finalizada';
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
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
