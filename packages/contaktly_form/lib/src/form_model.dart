import 'package:cv/cv.dart';

import 'form_files.dart';

/// The name field: optional by default.
const contaktlyFormFieldName = 'name';

/// The email field: the reply-to, always shown and required.
const contaktlyFormFieldEmail = 'email';

/// The subject field: optional, may be hidden.
const contaktlyFormFieldSubject = 'subject';

/// The message field: always shown and required.
const contaktlyFormFieldMessage = 'message';

/// The fields of a v1 form, in their order on the form.
const contaktlyFormFieldKeys = [
  contaktlyFormFieldName,
  contaktlyFormFieldEmail,
  contaktlyFormFieldSubject,
  contaktlyFormFieldMessage,
];

/// The fields always shown and required.
const _alwaysRequired = [contaktlyFormFieldEmail, contaktlyFormFieldMessage];

/// Light, dark or the one of the system.
const contaktlyFormBrightnessLight = 'light';

/// See [contaktlyFormBrightnessLight].
const contaktlyFormBrightnessDark = 'dark';

/// See [contaktlyFormBrightnessLight].
const contaktlyFormBrightnessSystem = 'system';

var _buildersInitialized = false;

/// Registers the form models, before any `cv<T>()` of them.
void initContaktlyFormBuilders() {
  if (_buildersInitialized) {
    return;
  }
  _buildersInitialized = true;
  cvAddConstructors([
    CvContaktlyForm.new,
    CvContaktlyFormField.new,
    CvContaktlyFormTexts.new,
    CvContaktlyFormLook.new,
    CvContaktlyFormProfile.new,
    CvContaktlyFormPublished.new,
    CvContaktlyFormAttachments.new,
    CvContaktlyFormSendFile.new,
  ]);
}

/// A field of a form, one of [contaktlyFormFieldKeys].
class CvContaktlyFormField extends CvModelBase {
  /// One of [contaktlyFormFieldKeys].
  final key = CvField<String>('key');

  /// Shown on the form, true by default.
  final enabled = CvField<bool>('enabled');

  /// Required, false by default.
  final required = CvField<bool>('required');

  @override
  CvFields get fields => [key, enabled, required];
}

/// The texts of a form in one language, a null one taking the default of
/// the language (see `contaktlyFormStrings`).
class CvContaktlyFormTexts extends CvModelBase {
  /// `en`, `fr`.
  final lang = CvField<String>('lang');

  /// The title above the form, empty for none (null takes the default).
  final title = CvField<String>('title');

  /// The line under the title.
  final intro = CvField<String>('intro');

  /// The label of the name field.
  final nameLabel = CvField<String>('nameLabel');

  /// The label of the email field.
  final emailLabel = CvField<String>('emailLabel');

  /// The label of the subject field.
  final subjectLabel = CvField<String>('subjectLabel');

  /// The subjects to choose from, a free subject when empty.
  final subjectChoices = CvListField<String>('subjectChoices');

  /// The label of the message field.
  final messageLabel = CvField<String>('messageLabel');

  /// The label of the files of a form taking files.
  final filesLabel = CvField<String>('filesLabel');

  /// The line under the files, `{types}` and `{size}` replaced.
  final filesHelp = CvField<String>('filesHelp');

  /// The send button.
  final submit = CvField<String>('submit');

  /// The send button while sending.
  final sending = CvField<String>('sending');

  /// The title of the panel shown once sent.
  final sentTitle = CvField<String>('sentTitle');

  /// The text of the panel shown once sent, `{email}` replaced.
  final sentText = CvField<String>('sentText');

  /// The button that empties the form for another message.
  final another = CvField<String>('another');

  /// The error shown when the message could not be sent.
  final error = CvField<String>('error');

  /// A consent line under the form, none by default.
  final consent = CvField<String>('consent');

  /// The privacy page linked from the consent line.
  final privacyUrl = CvField<String>('privacyUrl');

  @override
  CvFields get fields => [
    lang,
    title,
    intro,
    nameLabel,
    emailLabel,
    subjectLabel,
    subjectChoices,
    messageLabel,
    filesLabel,
    filesHelp,
    submit,
    sending,
    sentTitle,
    sentText,
    another,
    error,
    consent,
    privacyUrl,
  ];
}

/// The look of a form.
class CvContaktlyFormLook extends CvModelBase {
  /// A festenao theme preset name (`festenao`, `papier`...).
  final preset = CvField<String>('preset');

  /// The accent colour, `#RRGGBB`.
  final accent = CvField<String>('accent');

  /// The font family of the texts.
  final fontFamily = CvField<String>('fontFamily');

  /// The corner radius of the fields and the button, in pixels.
  final radius = CvField<int>('radius');

  /// [contaktlyFormBrightnessLight], dark or system (the default).
  final brightness = CvField<String>('brightness');

  /// Less space between the fields.
  final compact = CvField<bool>('compact');

  @override
  CvFields get fields => [
    preset,
    accent,
    fontFamily,
    radius,
    brightness,
    compact,
  ];
}

/// Who a form writes to, shown above it: the owner of a user form,
/// none for the other forms.
class CvContaktlyFormProfile extends CvModelBase {
  /// The owner's name.
  final name = CvField<String>('name');

  /// The round picture next to the name: the Google photo, or the owner's
  /// own (a plan).
  final pictureUrl = CvField<String>('pictureUrl');

  /// An image on top of the page (a plan).
  final imageUrl = CvField<String>('imageUrl');

  @override
  CvFields get fields => [name, pictureUrl, imageUrl];
}

/// The fields of a form, shared by [CvContaktlyForm] and the Firestore
/// document of the server (`app/<app>/form/<formId>`).
mixin ContaktlyFormMixin implements CvModel {
  /// The service the messages go to.
  final serviceId = CvField<String>('serviceId');

  /// The name shown in the app, and the mail subject when nothing else.
  final name = CvField<String>('name');

  /// When false the form is closed, true by default.
  final enabled = CvField<bool>('enabled');

  /// The languages of the form, `en` first by default.
  final languages = CvListField<String>('languages');

  /// The language of a page without one, the first language by default.
  final defaultLanguage = CvField<String>('defaultLanguage');

  /// The fields, the v1 defaults when missing (see `fieldOf`).
  final formFields = CvModelListField<CvContaktlyFormField>('fields');

  /// The texts per language.
  final texts = CvModelListField<CvContaktlyFormTexts>('texts');

  /// The mail subject prefix, `contact_mysite` gives `[contact_mysite] ...`.
  final subjectTag = CvField<String>('subjectTag');

  /// The look.
  final look = CvModelField<CvContaktlyFormLook>('look');

  /// Once sent, go to this url instead of showing the sent panel.
  final redirectUrl = CvField<String>('redirectUrl');

  /// The sites allowed to frame the form page, all when empty.
  final embedOrigins = CvListField<String>('embedOrigins');

  /// Who the form writes to (a user form), none by default.
  final profile = CvModelField<CvContaktlyFormProfile>('profile');

  /// The files a message may carry, none when null (the default).
  final attachments = CvModelField<CvContaktlyFormAttachments>('attachments');

  /// The fields of the mixin.
  List<CvField> get contaktlyFormFields => [
    serviceId,
    name,
    enabled,
    languages,
    defaultLanguage,
    formFields,
    texts,
    subjectTag,
    look,
    redirectUrl,
    embedOrigins,
    profile,
    attachments,
  ];
}

/// A contact form, its configuration (the draft, or what was published).
class CvContaktlyForm extends CvModelBase with ContaktlyFormMixin {
  @override
  CvFields get fields => contaktlyFormFields;
}

/// What the form page, the components and the trials use: a published form
/// and what it needs to send (the `form.json` of the forms site).
///
/// The enc password is public by construction, as in every client of a
/// public service.
class CvContaktlyFormPublished extends CvModelBase {
  /// The form id, in each request (signed).
  final formId = CvField<String>('formId');

  /// The published version, 1 for the first publish.
  final version = CvField<int>('version');

  /// `contaktly_dev` or `contaktly_prod`.
  final app = CvField<String>('app');

  /// The signed paths of the service.
  final encPaths = CvListField<String>('encPaths');

  /// The enc password of the service.
  final encPassword = CvField<String>('encPassword');

  /// The form.
  final form = CvModelField<CvContaktlyForm>('form');

  @override
  CvFields get fields => [formId, version, app, encPaths, encPassword, form];
}

/// Form helpers.
extension ContaktlyFormMixinExt on ContaktlyFormMixin {
  /// Open unless disabled.
  bool get isEnabled => enabled.v ?? true;

  /// The languages, `['en']` when none.
  List<String> get languagesOrDefault {
    var languages = this.languages.v;
    return (languages == null || languages.isEmpty) ? const ['en'] : languages;
  }

  /// The language of a page without one.
  String get defaultLanguageOrFirst {
    var language = defaultLanguage.v;
    return (language != null && languagesOrDefault.contains(language))
        ? language
        : languagesOrDefault.first;
  }

  /// [language] when the form has it, the default language otherwise.
  String languageOf(String? language) =>
      (language != null && languagesOrDefault.contains(language))
      ? language
      : defaultLanguageOrFirst;

  /// The configuration of the field [key]: the stored one over the v1
  /// default (shown; email and message required, the others optional).
  /// Email and message are always shown and required.
  CvContaktlyFormField fieldOf(String key) {
    var stored = formFields.v?.firstWhereOrNull((field) => field.key.v == key);
    var always = _alwaysRequired.contains(key);
    return CvContaktlyFormField()
      ..key.v = key
      ..enabled.v = always || (stored?.enabled.v ?? true)
      ..required.v = always || (stored?.required.v ?? false);
  }

  /// The fields shown, in their order.
  List<CvContaktlyFormField> get shownFields => contaktlyFormFieldKeys
      .map(fieldOf)
      .where((field) => field.enabled.v!)
      .toList();

  /// True when a message may carry files.
  bool get takesFiles => maxFileCount > 0;

  /// The files a message may carry, 0 for none.
  int get maxFileCount {
    var attachments = this.attachments.v;
    if (attachments == null) {
      return 0;
    }
    var max = attachments.maxFiles.v ?? 1;
    return max < 0 ? 0 : max;
  }

  /// The file fields shown, at least [maxFileCount]: the ones past it are
  /// shown disabled.
  int get shownFileCount {
    if (!takesFiles) {
      return 0;
    }
    var shown = attachments.v!.shownFiles.v ?? 0;
    return shown > maxFileCount ? shown : maxFileCount;
  }

  /// The size of a file at most in bytes.
  int get maxFileSizeOrDefault {
    var size = attachments.v?.maxFileSize.v;
    return (size == null || size <= 0 || size > contaktlyFormFileMaxSize)
        ? contaktlyFormFileMaxSize
        : size;
  }

  /// The types taken, of `contaktlyFormFileTypes`.
  List<String> get fileTypesOrDefault {
    var types = attachments.v?.types.v ?? const <String>[];
    var known = types.where(contaktlyFormFileTypes.containsKey).toList();
    return known.isEmpty ? contaktlyFormFileTypes.keys.toList() : known;
  }

  /// The stored texts of [language], null if none.
  CvContaktlyFormTexts? storedTextsOf(String language) =>
      texts.v?.firstWhereOrNull((texts) => texts.lang.v == language);
}

extension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
