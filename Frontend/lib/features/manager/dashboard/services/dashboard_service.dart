import 'dart:async';
import '../models/dashboard_stats.dart';
import '../../../../calls/relatorio.call.dart';
import 'idashboard_service.dart';

class DashboardService implements IDashboardService  {
  @override
  Future<DashboardStats> getStats() async {
    final completer = Completer<DashboardStats>();

    await RelatorioCall.resumo(
      onSuccess: (data) {
        completer.complete(DashboardStats.fromJson(data));
      },
      onError: (msg) => completer.completeError(Exception(msg)),
    );

    return completer.future;
  }
}
