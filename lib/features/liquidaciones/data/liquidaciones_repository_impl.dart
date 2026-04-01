import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesRepositoryImpl implements LiquidacionesRepository {
  LiquidacionesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    dynamic payload;
    try {
      payload = await _httpClient.getJson(
        '/liquidaciones',
        queryParameters: <String, String>{
          'q': query.search,
          'estado': query.estado == 'todos' ? '' : query.estado,
          'page': query.page.toString(),
          'limit': query.limit.toString(),
        },
      );
    } on AppFailure catch (error) {
      if (error.statusCode != 400) {
        rethrow;
      }
      payload = await _httpClient.getJson(
        '/liquidaciones',
        queryParameters: <String, String>{
          'q': query.search,
          'estado': query.estado == 'todos' ? '' : query.estado,
        },
      );
    }

    final result = PagedResult<LiquidacionItem>.fromDynamic(
      payload,
      (json) {
        final servicioNode = _asMap(json['servicio']);
        return LiquidacionItem(
          id: (json['id'] ?? json['liquidacionId'] ?? '').toString(),
          servicioId: (json['servicioId'] ?? json['servicio_id'] ?? servicioNode['id'] ?? '').toString(),
          montoUsd: _toDouble(
            json['montoUsd'] ?? json['monto_usd'] ?? json['totalUsd'] ?? json['total_usd'],
          ),
          aprobada: _toBool(json['aprobada'] ?? json['estado']),
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
        ? <LiquidacionItem>[]
        : result.items.sublist(start, end > result.items.length ? result.items.length : end);

    return PagedResult<LiquidacionItem>(
      items: pagedItems,
      total: result.total,
      page: query.page,
      limit: query.limit,
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

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'aprobada' || normalized == 'true' || normalized == 'approved';
    }
    return false;
  }
}
