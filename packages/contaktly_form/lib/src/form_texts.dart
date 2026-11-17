import 'form_files.dart';
import 'form_model.dart';

/// The texts of a form in one language, every one set: the form's own over
/// the defaults of the language.
class ContaktlyFormStrings {
  /// The language.
  final String lang;

  /// The title above the form, empty for none.
  final String title;

  /// The line under the title, empty for none.
  final String intro;

  /// The label of the name field.
  final String nameLabel;

  /// The label of the email field.
  final String emailLabel;

  /// The label of the subject field.
  final String subjectLabel;

  /// The subjects to choose from, a free subject when empty.
  final List<String> subjectChoices;

  /// The label of the message field.
  final String messageLabel;

  /// The send button.
  final String submit;

  /// The send button while sending.
  final String sending;

  /// The title of the sent panel.
  final String sentTitle;

  /// The text of the sent panel, `{email}` to replace ([sentTextFor]).
  final String sentText;

  /// The button for another message.
  final String another;

  /// The error when the message could not be sent.
  final String error;

  /// The error when the form no longer takes messages (its service closed:
  /// expired, deleted, blocked).
  final String closedError;

  /// The error when the form took too many messages for now.
  final String limitedError;

  /// A field left empty.
  final String requiredError;

  /// An invalid email.
  final String emailError;

  /// A field too long, `{max}` to replace.
  final String tooLongError;

  /// The consent line, empty for none.
  final String consent;

  /// The privacy page of the consent line, empty for none.
  final String privacyUrl;

  /// The label of the files.
  final String filesLabel;

  /// The line under the files, `{types}` and `{size}` to replace
  /// ([filesHelpFor]).
  final String filesHelp;

  /// The button picking a file (Flutter).
  final String fileAdd;

  /// The button removing a file picked (Flutter).
  final String fileRemove;

  /// The line under the file fields shown disabled, empty for none.
  final String filesLocked;

  /// A file of a type not taken, `{name}` to replace.
  final String fileTypeError;

  /// A file too big, `{name}` and `{size}` to replace.
  final String fileTooBigError;

  /// Files too big in all, `{size}` to replace.
  final String filesTooBigError;

  /// The backend refused a file, or too many files.
  final String fileError;

  /// All the texts (the ones of the files in English by default).
  const ContaktlyFormStrings({
    required this.lang,
    required this.title,
    required this.intro,
    required this.nameLabel,
    required this.emailLabel,
    required this.subjectLabel,
    this.subjectChoices = const [],
    required this.messageLabel,
    required this.submit,
    required this.sending,
    required this.sentTitle,
    required this.sentText,
    required this.another,
    required this.error,
    required this.closedError,
    required this.limitedError,
    required this.requiredError,
    required this.emailError,
    required this.tooLongError,
    required this.consent,
    required this.privacyUrl,
    this.filesLabel = 'Files',
    this.filesHelp = '{types}, {size} at most per file',
    this.fileAdd = 'Add a file',
    this.fileRemove = 'Remove',
    this.filesLocked = '',
    this.fileTypeError = '{name}: this type of file is not taken',
    this.fileTooBigError = '{name}: {size} at most',
    this.filesTooBigError = '{size} at most in all',
    this.fileError = 'A file was refused: check its type and its size.',
  });

  /// These texts, the ones given replaced: the texts of a published form
  /// adapted to a page (`strings.copyWith(submit: 'Envoyer')`).
  ContaktlyFormStrings copyWith({
    String? title,
    String? intro,
    String? nameLabel,
    String? emailLabel,
    String? subjectLabel,
    List<String>? subjectChoices,
    String? messageLabel,
    String? submit,
    String? sending,
    String? sentTitle,
    String? sentText,
    String? another,
    String? error,
    String? closedError,
    String? limitedError,
    String? requiredError,
    String? emailError,
    String? tooLongError,
    String? consent,
    String? privacyUrl,
    String? filesLabel,
    String? filesHelp,
    String? fileAdd,
    String? fileRemove,
    String? filesLocked,
    String? fileTypeError,
    String? fileTooBigError,
    String? filesTooBigError,
    String? fileError,
  }) => ContaktlyFormStrings(
    lang: lang,
    title: title ?? this.title,
    intro: intro ?? this.intro,
    nameLabel: nameLabel ?? this.nameLabel,
    emailLabel: emailLabel ?? this.emailLabel,
    subjectLabel: subjectLabel ?? this.subjectLabel,
    subjectChoices: subjectChoices ?? this.subjectChoices,
    messageLabel: messageLabel ?? this.messageLabel,
    submit: submit ?? this.submit,
    sending: sending ?? this.sending,
    sentTitle: sentTitle ?? this.sentTitle,
    sentText: sentText ?? this.sentText,
    another: another ?? this.another,
    error: error ?? this.error,
    closedError: closedError ?? this.closedError,
    limitedError: limitedError ?? this.limitedError,
    requiredError: requiredError ?? this.requiredError,
    emailError: emailError ?? this.emailError,
    tooLongError: tooLongError ?? this.tooLongError,
    consent: consent ?? this.consent,
    privacyUrl: privacyUrl ?? this.privacyUrl,
    filesLabel: filesLabel ?? this.filesLabel,
    filesHelp: filesHelp ?? this.filesHelp,
    fileAdd: fileAdd ?? this.fileAdd,
    fileRemove: fileRemove ?? this.fileRemove,
    filesLocked: filesLocked ?? this.filesLocked,
    fileTypeError: fileTypeError ?? this.fileTypeError,
    fileTooBigError: fileTooBigError ?? this.fileTooBigError,
    filesTooBigError: filesTooBigError ?? this.filesTooBigError,
    fileError: fileError ?? this.fileError,
  );

  /// The label of the field [key].
  String labelOf(String key) => switch (key) {
    contaktlyFormFieldName => nameLabel,
    contaktlyFormFieldEmail => emailLabel,
    contaktlyFormFieldSubject => subjectLabel,
    _ => messageLabel,
  };

  /// [sentText] for [email].
  String sentTextFor(String email) => sentText.replaceAll('{email}', email);

  /// [tooLongError] for [max] characters.
  String tooLongErrorFor(int max) =>
      tooLongError.replaceAll('{max}', max.toString());

  /// [bytes] as shown: `5 MB`, `200 KB` (`Mo`, `Ko` in French).
  String sizeText(int bytes) {
    var fr = lang == 'fr';
    if (bytes < 1024) {
      return '$bytes ${fr ? 'o' : 'B'}';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).round()} ${fr ? 'Ko' : 'KB'}';
    }
    var mega = bytes / (1024 * 1024);
    var text = mega == mega.roundToDouble()
        ? mega.round().toString()
        : mega.toStringAsFixed(1);
    return '${fr ? text.replaceAll('.', ',') : text} ${fr ? 'Mo' : 'MB'}';
  }

  /// [filesHelp] for [types] (their extensions, `JPG, PDF`) and
  /// [maxFileSize].
  String filesHelpFor(Iterable<String> types, int maxFileSize) => filesHelp
      .replaceAll(
        '{types}',
        [
          for (var type in types) ?contaktlyFormFileTypes[type],
        ].join(', ').toUpperCase(),
      )
      .replaceAll('{size}', sizeText(maxFileSize));

  /// [fileTypeError] for the file [name].
  String fileTypeErrorFor(String name) =>
      fileTypeError.replaceAll('{name}', name);

  /// [fileTooBigError] for the file [name] and [maxFileSize].
  String fileTooBigErrorFor(String name, int maxFileSize) => fileTooBigError
      .replaceAll('{name}', name)
      .replaceAll('{size}', sizeText(maxFileSize));

  /// [filesTooBigError] for [maxSize] in all.
  String filesTooBigErrorFor(int maxSize) =>
      filesTooBigError.replaceAll('{size}', sizeText(maxSize));
}

/// The default texts in English.
const contaktlyFormStringsEn = ContaktlyFormStrings(
  lang: 'en',
  title: 'Contact',
  intro: '',
  nameLabel: 'Name',
  emailLabel: 'Email',
  subjectLabel: 'Subject',
  messageLabel: 'Message',
  submit: 'Send',
  sending: 'Sending…',
  sentTitle: 'Message sent',
  sentText: 'Thank you. The reply will go to {email}.',
  another: 'Write another message',
  error: 'The message could not be sent. Try again later.',
  closedError: 'This form is closed: it no longer takes messages.',
  limitedError: 'Too many messages for now. Try again in a few minutes.',
  requiredError: 'Required',
  emailError: 'A valid email is required',
  tooLongError: '{max} characters at most',
  consent: '',
  privacyUrl: '',
);

/// The default texts in French.
const contaktlyFormStringsFr = ContaktlyFormStrings(
  lang: 'fr',
  title: 'Contact',
  intro: '',
  nameLabel: 'Nom',
  emailLabel: 'E-mail',
  subjectLabel: 'Objet',
  messageLabel: 'Message',
  submit: 'Envoyer',
  sending: 'Envoi…',
  sentTitle: 'Message envoyé',
  sentText: 'Merci. La réponse arrivera à {email}.',
  another: 'Écrire un autre message',
  error: "Le message n'a pas pu être envoyé. Réessayez plus tard.",
  closedError: 'Ce formulaire est fermé : il ne prend plus de messages.',
  limitedError:
      'Trop de messages pour le moment. Réessayez dans quelques minutes.',
  requiredError: 'Obligatoire',
  emailError: 'Une adresse e-mail valide est requise',
  tooLongError: '{max} caractères au plus',
  consent: '',
  privacyUrl: '',
  filesLabel: 'Fichiers',
  filesHelp: '{types}, {size} au plus par fichier',
  fileAdd: 'Ajouter un fichier',
  fileRemove: 'Retirer',
  fileTypeError: "{name} : ce type de fichier n'est pas accepté",
  fileTooBigError: '{name} : {size} au plus',
  filesTooBigError: '{size} au plus en tout',
  fileError: 'Un fichier a été refusé : vérifiez son type et sa taille.',
);

/// The default texts of [lang], English for a language without defaults.
ContaktlyFormStrings contaktlyFormDefaultStrings(String lang) =>
    lang == 'fr' ? contaktlyFormStringsFr : contaktlyFormStringsEn;

/// The texts of [form] in [lang] (the form's default language when it does
/// not have [lang]): its own over the defaults of the language.
ContaktlyFormStrings contaktlyFormStrings(
  ContaktlyFormMixin form, [
  String? lang,
]) {
  var language = form.languageOf(lang);
  var base = contaktlyFormDefaultStrings(language);
  var own = form.storedTextsOf(language);
  String pick(String? value, String fallback) =>
      (value == null || value.isEmpty) ? fallback : value;
  return ContaktlyFormStrings(
    lang: language,
    // An empty title (not null) is none: a form under a heading of its page.
    title: own?.title.v ?? base.title,
    intro: own?.intro.v ?? base.intro,
    nameLabel: pick(own?.nameLabel.v, base.nameLabel),
    emailLabel: pick(own?.emailLabel.v, base.emailLabel),
    subjectLabel: pick(own?.subjectLabel.v, base.subjectLabel),
    subjectChoices: own?.subjectChoices.v ?? base.subjectChoices,
    messageLabel: pick(own?.messageLabel.v, base.messageLabel),
    submit: pick(own?.submit.v, base.submit),
    sending: pick(own?.sending.v, base.sending),
    sentTitle: pick(own?.sentTitle.v, base.sentTitle),
    sentText: pick(own?.sentText.v, base.sentText),
    another: pick(own?.another.v, base.another),
    error: pick(own?.error.v, base.error),
    closedError: base.closedError,
    limitedError: base.limitedError,
    requiredError: base.requiredError,
    emailError: base.emailError,
    tooLongError: base.tooLongError,
    consent: own?.consent.v ?? base.consent,
    privacyUrl: own?.privacyUrl.v ?? base.privacyUrl,
    filesLabel: pick(own?.filesLabel.v, base.filesLabel),
    filesHelp: pick(own?.filesHelp.v, base.filesHelp),
    fileAdd: base.fileAdd,
    fileRemove: base.fileRemove,
    filesLocked: base.filesLocked,
    fileTypeError: base.fileTypeError,
    fileTooBigError: base.fileTooBigError,
    filesTooBigError: base.filesTooBigError,
    fileError: base.fileError,
  );
}
