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

  @override
  Future<ServicioDetalle> fetchServicioDetalle(String servicioId) async {
    final payload = await _httpClient.getJson('/servicios/$servicioId');
    final root = _asMap(payload);
    final servicioNode = _asMap(root['servicio']);
    final clienteNode = _asMap(servicioNode['cliente']);

    final resolvedId = (root['servicioId'] ?? root['id'] ?? servicioNode['id'] ?? servicioId).toString();
    final canal = (servicioNode['canal'] ?? root['canal'] ?? 'sin_canal').toString();
    final lugarProvincia = (servicioNode['lugarProvinciaNombre'] ?? '').toString();
    final lugarDetalle = (servicioNode['lugarDetalle'] ?? '').toString();
    final lugar = [lugarProvincia, lugarDetalle]
        .where((part) => part.trim().isNotEmpty)
        .join(' - ');

    return ServicioDetalle(
      id: resolvedId,
      estadoOrden: (root['estadoOrden'] ?? root['estado_orden'] ?? servicioNode['estadoOrden'] ?? 'sin_estado')
          .toString(),
      canal: canal,
      clienteNombre: _stringOrNull(clienteNode['nombre']),
      lugar: _stringOrNull(lugar),
      equipoSerie: _stringOrNull(servicioNode['equipoNroSerie'] ?? servicioNode['equipo_nro_serie']),
      sintoma: _stringOrNull(servicioNode['sintoma']),
      diagnosticoDetalle: _stringOrNull(servicioNode['diagnosticoDetalle']),
      observaciones: _stringOrNull(servicioNode['observaciones']),
      fechaHoraServicio: _stringOrNull(root['fechaHoraServicio'] ?? servicioNode['fechaHoraServicio']),
    );
  }

  @override
  Future<ServicioDocumentoInfo> fetchDocumento(String servicioId) async {
    final payload = await _httpClient.getJson('/servicios/$servicioId/documento');
    final root = _asMap(payload);
    final documentoNode = _asMap(root['documento']);
    final rawPdfUrl = _stringOrNull(documentoNode['pdfUrl']);

    return ServicioDocumentoInfo(
      pdfHashSha256: _stringOrNull(documentoNode['pdfHashSha256']),
      pdfUrl: _normalizePdfUrl(rawPdfUrl),
      firmaClienteNombre: _stringOrNull(documentoNode['firmaClienteNombre']),
      firmaClienteDocumento: _stringOrNull(documentoNode['firmaClienteDocumento']),
      firmaFechaHora: _stringOrNull(documentoNode['firmaFechaHora']),
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

  String? _stringOrNull(dynamic value) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  String? _normalizePdfUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = rawUrl.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    final baseUri = Uri.parse(_httpClient.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
    final apiPrefix = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;

    if (trimmed.startsWith('/api/')) {
      return '$origin$trimmed';
    }
    if (trimmed.startsWith('/')) {
      return '$origin$apiPrefix$trimmed';
    }

    return '$origin$apiPrefix/$trimmed';
  }
}
