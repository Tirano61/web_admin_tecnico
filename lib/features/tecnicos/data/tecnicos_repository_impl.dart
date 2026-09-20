import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/tecnicos/domain/tecnicos_repository.dart';

class TecnicosRepositoryImpl implements TecnicosRepository {
  TecnicosRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<TecnicoItem>> fetchTecnicos({required TecnicosQuery query}) async {
    final search = query.search.trim();

    // `activos` viaja siempre explicito: si se omite, el backend asume `true`
    // y los inactivos nunca aparecerian.
    final payload = await _httpClient.getJson(
      '/auth/tecnicos',
      queryParameters: <String, String>{
        'page': query.page.toString(),
        'limit': query.limit.toString(),
        'activos': query.activos ? 'true' : 'false',
        if (search.isNotEmpty) 'q': search,
      },
    );

    return PagedResult<TecnicoItem>.fromDynamic(
      payload,
      (json) => _mapTecnicoItem(json),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );
  }

  @override
  Future<TecnicoDetalle> fetchTecnicoDetalle(String tecnicoId) async {
    final payload = await _httpClient.getJson('/auth/tecnicos/$tecnicoId');
    final json = _asMap(payload);

    return TecnicoDetalle(
      id: _stringOrNull(json['id']) ?? tecnicoId,
      fullName: _stringOrNull(json['fullName'] ?? json['full_name']) ?? 'Sin nombre',
      email: _stringOrNull(json['email']) ?? '-',
      isActive: _toBool(json['isActive'] ?? json['is_active'] ?? true),
      roles: _toStringList(json['roles']),
      createdAt: _stringOrNull(json['created_at'] ?? json['createdAt']),
      updatedAt: _stringOrNull(json['updated_at'] ?? json['updatedAt']),
    );
  }

  @override
  Future<void> createTecnico({required CreateTecnicoInput input}) async {
    await _httpClient.postJson(
      '/auth/tecnicos',
      body: <String, dynamic>{
        'email': input.email.trim(),
        'password': input.password,
        'fullName': input.fullName.trim(),
        'isActive': input.isActive,
      },
    );
  }

  @override
  Future<void> updateTecnico({required UpdateTecnicoInput input}) async {
    await _httpClient.patchJson(
      '/auth/tecnicos/${input.id}',
      body: <String, dynamic>{
        'fullName': input.fullName.trim(),
        'email': input.email.trim(),
      },
    );
  }

  @override
  Future<void> updateEstadoTecnico({
    required String tecnicoId,
    required bool isActive,
  }) async {
    await _httpClient.patchJson(
      '/auth/tecnicos/$tecnicoId/estado',
      body: <String, dynamic>{'isActive': isActive},
    );
  }

  TecnicoItem _mapTecnicoItem(Map<String, dynamic> json) {
    final root = _asMap(json);
    return TecnicoItem(
      id: _stringOrNull(root['id']) ?? '',
      fullName: _stringOrNull(root['fullName'] ?? root['full_name']) ?? 'Sin nombre',
      email: _stringOrNull(root['email']) ?? '-',
      isActive: _toBool(root['isActive'] ?? root['is_active'] ?? true),
      roles: _toStringList(root['roles']),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => (item ?? '').toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final single = _stringOrNull(value);
    return single == null ? const <String>[] : <String>[single];
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final text = (value ?? '').toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }
}
