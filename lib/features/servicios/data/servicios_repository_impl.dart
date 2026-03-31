import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

class ServiciosRepositoryImpl implements ServiciosRepository {
  @override
  Future<List<ServicioItem>> fetchServicios() async {
    return const <ServicioItem>[
      ServicioItem(
        id: 'SRV-001',
        descripcion: 'Servicio de campo pendiente de firma',
        estadoOrden: 'cerrada',
      ),
    ];
  }
}
