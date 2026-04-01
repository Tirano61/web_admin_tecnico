import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

class ServiciosRepositoryImpl implements ServiciosRepository {
  ServiciosRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<ServicioItem>> fetchServicios({required ServiciosQuery query}) async {
    dynamic payload;
    try {
      payload = await _httpClient.getJson(
        '/servicios',
        queryParameters: <String, String>{
          'q': query.search,
          'estadoOrden': query.estado == 'todos' ? '' : query.estado,
          'canal': query.canal == 'todos' ? '' : query.canal,
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      );
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }
      payload = await _httpClient.getJson(
        '/servicios',
        queryParameters: <String, String>{
          'q': query.search,
          'estadoOrden': query.estado == 'todos' ? '' : query.estado,
          'canal': query.canal == 'todos' ? '' : query.canal,
        },
      );
    }

    final result = PagedResult<ServicioItem>.fromDynamic(
      payload,
      (json) {
        final servicioNode = _asMap(json['servicio']);
        return ServicioItem(
          id: _resolveId(json, servicioNode),
          descripcion: _resolveDescripcion(json, servicioNode),
          estadoOrden:
              (json['estadoOrden'] ?? json['estado_orden'] ?? servicioNode['estadoOrden'] ?? 'sin_estado')
                  .toString(),
        );
      },
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    if (result.items.length <= query.limit) {
      return result;
    }

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pagedItems = start >= result.items.length
        ? <ServicioItem>[]
        : result.items.sublist(start, end > result.items.length ? result.items.length : end);

    return PagedResult<ServicioItem>(
      items: pagedItems,
      total: result.total,
      page: query.page,
      limit: query.limit,
    );
  }

  String _resolveId(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final value = root['id'] ?? root['servicioId'] ?? servicioNode['id'] ?? servicioNode['servicioId'];
    return (value ?? '').toString();
  }

  String _resolveDescripcion(Map<String, dynamic> root, Map<String, dynamic> servicioNode) {
    final json = servicioNode.isEmpty ? root : servicioNode;
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

    final fallbackId = _resolveId(root, servicioNode);
    return fallbackId.isEmpty ? 'Servicio sin descripcion' : 'Servicio $fallbackId';
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
}
