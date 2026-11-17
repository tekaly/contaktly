import 'dart:convert';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'form_island.dart';
import 'form_profile.dart';
import 'form_style.dart';

/// The class scoping the css of a form in a page of another site.
const contaktlyFormRootClass = 'cf-root';

/// A contaktly form in a page of a jaspr site: its css, scoped to the form
/// (the site keeps its own font and body), and its island, hydrated by the
/// site's own client bundle. It sends to the Dart backend of the form's app.
class ContaktlyContactForm extends StatelessComponent {
  /// The published form.
  final CvContaktlyFormPublished published;

  /// The language, the form's default when it does not have it.
  final String lang;

  /// In the form card (a border, the paper background), true by default.
  final bool card;

  /// The command function, the Dart backend of the form's app by default.
  final String? commandUrl;

  /// The title of the form above it; false under a heading of the page.
  final bool showTitle;

  /// The image, the photo and the name of a user form's owner above it,
  /// true by default.
  final bool showProfile;

  /// Adapts the texts of the form (`(strings) => strings.copyWith(...)`),
  /// applied when the page renders: the title, the intro, the labels, the
  /// subject choices, the buttons, the sent panel, the error and the consent
  /// line (the refusal and validation texts stay the defaults).
  final ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings;

  /// The form of [published].
  const ContaktlyContactForm({
    super.key,
    required this.published,
    this.lang = 'en',
    this.card = true,
    this.commandUrl,
    this.showTitle = true,
    this.showProfile = true,
    this.strings,
  });

  /// [published] with the texts of [language] adapted, the titles emptied
  /// when not shown.
  CvContaktlyFormPublished _adapted(String language) {
    initContaktlyFormBuilders();
    var adapted = CvContaktlyFormPublished()..fromMap(published.toMap());
    var form = adapted.form.v!;
    var adapt = strings;
    var texts = [
      for (var lang in form.languagesOrDefault)
        form.storedTextsOf(lang) ?? (CvContaktlyFormTexts()..lang.v = lang),
    ];
    form.texts.v = texts;
    if (adapt != null) {
      var own = adapt(contaktlyFormStrings(form, language));
      var languageTexts = texts.firstWhere((texts) => texts.lang.v == language);
      languageTexts
        ..title.v = own.title
        ..intro.v = own.intro
        ..nameLabel.v = own.nameLabel
        ..emailLabel.v = own.emailLabel
        ..subjectLabel.v = own.subjectLabel
        ..subjectChoices.v = own.subjectChoices
        ..messageLabel.v = own.messageLabel
        ..submit.v = own.submit
        ..sending.v = own.sending
        ..sentTitle.v = own.sentTitle
        ..sentText.v = own.sentText
        ..another.v = own.another
        ..error.v = own.error
        ..consent.v = own.consent
        ..privacyUrl.v = own.privacyUrl;
    }
    if (!showTitle) {
      // An empty title is none.
      for (var languageTexts in texts) {
        languageTexts.title.v = '';
      }
    }
    return adapted;
  }

  @override
  Component build(BuildContext context) {
    var language = published.form.v!.languageOf(lang);
    var shown = (showTitle && strings == null) ? published : _adapted(language);
    var form = shown.form.v!;
    var look = form.look.v;
    var css = contaktlyFormCss(
      accent: look?.accent.v,
      radius: look?.radius.v,
      brightness: look?.brightness.v,
      compact: look?.compact.v ?? false,
      root: '.$contaktlyFormRootClass',
    );
    return div(classes: contaktlyFormRootClass, [
      RawText('<style>$css</style>'),
      div(classes: card ? 'cf-card' : 'cf-embed', [
        if (showProfile)
          ...contaktlyFormProfileHeader(ContaktlyFormProfile.of(form)),
        ContaktlyFormIsland(
          published:
              jsonDecode(jsonEncode(shown.toMap())) as Map<String, Object?>,
          lang: language,
          commandUrl: commandUrl,
        ),
      ]),
    ]);
  }
}
