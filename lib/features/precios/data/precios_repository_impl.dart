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
        id: (json['id'] ?? '').toString(),
        descripcion: 'Cotizacion dolar',
        valor: _toDouble(json['valor'] ?? json['cotizacion'] ?? json['monto']),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
    );

    final tarifa = PagedResult<PrecioItem>.fromDynamic(
      responses[1],
      (json) => PrecioItem(
        id: (json['id'] ?? '').toString(),
        descripcion: 'Tarifa km USD',
        valor: _toDouble(json['valorKmUsd'] ?? json['valor'] ?? json['monto']),
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
          item.descripcion.toLowerCase().contains(search);
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

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
