import 'dart:convert';

/// JWT sin firmar con el mismo payload que emite el backend: `{ id, roles }`
/// y, cuando corresponde, `exp`.
String jwtDePrueba({
  required List<String> roles,
  String id = 'u-1',
  DateTime? exp,
}) {
  String segmento(Map<String, dynamic> datos) =>
      base64Url.encode(utf8.encode(jsonEncode(datos))).replaceAll('=', '');

  final payload = <String, dynamic>{'id': id, 'roles': roles};
  if (exp != null) {
    payload['exp'] = exp.toUtc().millisecondsSinceEpoch ~/ 1000;
  }

  return '${segmento(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'})}'
      '.${segmento(payload)}'
      '.firma';
}
