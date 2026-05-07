import 'package:dio/dio.dart';
import 'api_core.dart';

// ─────────────────────────────────────────────────────────────────────────────
// veiculo.call.dart
//
// Centralizes all vehicle management HTTP calls to the DriveConnect backend.
// Handles fleet registration, listing, and updates, including image uploads.
// Uses the callback pattern: onSuccess and onError. No exceptions thrown to UI.
// ─────────────────────────────────────────────────────────────────────────────

class VeiculoCall {
  /// Registra um novo veículo na frota.
  /// ROUTE: POST /veiculos
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE (Multipart/Form-Data):
  /// ```dart
  /// await VeiculoCall.registrarVeiculo(
  ///   modeloId: 1,
  ///   filialId: 'uuid-filial',
  ///   placa: 'ABC-1234',
  ///   ano: 2024,
  ///   cor: 'Branco',
  ///   status: 'DISPONIVEL',
  ///   imagePath: '/path/to/car.jpg', // Opcional
  ///   onSuccess: (data) => print('Veículo registrado com ID: ${data['id']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  /// Registra um novo veículo na frota com até 10 imagens.
  /// O parâmetro [imagens] pode receber uma lista de caminhos (String) ou objetos XFile/File.
  static Future<void> registrarVeiculo({
    required int modeloId,
    required String filialId,
    required String placa,
    required int ano,
    required String cor,
    required String status,
    List<dynamic>? imagens, // Suporta List<String>, List<XFile>, etc.
    int indicePrincipal = 0,
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
      };

      if (imagens != null && imagens.isNotEmpty) {
        final List<MultipartFile> multipartFiles = [];
        for (var img in imagens) {
          if (img is String) {
            multipartFiles.add(await MultipartFile.fromFile(img));
          } else {
            // Se for XFile (do pacote image_picker), acessamos o path
            // Para Web, o dio trata MultipartFile.fromBytes
            multipartFiles.add(await MultipartFile.fromFile(img.path));
          }
        }
        map['imagem'] = multipartFiles;
      }

      final formData = FormData.fromMap(map, ListFormat.multiCompatible);

      final response = await dioClient.post<Map<String, dynamic>>(
        '/veiculos',
        data: formData,
      );

      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Lista veículos da frota, opcionalmente filtrados por filial.
  /// ROUTE: GET /veiculos?filialId=...
  /// AUTH: required (pode ser aberto dependendo da configuração do backend)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await VeiculoCall.listar(
  ///   filialId: 'uuid-filial', // Opcional
  ///   onSuccess: (veiculos) => print('Veículos encontrados: ${veiculos.length}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> listar({
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

  /// Busca detalhes de um veículo específico por ID.
  /// ROUTE: GET /veiculos/:id
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await VeiculoCall.buscar(
  ///   id: 'uuid-veiculo',
  ///   onSuccess: (veiculo) => print('Placa: ${veiculo['placa']}'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> buscar({
    required String id,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.get<Map<String, dynamic>>(
        '/veiculos/$id',
      );

      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Atualiza dados de um veículo existente.
  /// ROUTE: PUT /veiculos/:id
  /// AUTH: required (Gerente, Admin)
  ///
  /// USAGE EXAMPLE:
  /// ```dart
  /// await VeiculoCall.atualizar(
  ///   id: 'uuid-veiculo',
  ///   status: 'MANUTENCAO',
  ///   onSuccess: (data) => print('Atualizado!'),
  ///   onError: (msg) => print(msg),
  /// );
  /// ```
  static Future<void> atualizar({
    required String id,
    int? modeloId,
    String? filialId,
    String? placa,
    int? ano,
    String? cor,
    String? status,
    List<String>? imagePaths,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final Map<String, dynamic> map = {
        if (modeloId != null) 'modelo_id': modeloId,
        if (filialId != null) 'filial_id': filialId,
        if (placa != null) 'placa': placa,
        if (ano != null) 'ano': ano,
        if (cor != null) 'cor': cor,
        if (status != null) 'status': status,
      };

      if (imagePaths != null && imagePaths.isNotEmpty) {
        final List<MultipartFile> files = [];
        for (final path in imagePaths) {
          files.add(await MultipartFile.fromFile(path));
        }
        map['imagem'] = files;
      }

      final response = await dioClient.put<Map<String, dynamic>>(
        '/veiculos/$id',
        data: FormData.fromMap(map, ListFormat.multiCompatible),
      );

      onSuccess(response.data!);
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Adiciona uma imagem adicional ao veículo.
  /// ROUTE: POST /veiculos/:id/imagens
  static Future<void> adicionarImagem({
    required String id,
    required String imagePath,
    bool isPrincipal = false,
    required void Function(Map<String, dynamic> data) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final formData = FormData.fromMap({
        'imagem': await MultipartFile.fromFile(imagePath),
        'is_principal': isPrincipal.toString(),
      });

      final response = await dioClient.post<Map<String, dynamic>>(
        '/veiculos/$id/imagens',
        data: formData,
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
  static Future<void> deletar({
    required String id,
    required void Function(String mensagem) onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final response = await dioClient.delete<Map<String, dynamic>>(
        '/veiculos/$id',
      );

      onSuccess(response.data!['mensagem'] as String? ?? 'Veículo removido com sucesso.');
    } on DioException catch (e) {
      handleApiError(e, onError);
    } catch (e) {
      onError(e.toString());
    }
  }
}
