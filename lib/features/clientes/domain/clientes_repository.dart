class ClienteItem {
  const ClienteItem({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

abstract class ClientesRepository {
  Future<List<ClienteItem>> fetchClientes();
}
