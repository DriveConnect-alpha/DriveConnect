import '../../../../core/models/plano_seguro.dart';
import 'iinsurance_service.dart';

class MockInsuranceService implements IInsuranceService {
  @override
  Future<List<PlanoSeguro>> getPlanos() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      PlanoSeguro(
        id: 'BASICO',
        nome: 'Plano Básico',
        descricao: 'Cobertura básica',
        percentual: 5.0,
        obrigatorio: true,
        ativo: true,
      ),
      PlanoSeguro(
        id: 'PREMIUM',
        nome: 'Plano Premium',
        descricao: 'Cobertura total',
        percentual: 15.0,
        obrigatorio: false,
        ativo: true,
      ),
    ];
  }

  @override
  Future<void> updatePlano(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
