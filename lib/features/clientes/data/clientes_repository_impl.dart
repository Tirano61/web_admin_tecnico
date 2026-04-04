import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/clientes/domain/clientes_repository.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  ClientesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<ClienteItem>> fetchClientes({required ClientesQuery query}) async {
    dynamic payload;
    try {
      payload = await _httpClient.getJson(
        '/clientes/buscar',
        queryParameters: <String, String>{
          'q': query.search,
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      );
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }
      payload = await _httpClient.getJson(
        '/clientes/buscar',
        queryParameters: <String, String>{'q': query.search},
      );
    }

    final result = PagedResult<ClienteItem>.fromDynamic(
      payload,
      (json) => ClienteItem(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? json['razonSocial'] ?? '').toString(),
        cuit: _stringOrNull(json['cuit']),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    if (result.items.length <= query.limit) {
      return result;
    }

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pagedItems = start >= result.items.length
        ? <ClienteItem>[]
        : result.items.sublist(start, end > result.items.length ? result.items.length : end);

    return PagedResult<ClienteItem>(
      items: pagedItems,
      total: result.total,
      page: query.page,
      limit: query.limit,
    );
  }

  @override
  Future<ClienteDetalle> fetchClienteDetalle(String clienteId) async {
    final payload = await _httpClient.getJson('/clientes/$clienteId');
    final root = _asMap(payload);
    final clienteNode = _asMap(root['cliente']);
    final json = clienteNode.isNotEmpty ? clienteNode : root;

    return ClienteDetalle(
      id: _stringOrNull(json['id']) ?? clienteId,
      nombre: _stringOrNull(json['nombre'] ?? json['razonSocial']) ?? 'Sin nombre',
      cuit: _stringOrNull(json['cuit']),
      contacto: _stringOrNull(json['contacto']),
      telefono: _stringOrNull(json['telefono']),
      localidad: _stringOrNull(json['localidad']),
    );
  }

  @override
  Future<void> createCliente({required CreateClienteInput input}) async {
    final bodies = _buildPayloadCandidates(
      nombre: input.nombre,
      cuit: input.cuit,
      contacto: input.contacto,
      telefono: input.telefono,
      localidad: input.localidad,
    );

    await _sendWithFallback(
      bodies,
      (body) => _httpClient.postJson('/clientes', body: body),
    );
  }

  @override
  Future<void> updateCliente({required UpdateClienteInput input}) async {
    final bodies = _buildPayloadCandidates(
      nombre: input.nombre,
      cuit: input.cuit,
      contacto: input.contacto,
      telefono: input.telefono,
      localidad: input.localidad,
    );

    await _sendWithFallback(
      bodies,
      (body) => _httpClient.patchJson('/clientes/${input.id}', body: body),
    );
  }

  Future<void> _sendWithFallback(
    List<Map<String, dynamic>> bodies,
    Future<dynamic> Function(Map<String, dynamic> body) sender,
  ) async {
    AppFailure? lastFailure;
    for (final body in bodies) {
      try {
        await sender(body);
        return;
      } on AppFailure catch (error) {
        if (error.statusCode == 400 || error.statusCode == 422) {
          lastFailure = error;
          continue;
        }
        rethrow;
      }
    }

    throw lastFailure ?? const AppFailure('No se pudo guardar el cliente');
  }

  List<Map<String, dynamic>> _buildPayloadCandidates({
    required String nombre,
    required String cuit,
    String? contacto,
    String? telefono,
    String? localidad,
  }) {
    final cleanNombre = nombre.trim();
    final cleanCuit = cuit.trim();
    final cleanContacto = _stringOrNull(contacto);
    final cleanTelefono = _stringOrNull(telefono);
    final cleanLocalidad = _stringOrNull(localidad);

    final candidateNombre = <String, dynamic>{
      'nombre': cleanNombre,
      'cuit': cleanCuit,
      ...?_singleEntry('contacto', cleanContacto),
      ...?_singleEntry('telefono', cleanTelefono),
      ...?_singleEntry('localidad', cleanLocalidad),
    };

    final candidateRazonSocial = <String, dynamic>{
      'razonSocial': cleanNombre,
      'cuit': cleanCuit,
      ...?_singleEntry('contacto', cleanContacto),
      ...?_singleEntry('telefono', cleanTelefono),
      ...?_singleEntry('localidad', cleanLocalidad),
    };

    return <Map<String, dynamic>>[
      candidateNombre,
      candidateRazonSocial,
    ];
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

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  Map<String, dynamic>? _singleEntry(String key, String? value) {
    if (value == null) {
      return null;
    }
    return <String, dynamic>{key: value};
  }
}
