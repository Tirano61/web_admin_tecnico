import 'package:web_admin_tecnico/core/api/paged_result.dart';

/// Fila del listado de tecnicos (`GET /auth/tecnicos`).
class TecnicoItem {
  const TecnicoItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
    this.roles = const <String>[],
  });

  final String id;
  final String fullName;
  final String email;
  final bool isActive;
  final List<String> roles;
}

/// Detalle de un tecnico (`GET /auth/tecnicos/:id`), que ademas del listado
/// trae las fechas de alta y ultima modificacion.
class TecnicoDetalle {
  const TecnicoDetalle({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isActive,
    this.roles = const <String>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String fullName;
  final String email;
  final bool isActive;
  final List<String> roles;
  final String? createdAt;
  final String? updatedAt;
}

/// Valores del param `activos` de `GET /auth/tecnicos`: `true`, `false` o
/// `todos`. Si se omite, el backend devuelve solo los activos.
enum FiltroEstadoTecnicos {
  activos('true', 'ACTIVOS'),
  inactivos('false', 'INACTIVOS'),
  todos('todos', 'TODOS');

  const FiltroEstadoTecnicos(this.valorQuery, this.etiqueta);

  final String valorQuery;
  final String etiqueta;

  /// Si un tecnico con ese estado entra en este filtro.
  bool incluye({required bool isActive}) {
    switch (this) {
      case FiltroEstadoTecnicos.activos:
        return isActive;
      case FiltroEstadoTecnicos.inactivos:
        return !isActive;
      case FiltroEstadoTecnicos.todos:
        return true;
    }
  }
}

class TecnicosQuery {
  const TecnicosQuery({
    this.search = '',
    this.activos = FiltroEstadoTecnicos.activos,
    this.page = 1,
    this.limit = 20,
  });

  final String search;
  final FiltroEstadoTecnicos activos;
  final int page;
  final int limit;

  TecnicosQuery copyWith({
    String? search,
    FiltroEstadoTecnicos? activos,
    int? page,
    int? limit,
  }) {
    return TecnicosQuery(
      search: search ?? this.search,
      activos: activos ?? this.activos,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

/// `CreateTecnicoDto`: { email, password, fullName, isActive? }.
/// El rol `tecnico` lo asigna el backend, no se manda desde el panel.
class CreateTecnicoInput {
  const CreateTecnicoInput({
    required this.email,
    required this.password,
    required this.fullName,
    this.isActive = true,
  });

  final String email;
  final String password;
  final String fullName;
  final bool isActive;
}

/// `UpdateTecnicoDto`: { fullName?, email? }. El backend rechaza el PATCH si
/// no llega al menos uno de los dos; el panel manda siempre los dos.
class UpdateTecnicoInput {
  const UpdateTecnicoInput({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;
}

abstract class TecnicosRepository {
  Future<PagedResult<TecnicoItem>> fetchTecnicos({required TecnicosQuery query});

  Future<TecnicoDetalle> fetchTecnicoDetalle(String tecnicoId);

  Future<void> createTecnico({required CreateTecnicoInput input});

  Future<void> updateTecnico({required UpdateTecnicoInput input});

  Future<void> updateEstadoTecnico({
    required String tecnicoId,
    required bool isActive,
  });
}
