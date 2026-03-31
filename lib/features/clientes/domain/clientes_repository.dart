import 'package:web_admin_tecnico/core/api/paged_result.dart';

class ClienteItem {
  const ClienteItem({required this.id, required this.nombre});

  final String id;
  final String nombre;
}

class ClientesQuery {
  const ClientesQuery({
    this.search = '',
    this.page = 1,
    this.limit = 6,
  });

  final String search;
  final int page;
  final int limit;

  ClientesQuery copyWith({String? search, int? page, int? limit}) {
    return ClientesQuery(
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

class CreateClienteInput {
  const CreateClienteInput({
    required this.nombre,
    required this.cuit,
    this.contacto,
    this.telefono,
    this.localidad,
  });

  final String nombre;
  final String cuit;
  final String? contacto;
  final String? telefono;
  final String? localidad;
}

abstract class ClientesRepository {
  Future<PagedResult<ClienteItem>> fetchClientes({required ClientesQuery query});

  Future<void> createCliente({required CreateClienteInput input});
}
