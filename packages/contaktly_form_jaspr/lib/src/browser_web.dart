import 'dart:js_interop';
import 'dart:typed_data';

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

/// The files chosen in the enabled file inputs of the [form] element, in
/// their order: their name, type, size, and how to read them.
List<({String name, String type, int size, Future<Uint8List> Function() read})>
contaktlyFormPageFiles(Object? form) {
  if (form == null) {
    return const [];
  }
  var inputs = (form as web.HTMLFormElement).querySelectorAll(
    'input[type=file]',
  );
  return [
    for (var i = 0; i < inputs.length; i++)
      if (inputs.item(i) case var node?
          when !(node as web.HTMLInputElement).disabled)
        if (node.files?.item(0) case var file?)
          (
            name: file.name,
            type: file.type,
            size: file.size,
            read: () async =>
                (await file.arrayBuffer().toDart).toDart.asUint8List(),
          ),
  ];
}
