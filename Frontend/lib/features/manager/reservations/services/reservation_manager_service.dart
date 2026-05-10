import '../../../../core/network/api_client.dart';
import '../../../../core/models/reserva.dart';
import 'ireservation_manager_service.dart';

class ReservationManagerService implements IReservationManagerService {
  final ApiClient _apiClient;

  ReservationManagerService(this._apiClient);

  @override
  Future<List<Reserva>> getManagerReservations() async {
    final response = await _apiClient.get('/reservas/gerente');
    return (response.data as List).map((r) => Reserva.fromJson(r)).toList();
  }

  @override
  Future<void> updateReservationStatus(String id, String status) async {
    await _apiClient.patch('/reservas/$id/status', data: {'status': status});
  }
}
