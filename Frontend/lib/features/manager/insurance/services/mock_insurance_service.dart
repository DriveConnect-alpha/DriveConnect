import '../../../../core/models/plano_seguro.dart';
import 'iinsurance_service.dart';

class MockInsuranceService implements IInsuranceService {
  @override
  Future<List<PlanoSeguro>> getPlanos() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      PlanoSeguro(id: 'BASICO', nome: 'Plano Básico', descricao: 'Cobertura básica', precoDiaria: 50.0),
      PlanoSeguro(id: 'PREMIUM', nome: 'Plano Premium', descricao: 'Cobertura total', precoDiaria: 120.0),
    ];
  }

  @override
  Future<void> updatePlano(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
