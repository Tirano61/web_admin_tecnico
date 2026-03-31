import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/clientes/domain/clientes_repository.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  ClientesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<ClienteItem>> fetchClientes({required ClientesQuery query}) async {
    final payload = await _httpClient.getJson(
      '/clientes/buscar',
      queryParameters: <String, String>{
        'q': query.search,
        'page': query.page.toString(),
        'limit': query.limit.toString(),
      },
    );

    return PagedResult<ClienteItem>.fromDynamic(
      payload,
      (json) => ClienteItem(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? json['razonSocial'] ?? '').toString(),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
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
