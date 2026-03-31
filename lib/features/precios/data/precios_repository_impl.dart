import 'package:web_admin_tecnico/features/precios/domain/precios_repository.dart';

class PreciosRepositoryImpl implements PreciosRepository {
  @override
  Future<List<PrecioItem>> fetchPrecios() async {
    return const <PrecioItem>[
      PrecioItem(id: 'PRC-001', descripcion: 'Cotizacion dolar', valor: 1120.50),
      PrecioItem(id: 'PRC-002', descripcion: 'Tarifa km USD', valor: 0.75),
    ];
  }
}
