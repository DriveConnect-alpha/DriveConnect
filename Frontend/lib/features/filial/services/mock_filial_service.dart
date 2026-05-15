import '../models/filial.dart';
import 'ifilial_service.dart';

class MockFilialService implements IFilialService {
  @override
  Future<List<Filial>> listFiliais() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Filial(id: 'f1', nome: 'Matriz São Paulo', cidade: 'São Paulo', uf: 'SP'),
      Filial(id: 'f2', nome: 'Filial Rio de Janeiro', cidade: 'Rio de Janeiro', uf: 'RJ'),
      Filial(id: 'f3', nome: 'Filial Belo Horizonte', cidade: 'Belo Horizonte', uf: 'MG'),
    ];
  }
}
