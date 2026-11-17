/// The page of a form in the browser: the browser implementation, a stub
/// on the vm (server rendering, tests).
library;

export 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart';
