import 'package:web_admin_tecnico/features/clientes/domain/clientes_repository.dart';

class ClientesRepositoryImpl implements ClientesRepository {
  @override
  Future<List<ClienteItem>> fetchClientes() async {
    return const <ClienteItem>[
      ClienteItem(id: 'CLI-001', nombre: 'Agro SRL'),
    ];
  }
}
