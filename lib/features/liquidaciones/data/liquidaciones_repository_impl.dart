import 'package:web_admin_tecnico/core/api/authenticated_http_client.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesRepositoryImpl implements LiquidacionesRepository {
  LiquidacionesRepositoryImpl({AuthenticatedHttpClient? httpClient})
      : _httpClient = httpClient ?? AuthenticatedHttpClient();

  final AuthenticatedHttpClient _httpClient;

  @override
  Future<PagedResult<LiquidacionItem>> fetchLiquidaciones({
    required LiquidacionesQuery query,
  }) async {
    final payload = await _httpClient.getJson(
      '/liquidaciones',
      queryParameters: <String, String>{
        'q': query.search,
        'estado': query.estado == 'todos' ? '' : query.estado,
        'page': query.page.toString(),
        'limit': query.limit.toString(),
      },
    );

    return PagedResult<LiquidacionItem>.fromDynamic(
      payload,
      (json) => LiquidacionItem(
        id: (json['id'] ?? '').toString(),
        servicioId: (json['servicioId'] ?? json['servicio_id'] ?? '').toString(),
        montoUsd: _toDouble(json['montoUsd'] ?? json['monto_usd'] ?? json['totalUsd']),
        aprobada: _toBool(json['aprobada'] ?? json['estado']),
      ),
      fallbackPage: query.page,
      fallbackLimit: query.limit,
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
