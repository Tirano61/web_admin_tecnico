import 'package:web_admin_tecnico/core/auth/auth_session.dart';
import 'package:web_admin_tecnico/core/auth/jwt_token.dart';
import 'package:web_admin_tecnico/core/auth/roles_panel.dart';

enum MotivoSesionInvalida {
  sinSesion,
  tokenIlegible,
  tokenVencido,
  rolSinAcceso,
}

extension MotivoSesionInvalidaX on MotivoSesionInvalida {
  /// Texto para mostrar en el login. `null` = arranque normal sin sesion.
  String? get mensaje {
    switch (this) {
      case MotivoSesionInvalida.sinSesion:
        return null;
      case MotivoSesionInvalida.tokenIlegible:
        return 'La sesion guardada no es valida. Inicia sesion de nuevo.';
      case MotivoSesionInvalida.tokenVencido:
        return 'Tu sesion expiro. Inicia sesion de nuevo.';
      case MotivoSesionInvalida.rolSinAcceso:
        return RolesPanel.mensajeAccesoDenegado;
    }
  }
}

class ResultadoSesionPersistida {
  const ResultadoSesionPersistida.valida(AuthSession this.session) : motivo = null;

  const ResultadoSesionPersistida.invalida(MotivoSesionInvalida this.motivo) : session = null;

  final AuthSession? session;
  final MotivoSesionInvalida? motivo;

  bool get esValida => session != null;
}

/// Revalida la sesion que quedo en el navegador antes de dejar entrar al panel.
///
/// Nada de lo guardado se toma por bueno: `localStorage` se edita a mano, asi
/// que la identidad sale del token firmado (id + roles) y solo los datos de
/// presentacion (email, nombre) se leen del usuario persistido. Un token de
/// `tecnico` no entra aunque los roles guardados digan otra cosa.
class ValidadorSesionPersistida {
  const ValidadorSesionPersistida();

  ResultadoSesionPersistida validar(AuthSession? guardada, {DateTime? ahora}) {
    if (guardada == null || guardada.token.trim().isEmpty) {
      return const ResultadoSesionPersistida.invalida(MotivoSesionInvalida.sinSesion);
    }

    final token = guardada.token.trim();
    if (!JwtToken.esLegible(token)) {
      return const ResultadoSesionPersistida.invalida(MotivoSesionInvalida.tokenIlegible);
    }

    if (JwtToken.estaVencido(token, ahora: ahora)) {
      return const ResultadoSesionPersistida.invalida(MotivoSesionInvalida.tokenVencido);
    }

    final rolesToken = JwtToken.roles(token);
    final roles = rolesToken.isNotEmpty ? rolesToken : guardada.roles;

    if (!RolesPanel.puedeAccederAlPanel(roles)) {
      return const ResultadoSesionPersistida.invalida(MotivoSesionInvalida.rolSinAcceso);
    }

    return ResultadoSesionPersistida.valida(
      guardada.copyWith(id: JwtToken.id(token) ?? guardada.id, roles: roles),
    );
  }
}
