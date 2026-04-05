import 'open_pdf_bytes_stub.dart' if (dart.library.html) 'open_pdf_bytes_web.dart' as impl;

Future<void> openPdfBytes(List<int> bytes) {
  return impl.openPdfBytes(bytes);
}

Future<void> downloadPdfBytes(
  List<int> bytes, {
  required String fileName,
}) {
  return impl.downloadPdfBytes(bytes, fileName: fileName);
}
