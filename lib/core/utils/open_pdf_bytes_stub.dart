Future<void> openPdfBytes(List<int> bytes) async {
  throw UnsupportedError('Visualizar PDF en memoria solo esta soportado en Flutter Web.');
}

Future<void> downloadPdfBytes(
  List<int> bytes, {
  required String fileName,
}) async {
  throw UnsupportedError('Descargar PDF en memoria solo esta soportado en Flutter Web.');
}
