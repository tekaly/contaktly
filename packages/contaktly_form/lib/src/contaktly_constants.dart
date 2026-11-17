/// The contaktly app of the dev backend.
const contaktlyAppDev = 'contaktly_dev';

/// The contaktly app of the prod backend.
const contaktlyAppProd = 'contaktly_prod';

/// The command function of the contaktly Dart backend, dev.
final contaktlyCommandUrlDartDev = Uri.parse(
  'https://commanddartv2dev-bexrnguvca-ew.a.run.app',
);

/// The command function of the contaktly Dart backend, prod.
final contaktlyCommandUrlDartProd = Uri.parse(
  'https://commanddartv2prod-bexrnguvca-ew.a.run.app',
);

/// The command function of the Dart backend of [app].
Uri contaktlyCommandUrlDart(String app) => app == contaktlyAppProd
    ? contaktlyCommandUrlDartProd
    : contaktlyCommandUrlDartDev;

/// The signed paths of a request when its published form gives none: the
/// ones of a service created for a form.
const contaktlyFormDefaultEncPaths = [
  'timestamp',
  'serviceId',
  'message.subject',
  'message.replyTo.0.email',
  'message.text',
];

/// The request path of the form id, signed when the request has one.
const contaktlyFormIdPath = 'formId';

/// The signed paths of a request: the ones of its service, then
/// [contaktlyFormIdPath] when it carries a form id.
List<String> contaktlySignedPaths(
  List<String> servicePaths, {
  String? formId,
}) => [...servicePaths, if (formId != null) contaktlyFormIdPath];

/// True if [formId] can name a form: 1 to 64 letters, digits, `_` and `-`.
bool contaktlyIsValidFormId(String? formId) =>
    formId != null && RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(formId);
