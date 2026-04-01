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
  Future<void> createCliente({required CreateClienteInput input}) async {
    await _httpClient.postJson(
      '/clientes',
      body: <String, dynamic>{
        'nombre': input.nombre.trim(),
        'cuit': input.cuit.trim(),
        'contacto': input.contacto?.trim(),
        'telefono': input.telefono?.trim(),
        'localidad': input.localidad?.trim(),
      },
    );
  }
}
