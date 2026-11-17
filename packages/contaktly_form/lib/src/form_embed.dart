import 'dart:convert';

import 'package:http/http.dart' as http;

import 'form_model.dart';

/// The message type a form page posts with its height to the page that
/// embeds it (any origin: nothing private).
const contaktlyFormMessageHeight = 'contaktly-form-height';

/// The message type a form page posts once a message is sent, with its
/// `formId`, to the page that embeds it.
const contaktlyFormMessageSent = 'contaktly-form-sent';

/// The attribute marking the iframe of a form in a host page: the height
/// script finds them by it.
const contaktlyFormIframeAttribute = 'data-contaktly-form';

/// The page of the published form [formId] on [formsSite], in [lang] when
/// set, in an iframe when [embed].
Uri contaktlyFormPageUrl(
  Uri formsSite,
  String formId, {
  String? lang,
  bool embed = false,
}) => formsSite.replace(
  path: '/f/$formId${lang == null ? '' : '/$lang'}',
  queryParameters: embed ? {'embed': '1'} : null,
);

/// The published form [formId] as json on [formsSite] (`form.json`).
Uri contaktlyFormJsonUrl(Uri formsSite, String formId) =>
    formsSite.replace(path: '/f/$formId/form.json');

/// The published form at [url] (a `form.json` of the forms site); a
/// [StateError] when the site answers anything else.
Future<CvContaktlyFormPublished> contaktlyFormPublishedLoad(
  Uri url, {
  http.Client? client,
}) async {
  initContaktlyFormBuilders();
  var own = client == null;
  client ??= http.Client();
  try {
    var response = await client.get(url);
    if (response.statusCode != 200) {
      throw StateError('$url: ${response.statusCode}');
    }
    return CvContaktlyFormPublished()
      ..fromMap(jsonDecode(utf8.decode(response.bodyBytes)) as Map);
  } finally {
    if (own) {
      client.close();
    }
  }
}
