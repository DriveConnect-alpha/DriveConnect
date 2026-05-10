import '../../../../core/models/plano_seguro.dart';

abstract class IInsuranceService {
  Future<List<PlanoSeguro>> getPlanos();
  Future<void> updatePlano(String id, Map<String, dynamic> data);
}
