import 'package:contaktly_form/contaktly_form.dart';

/// The enc password of the example service (32 bytes, not a real one).
const exampleFormEncPassword = 'TestFormEncPasswordNotRealSecret';

/// An example form: every field, English and French, a subject tag.
CvContaktlyForm exampleForm() {
  initContaktlyFormBuilders();
  return CvContaktlyForm()
    ..serviceId.v = 'examplecontactv1'
    ..name.v = 'Example contact form'
    ..languages.v = ['en', 'fr']
    ..formFields.v = [
      CvContaktlyFormField()
        ..key.v = contaktlyFormFieldName
        ..required.v = true,
      CvContaktlyFormField()..key.v = contaktlyFormFieldSubject,
    ]
    ..texts.v = [
      CvContaktlyFormTexts()
        ..lang.v = 'en'
        ..title.v = 'Write to us'
        ..intro.v = 'A question, an idea? We answer within a day.',
      CvContaktlyFormTexts()
        ..lang.v = 'fr'
        ..title.v = 'Écrivez-nous'
        ..intro.v = 'Une question, une idée ? Nous répondons sous un jour.',
    ]
    ..subjectTag.v = 'contact_example';
}

/// [exampleForm] as published on the dev app.
CvContaktlyFormPublished exampleFormPublished() => CvContaktlyFormPublished()
  ..formId.v = 'example'
  ..version.v = 1
  ..app.v = contaktlyAppDev
  ..encPaths.v = contaktlyFormDefaultEncPaths
  ..encPassword.v = exampleFormEncPassword
  ..form.v = exampleForm();
