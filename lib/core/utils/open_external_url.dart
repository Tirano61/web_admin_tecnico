import 'open_external_url_stub.dart' if (dart.library.html) 'open_external_url_web.dart' as impl;

Future<void> openExternalUrl(String url) {
  return impl.openExternalUrl(url);
}
