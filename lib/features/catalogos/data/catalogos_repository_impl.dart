import 'package:web_admin_tecnico/features/catalogos/domain/catalogos_repository.dart';

class CatalogosRepositoryImpl implements CatalogosRepository {
  @override
  Future<List<CatalogoItem>> fetchCatalogos() async {
    return const <CatalogoItem>[
      CatalogoItem(id: 'CAT-001', nombre: 'Zona Buenos Aires', tipo: 'zona'),
      CatalogoItem(id: 'CAT-002', nombre: 'Producto ST455', tipo: 'producto'),
    ];
  }
}
