import '../../../../core/models/reserva.dart';

abstract class IReservationManagerService {
  Future<List<Reserva>> getManagerReservations();
  Future<void> updateReservationStatus(String id, String status);
}
