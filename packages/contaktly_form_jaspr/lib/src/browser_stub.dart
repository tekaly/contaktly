import 'dart:typed_data';

/// True when the page runs in an iframe (never on the vm).
bool get contaktlyFormInIframe => false;

/// Goes to [url] once a message is sent (nothing on the vm).
void contaktlyFormRedirect(String url) {}

/// The files chosen in the enabled file inputs of the [form] element, in
/// their order: their name, type, size, and how to read them (none on the
/// vm).
List<({String name, String type, int size, Future<Uint8List> Function() read})>
contaktlyFormPageFiles(Object? form) => const [];
