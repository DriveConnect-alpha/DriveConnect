import 'dart:async';
import '../models/dashboard_stats.dart';
import '../../../../calls/relatorio.call.dart';
import 'idashboard_service.dart';

class DashboardService implements IDashboardService {
  @override
  Future<DashboardStats> getStats() async {
    final completer = Completer<DashboardStats>();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    await RelatorioCall.faturamento(
      dataInicio: startOfMonth.toIso8601String().split('T')[0],
      dataFim: endOfMonth.toIso8601String().split('T')[0],
      onSuccess: (data) {
        completer.complete(DashboardStats.fromJson(data));
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
