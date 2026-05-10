import '../models/filial.dart';

abstract class IFilialService {
  Future<List<Filial>> listFiliais();
}
