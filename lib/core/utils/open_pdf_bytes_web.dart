import 'dart:html' as html;

Future<void> openPdfBytes(List<int> bytes) async {
  final url = _createPdfObjectUrl(bytes);
  html.window.open(url, '_blank');
  _scheduleRevoke(url);
}

Future<void> downloadPdfBytes(
  List<int> bytes, {
  required String fileName,
}) async {
  final url = _createPdfObjectUrl(bytes);
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = fileName;

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  _scheduleRevoke(url);
}

String _createPdfObjectUrl(List<int> bytes) {
  final blob = html.Blob(<dynamic>[bytes], 'application/pdf');
  return html.Url.createObjectUrlFromBlob(blob);
}

void _scheduleRevoke(String url) {
  Future<void>.delayed(const Duration(seconds: 20)).then((_) {
    html.Url.revokeObjectUrl(url);
  });
}
