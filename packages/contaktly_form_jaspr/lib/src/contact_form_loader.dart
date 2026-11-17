import 'package:contaktly_form/contaktly_form.dart';
import 'package:jaspr/server.dart';

import 'contact_form.dart';

/// A contaktly form in a page of a jaspr site, loaded from the forms site
/// (its `form.json`) when the page renders: a static site gets the version
/// published when it builds. Server only.
class ContaktlyContactFormLoader extends AsyncStatelessComponent {
  /// The `form.json` of the form (`contaktlyFormJsonUrl`).
  final Uri url;

  /// The language, the form's default when it does not have it.
  final String lang;

  /// In the form card, true by default.
  final bool card;

  /// The title of the form above it; false under a heading of the page.
  final bool showTitle;

  /// The image, the photo and the name of a user form's owner above it.
  final bool showProfile;

  /// Adapts the texts of the form (see [ContaktlyContactForm.strings]).
  final ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings;

  /// The form at [url].
  const ContaktlyContactFormLoader({
    super.key,
    required this.url,
    this.lang = 'en',
    this.card = true,
    this.showTitle = true,
    this.showProfile = true,
    this.strings,
  });

  @override
  Future<Component> build(BuildContext context) async => ContaktlyContactForm(
    published: await contaktlyFormPublishedLoad(url),
    lang: lang,
    card: card,
    showTitle: showTitle,
    showProfile: showProfile,
    strings: strings,
  );
}
