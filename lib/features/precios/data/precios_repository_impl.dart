
import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/precios/domain/precios_repository.dart';

class PreciosRepositoryImpl implements PreciosRepository {
  PreciosRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<PrecioItem>> fetchPrecios({required PreciosQuery query}) async {
    final responses = await Future.wait<dynamic>(<Future<dynamic>>[
      _httpClient.getJson(
        '/cotizacion/historial',
        queryParameters: <String, String>{
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      ),
      _httpClient.getJson(
        '/tarifa-km/historial',
        queryParameters: <String, String>{
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      ),
    ]);

    final cotizacion = PagedResult<PrecioItem>.fromDynamic(
      responses[0],
      (json) => PrecioItem(
        id: _resolveId(json),
        tipo: PrecioTipo.cotizacion,
        valor: _toDouble(
          json['valor'] ??
              json['valorUsd'] ??
              json['cotizacion'] ??
              json['cotizacionDolar'] ??
              json['monto'],
        ),
        fecha: _stringOrNull(json['fecha'] ?? json['createdAt'] ?? json['updatedAt']),
        descripcion: _stringOrNull(json['descripcion']),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    final tarifa = PagedResult<PrecioItem>.fromDynamic(
      responses[1],
      (json) => PrecioItem(
        id: _resolveId(json),
        tipo: PrecioTipo.tarifaKm,
        valor: _toDouble(
          json['valorKmUsd'] ?? json['valor_km_usd'] ?? json['valor'] ?? json['monto'],
        ),
        fecha: _stringOrNull(json['fecha'] ?? json['createdAt'] ?? json['updatedAt']),
        descripcion: _stringOrNull(json['descripcion']),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    final merged = <PrecioItem>[...cotizacion.items, ...tarifa.items];
    final search = query.search.trim().toLowerCase();
    final filtered = merged.where((item) {
      if (search.isEmpty) {
        return true;
      }
      return item.id.toLowerCase().contains(search) ||
          item.tipo.label.toLowerCase().contains(search) ||
          (item.descripcion ?? '').toLowerCase().contains(search) ||
          (item.fecha ?? '').toLowerCase().contains(search);
    }).toList();

    final start = (query.page - 1) * query.limit;
    final end = start + query.limit;
    final pageItems = start >= filtered.length
        ? <PrecioItem>[]
        : filtered.sublist(start, end > filtered.length ? filtered.length : end);

    return PagedResult<PrecioItem>(
      items: pageItems,
      total: filtered.length,
      page: query.page,
      limit: query.limit,
    );
  }

  @override
  Future<PreciosActuales> fetchPreciosActuales() async {
    final responses = await Future.wait<dynamic>(<Future<dynamic>>[
      _httpClient.getJson('/cotizacion'),
      _httpClient.getJson('/tarifa-km'),
    ]);

    final cotizacion = _asMap(responses[0]);
    final tarifaKm = _asMap(responses[1]);

    return PreciosActuales(
      cotizacionUsd: _toDoubleOrNull(
        cotizacion['valor'] ??
            cotizacion['valorUsd'] ??
            cotizacion['cotizacion'] ??
            cotizacion['cotizacionDolar'] ??
            cotizacion['monto'],
      ),
      tarifaKmUsd: _toDoubleOrNull(
        tarifaKm['valorKmUsd'] ??
            tarifaKm['valor_km_usd'] ??
            tarifaKm['valor'] ??
            tarifaKm['monto'],
      ),
      cotizacionId: _stringOrNull(cotizacion['id']),
      tarifaKmId: _stringOrNull(tarifaKm['id']),
    );
  }

  @override
  Future<void> createCotizacion({required CreateCotizacionInput input}) async {
    // CreateCotizacionDto: { valor, fecha? } (fecha en formato ISO).
    final fecha = _stringOrNull(input.fecha);
    await _httpClient.postJson(
      '/cotizacion',
      body: <String, dynamic>{
        'valor': input.valorUsd,
        'fecha': ?fecha,
      },
    );
  }

  @override
  Future<void> createTarifaKm({required CreateTarifaKmInput input}) async {
    // CreateTarifaKmDto: { valorKmUsd, fecha? } (fecha en formato ISO).
    final fecha = _stringOrNull(input.fecha);
    await _httpClient.postJson(
      '/tarifa-km',
      body: <String, dynamic>{
        'valorKmUsd': input.valorKmUsd,
        'fecha': ?fecha,
      },
    );
  }

  String _resolveId(Map<String, dynamic> json) {
    final id = _stringOrNull(json['id']);
    if (id != null) {
      return id;
    }
    final fallback = _stringOrNull(json['fecha'] ?? json['createdAt'] ?? json['updatedAt']);
    if (fallback != null) {
      return fallback;
    }
    return 'sin-id';
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

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  double? _toDoubleOrNull(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}
