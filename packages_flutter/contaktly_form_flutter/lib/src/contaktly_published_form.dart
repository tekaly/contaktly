import 'package:contaktly_form/contaktly_form.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'contaktly_contact_form.dart';

/// The published form at [url] (its `form.json` on the forms site, loaded
/// when shown: the latest version), sending through the contaktly backend.
class ContaktlyPublishedForm extends StatefulWidget {
  /// The `form.json` of the form
  /// (`https://contact.wannahub.com/f/<formId>/form.json`).
  final Uri url;

  /// The language, the form's default when null or not one of its own.
  final String? lang;

  /// The command function, the Dart backend of the form's app by default.
  final Uri? commandUrl;

  /// Adapts the texts of the form: `(strings) => strings.copyWith(...)`.
  final ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings;

  /// Called once a message is sent, with the answer.
  final ValueChanged<ContaktlyFormSendResult>? onSent;

  /// The form's look (accent, radius, compact) over the host theme.
  final bool applyLook;

  /// The title of the form above it; false under a heading of the page.
  final bool showTitle;

  /// The image, the photo and the name of a user form's owner above it.
  final bool showProfile;

  /// Shown while the form loads, nothing by default.
  final WidgetBuilder? loadingBuilder;

  /// Shown when the form cannot be loaded, nothing by default.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// The http client (tests), a new one by default.
  final http.Client? client;

  /// The form at [url].
  const ContaktlyPublishedForm({
    super.key,
    required this.url,
    this.lang,
    this.commandUrl,
    this.strings,
    this.onSent,
    this.applyLook = true,
    this.showTitle = true,
    this.showProfile = true,
    this.loadingBuilder,
    this.errorBuilder,
    this.client,
  });

  @override
  State<ContaktlyPublishedForm> createState() => _ContaktlyPublishedFormState();
}

class _ContaktlyPublishedFormState extends State<ContaktlyPublishedForm> {
  late Future<ContaktlyServiceSender> _sender;

  @override
  void initState() {
    super.initState();
    _sender = _load();
  }

  Future<ContaktlyServiceSender> _load() async {
    var published = await contaktlyFormPublishedLoad(
      widget.url,
      client: widget.client,
    );
    return ContaktlyServiceSender(
      published: published,
      commandUrl: widget.commandUrl,
      client: widget.client,
    );
  }

  void _close() {
    _sender.then((sender) => sender.close()).ignore();
  }

  @override
  void didUpdateWidget(covariant ContaktlyPublishedForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.commandUrl != widget.commandUrl) {
      _close();
      _sender = _load();
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ContaktlyServiceSender>(
    future: _sender,
    builder: (context, snapshot) {
      var sender = snapshot.data;
      if (sender != null) {
        return ContaktlyContactForm(
          form: sender.published.form.v!,
          sender: sender,
          lang: widget.lang,
          strings: widget.strings,
          onSent: widget.onSent,
          applyLook: widget.applyLook,
          showTitle: widget.showTitle,
          showProfile: widget.showProfile,
        );
      }
      var error = snapshot.error;
      if (error != null) {
        return widget.errorBuilder?.call(context, error) ??
            const SizedBox.shrink();
      }
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    },
  );
}
