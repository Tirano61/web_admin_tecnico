/// Reglas de acceso al panel de administracion tecnica.
///
/// El backend devuelve `user.roles` como array: un usuario puede tener mas de
/// un rol. Este panel solo lo operan `admin-tecnico` y `admin` (superusuario);
/// un `tecnico` usa la app de carga de servicios, no este panel.
class RolesPanel {
  const RolesPanel._();

  static const String adminTecnico = 'admin-tecnico';
  static const String admin = 'admin';
  static const String tecnico = 'tecnico';

  static const Set<String> permitidos = <String>{adminTecnico, admin};

  static const String mensajeAccesoDenegado = 'Este panel es solo para administración';

  static String normalizar(String rol) => rol.trim().toLowerCase().replaceAll('_', '-');

  static bool puedeAccederAlPanel(Iterable<String> roles) =>
      roles.map(normalizar).any(permitidos.contains);
}
