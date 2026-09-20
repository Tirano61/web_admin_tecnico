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

class TecnicosQuery {
  const TecnicosQuery({
    this.search = '',
    this.activos = true,
    this.page = 1,
    this.limit = 20,
  });

  final String search;

  /// `QueryTecnicosDto.activos` es un booleano con default `true`: el backend
  /// filtra siempre por un estado u otro, no existe un "todos" en una sola
  /// consulta.
  final bool activos;
  final int page;
  final int limit;

  TecnicosQuery copyWith({
    String? search,
    bool? activos,
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
