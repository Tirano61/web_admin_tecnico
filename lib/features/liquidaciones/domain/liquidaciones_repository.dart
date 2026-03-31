class LiquidacionItem {
  const LiquidacionItem({
    required this.id,
    required this.servicioId,
    required this.montoUsd,
    required this.aprobada,
  });

  final String id;
  final String servicioId;
  final double montoUsd;
  final bool aprobada;
}

abstract class LiquidacionesRepository {
  Future<List<LiquidacionItem>> fetchLiquidaciones();
}
