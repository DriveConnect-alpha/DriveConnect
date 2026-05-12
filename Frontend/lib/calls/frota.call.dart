import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// frota.call.dart
//
// Unified module for Fleet management, including Car Types (Categories),
// Vehicle Models, and the Vehicles themselves.
// ─────────────────────────────────────────────────────────────────────────────

class FrotaCall {
  // ───────────────────────────────────────────────────────────────────────────
  // CATEGORIAS (TIPOS DE CARRO)
  // ───────────────────────────────────────────────────────────────────────────

  /// Lista todas as categorias (tipos) de carros.
  /// ROUTE: GET /tipos-carro
  static Future<void> listarCategorias({
    required void Function(List<Map<String, dynamic>> categorias) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>('/tipos-carro');
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Registra uma nova categoria.
  /// ROUTE: POST /tipos-carro
  /// AUTH: required (ADMIN)
  static Future<void> registrarCategoria({
    required String nome,
    required double precoBaseDiaria,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/tipos-carro',
        data: {'nome': nome, 'preco_base_diaria': precoBaseDiaria},
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MODELOS
  // ───────────────────────────────────────────────────────────────────────────

  /// Lista modelos disponíveis para reserva em um período e filial.
  /// ROUTE: GET /modelos/disponiveis
  static Future<void> listarModelosDisponiveis({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? filialId,
    required void Function(List<Map<String, dynamic>> modelos) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/modelos/disponiveis',
        queryParameters: {
          'data_inicio': dataInicio.toIso8601String().split('T')[0],
          'data_fim': dataFim.toIso8601String().split('T')[0],
          if (filialId != null) 'filial_id': filialId,
        },
      );
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Lista todos os modelos cadastrados.
  /// ROUTE: GET /modelos
  static Future<void> listarModelos({
    int? tipoCarroId,
    required void Function(List<Map<String, dynamic>> modelos) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/modelos',
        queryParameters: {
          if (tipoCarroId != null) 'tipo_carro_id': tipoCarroId,
        },
      );
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Registra um novo modelo de veículo.
  /// ROUTE: POST /modelos
  static Future<void> registrarModelo({
    required String nome,
    required String marca,
    required int tipoCarroId,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.post<Map<String, dynamic>>(
        '/modelos',
        data: {
          'nome': nome,
          'marca': marca,
          'tipo_carro_id': tipoCarroId,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // VEÍCULOS (FROTA FÍSICA)
  // ───────────────────────────────────────────────────────────────────────────

  /// Registra um novo veículo físico na frota.
  /// ROUTE: POST /veiculos
  static Future<void> registrarVeiculo({
    required int modeloId,
    required String filialId,
    required String placa,
    required int ano,
    required String cor,
    required String status,
    List<dynamic>? imagens,
    int indicePrincipal = 0,
    double? precoDiaria,
    List<String>? itensIds,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'modelo_id': modeloId,
        'filial_id': filialId,
        'placa': placa,
        'ano': ano,
        'cor': cor,
        'status': status,
        'indice_principal': indicePrincipal,
        if (precoDiaria != null) 'preco_diaria': precoDiaria,
        if (itensIds != null) 'itens_ids': itensIds,
      };

      if (imagens != null && imagens.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (var img in imagens) {
          final path = (img is String) ? img : (img.path as String);
          multipartFiles.add(await MultipartFile.fromFile(path));
        }
        map['imagem'] = multipartFiles;
      }

      final response = await dioClient.post<Map<String, dynamic>>(
        '/veiculos',
        data: FormData.fromMap(map, ListFormat.multiCompatible),
      );

      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Lista veículos da frota.
  /// ROUTE: GET /veiculos
  static Future<void> listarVeiculos({
    String? filialId,
    required void Function(List<Map<String, dynamic>> veiculos) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>(
        '/veiculos',
        queryParameters: {
          if (filialId != null) 'filialId': filialId,
        },
      );
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Busca detalhes de um veículo específico.
  /// ROUTE: GET /veiculos/:id
  static Future<void> buscarVeiculo({
    required String id,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>('/veiculos/$id');
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Atualiza dados de um veículo.
  /// ROUTE: PUT /veiculos/:id
  static Future<void> atualizarVeiculo({
    required String id,
    int? modeloId,
    String? filialId,
    String? placa,
    int? ano,
    String? cor,
    String? status,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.put<Map<String, dynamic>>(
        '/veiculos/$id',
        data: {
          if (modeloId != null) 'modelo_id': modeloId,
          if (filialId != null) 'filial_id': filialId,
          if (placa != null) 'placa': placa,
          if (ano != null) 'ano': ano,
          if (cor != null) 'cor': cor,
          if (status != null) 'status': status,
        },
      );
      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Remove um veículo da frota.
  /// ROUTE: DELETE /veiculos/:id
  static Future<void> deletarVeiculo({
    required String id,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.delete<Map<String, dynamic>>('/veiculos/$id');
      onSuccess(response.data!['mensagem'] as String? ?? 'Veículo removido.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Lista itens/opcionais disponíveis para veículos.
  /// ROUTE: GET /opcionais
  static Future<void> listarOpcionais({
    required void Function(List<Map<String, dynamic>> itens) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<List<dynamic>>('/opcionais');
      final data = (response.data ?? []).cast<Map<String, dynamic>>();
      onSuccess(data);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
