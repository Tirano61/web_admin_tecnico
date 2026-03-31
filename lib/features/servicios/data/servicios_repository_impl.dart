import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

class ServiciosRepositoryImpl implements ServiciosRepository {
  ServiciosRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<ServicioItem>> fetchServicios({required ServiciosQuery query}) async {
    final payload = await _httpClient.getJson(
      '/servicios',
      queryParameters: <String, String>{
        'q': query.search,
        'estadoOrden': query.estado == 'todos' ? '' : query.estado,
        'page': query.page.toString(),
        'limit': query.limit.toString(),
      },
    );

    return PagedResult<ServicioItem>.fromDynamic(
      payload,
      (json) => ServicioItem(
        id: (json['id'] ?? json['servicioId'] ?? '').toString(),
        descripcion: _resolveDescripcion(json),
        estadoOrden: (json['estadoOrden'] ?? json['estado_orden'] ?? 'sin_estado').toString(),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );
  }

  String _resolveDescripcion(Map<String, dynamic> json) {
    final cliente = json['cliente'];
    final clienteNombre = cliente is Map<String, dynamic> ? cliente['nombre']?.toString() : null;
    final sintoma = json['sintoma']?.toString();
    final serie = json['equipoNroSerie']?.toString() ?? json['equipo_nro_serie']?.toString();

    if (clienteNombre != null && clienteNombre.isNotEmpty) {
      return sintoma != null && sintoma.isNotEmpty
          ? '$clienteNombre - $sintoma'
          : clienteNombre;
    }
    if (sintoma != null && sintoma.isNotEmpty) {
      return sintoma;
    }
    if (serie != null && serie.isNotEmpty) {
      return 'Equipo serie $serie';
    }

    final fallbackId = (json['id'] ?? json['servicioId'] ?? '').toString();
    return fallbackId.isEmpty ? 'Servicio sin descripcion' : 'Servicio $fallbackId';
  }
}
