import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesRepositoryImpl implements LiquidacionesRepository {
  @override
  Future<List<LiquidacionItem>> fetchLiquidaciones() async {
    return const <LiquidacionItem>[
      LiquidacionItem(
        id: 'LIQ-001',
        servicioId: 'SRV-001',
        montoUsd: 350.0,
        aprobada: false,
      ),
    ];
  }
}
