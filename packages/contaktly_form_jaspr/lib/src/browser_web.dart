import 'package:web/web.dart' as web;

/// True when the page runs in an iframe.
bool get contaktlyFormInIframe => web.window.parent != web.window;

/// Goes to [url] once a message is sent, a page of its own only (in an
/// iframe, the host page decides).
void contaktlyFormRedirect(String url) {
  if (contaktlyFormInIframe) {
    return;
  }
  web.window.location.assign(url);
}
