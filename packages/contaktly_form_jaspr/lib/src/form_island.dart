/// The contact form island of a published form: pre-rendered on the
/// server, hydrated in the browser, where it validates and sends through the
/// contaktly backend.
library;

import 'package:contaktly_form/contaktly_form.dart';
import 'package:jaspr/jaspr.dart';

import 'browser.dart';
import 'form_view.dart';

/// The published form [published] in [lang], sending to the contaktly
/// backend; once sent, the form's redirect url when it has one (a page of
/// its own).
@client
class ContaktlyFormIsland extends StatefulComponent {
  /// The published form, as `CvContaktlyFormPublished.toMap()`.
  final Map<String, Object?> published;

  /// The language, the form's default when it does not have it.
  final String lang;

  /// The command function, the Dart backend of the form's app by default;
  /// relative to the page when not absolute.
  final String? commandUrl;

  /// The island.
  const ContaktlyFormIsland({
    super.key,
    required this.published,
    required this.lang,
    this.commandUrl,
  });

  @override
  State<ContaktlyFormIsland> createState() => _ContaktlyFormIslandState();
}

class _ContaktlyFormIslandState extends State<ContaktlyFormIsland> {
  late final _published = () {
    initContaktlyFormBuilders();
    return CvContaktlyFormPublished()..fromMap(component.published);
  }();

  /// In the browser only.
  ContaktlyServiceSender? _sender;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      var commandUrl = component.commandUrl;
      _sender = ContaktlyServiceSender(
        published: _published,
        // Relative to the page in the browser.
        commandUrl: commandUrl == null ? null : Uri.base.resolve(commandUrl),
      );
    }
  }

  @override
  void dispose() {
    _sender?.close();
    super.dispose();
  }

  void _sent(ContaktlyFormSendResult result) {
    var redirectUrl = _published.form.v!.redirectUrl.v;
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      contaktlyFormRedirect(redirectUrl);
    }
  }

  @override
  Component build(BuildContext context) => ContaktlyContactFormView(
    form: _published.form.v!,
    lang: component.lang,
    sender: _sender,
    onSent: _sent,
  );
}
