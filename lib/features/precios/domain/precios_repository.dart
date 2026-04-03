import 'package:web_admin_tecnico/core/api/paged_result.dart';

enum PrecioTipo {
  cotizacion,
  tarifaKm,
}

extension PrecioTipoX on PrecioTipo {
  String get label {
    switch (this) {
      case PrecioTipo.cotizacion:
        return 'Cotizacion dolar';
      case PrecioTipo.tarifaKm:
        return 'Tarifa km USD';
    }
  }
}

class PrecioItem {
  const PrecioItem({
    required this.id,
    required this.tipo,
    required this.valor,
    this.fecha,
    this.descripcion,
  });

  final String id;
  final PrecioTipo tipo;
  final double valor;
  final String? fecha;
  final String? descripcion;
}

class PreciosActuales {
  const PreciosActuales({
    this.cotizacionUsd,
    this.tarifaKmUsd,
    this.cotizacionId,
    this.tarifaKmId,
  });

  final double? cotizacionUsd;
  final double? tarifaKmUsd;
  final String? cotizacionId;
  final String? tarifaKmId;
}

class CreateCotizacionInput {
  const CreateCotizacionInput({
    required this.valorUsd,
    this.fecha,
  });

  final double valorUsd;
  final String? fecha;
}

class CreateTarifaKmInput {
  const CreateTarifaKmInput({
    required this.valorKmUsd,
    this.fecha,
  });

  final double valorKmUsd;
  final String? fecha;
}

class PreciosQuery {
  const PreciosQuery({
    this.search = '',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final int page;
  final int limit;

  PreciosQuery copyWith({String? search, int? page, int? limit}) {
    return PreciosQuery(
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

abstract class PreciosRepository {
  Future<PagedResult<PrecioItem>> fetchPrecios({required PreciosQuery query});

  Future<PreciosActuales> fetchPreciosActuales();

  Future<void> createCotizacion({required CreateCotizacionInput input});

  Future<void> createTarifaKm({required CreateTarifaKmInput input});
}
