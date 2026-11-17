import 'dart:convert';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:contaktly_form/src/form_message.dart'
    show contaktlyFormMailSubject, contaktlyFormMessageMaxLength;
import 'package:cv/cv.dart';
import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/hash.dart';
import 'package:test/test.dart';

import 'example_form.dart';

void main() {
  initContaktlyFormBuilders();

  group('model', () {
    test('round trip', () {
      var published = exampleFormPublished();
      var copy = published.toMap().cv<CvContaktlyFormPublished>();
      expect(copy.toMap(), published.toMap());
      expect(copy.form.v!.texts.v!.last.title.v, 'Écrivez-nous');
      // The fields of a form are stored under `fields`.
      expect(published.form.v!.toMap()['fields'], isA<List>());
    });
    test('fields', () {
      var form = CvContaktlyForm();
      expect(form.shownFields.map((field) => field.key.v), [
        'name',
        'email',
        'subject',
        'message',
      ]);
      expect(form.fieldOf(contaktlyFormFieldName).required.v, isFalse);
      // Email and message are always shown and required.
      form.formFields.v = [
        CvContaktlyFormField()
          ..key.v = contaktlyFormFieldEmail
          ..enabled.v = false
          ..required.v = false,
        CvContaktlyFormField()
          ..key.v = contaktlyFormFieldSubject
          ..enabled.v = false,
      ];
      expect(form.fieldOf(contaktlyFormFieldEmail).required.v, isTrue);
      expect(form.shownFields.map((field) => field.key.v), [
        'name',
        'email',
        'message',
      ]);
    });
    test('languages', () {
      var form = CvContaktlyForm();
      expect(form.languagesOrDefault, ['en']);
      expect(form.languageOf('fr'), 'en');
      form
        ..languages.v = ['en', 'fr']
        ..defaultLanguage.v = 'fr';
      expect(form.languageOf('fr'), 'fr');
      expect(form.languageOf('de'), 'fr');
      expect(form.isEnabled, isTrue);
    });
  });

  group('strings', () {
    test('defaults and overrides', () {
      var form = exampleForm();
      var en = contaktlyFormStrings(form, 'en');
      expect(en.title, 'Write to us');
      expect(en.submit, 'Send');
      var fr = contaktlyFormStrings(form, 'fr');
      expect(fr.title, 'Écrivez-nous');
      expect(fr.submit, 'Envoyer');
      expect(fr.sentTextFor('a@b.c'), 'Merci. La réponse arrivera à a@b.c.');
      expect(fr.labelOf(contaktlyFormFieldSubject), 'Objet');
      // A language the form does not have: its default language.
      expect(contaktlyFormStrings(form, 'de').lang, 'en');
    });
    test('copyWith', () {
      var fr = contaktlyFormStrings(exampleForm(), 'fr');
      var custom = fr.copyWith(submit: 'Écrire', subjectChoices: ['A', 'B']);
      expect(custom.submit, 'Écrire');
      expect(custom.subjectChoices, ['A', 'B']);
      expect(custom.title, 'Écrivez-nous');
      expect(custom.lang, 'fr');
      expect(fr.submit, 'Envoyer');
    });
  });

  group('values', () {
    var form = exampleForm();
    var strings = contaktlyFormStrings(form, 'en');
    test('validate', () {
      expect(
        contaktlyFormValidate(form, const ContaktlyFormValues(), strings),
        {
          'name': 'Required',
          'email': 'A valid email is required',
          'message': 'Required',
        },
      );
      var valid = const ContaktlyFormValues(
        name: ' Ana ',
        email: 'ana@example.com',
        message: 'Hello',
      );
      expect(contaktlyFormValidate(form, valid, strings), isEmpty);
      expect(
        contaktlyFormValidate(
          form,
          ContaktlyFormValues(
            name: 'Ana',
            email: 'not an email',
            message: 'x' * (contaktlyFormMessageMaxLength + 1),
          ),
          strings,
        ),
        {
          'email': 'A valid email is required',
          'message': '10000 characters at most',
        },
      );
      // A hidden field is not validated.
      form.formFields.v = [
        CvContaktlyFormField()
          ..key.v = contaktlyFormFieldName
          ..enabled.v = false
          ..required.v = true,
      ];
      expect(
        contaktlyFormValidate(
          form,
          const ContaktlyFormValues(email: 'ana@example.com', message: 'Hi'),
          strings,
        ),
        isEmpty,
      );
    });
    test('subject choices', () {
      var form = CvContaktlyForm()
        ..texts.v = [
          CvContaktlyFormTexts()
            ..lang.v = 'en'
            ..subjectChoices.v = ['Spam', 'Other'],
        ];
      var strings = contaktlyFormStrings(form, 'en');
      expect(strings.subjectChoices, ['Spam', 'Other']);
      expect(contaktlyFormStrings(CvContaktlyForm()).subjectChoices, isEmpty);
      ContaktlyFormValues values(String? subject) => ContaktlyFormValues(
        email: 'ana@example.com',
        subject: subject,
        message: 'Hi',
      );
      expect(contaktlyFormValidate(form, values('Spam'), strings), isEmpty);
      // Not one of the choices.
      expect(contaktlyFormValidate(form, values('Ads'), strings), {
        'subject': 'Required',
      });
    });
    test('spam', () {
      var shownAt = DateTime(2026, 10, 22, 12);
      expect(
        contaktlyFormIsLikelySpam(
          const ContaktlyFormValues(honeypot: 'http://spam'),
        ),
        isTrue,
      );
      expect(
        contaktlyFormIsLikelySpam(
          ContaktlyFormValues(shownAt: shownAt),
          now: shownAt.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        contaktlyFormIsLikelySpam(
          ContaktlyFormValues(shownAt: shownAt),
          now: shownAt.add(const Duration(seconds: 20)),
        ),
        isFalse,
      );
      expect(contaktlyFormIsLikelySpam(const ContaktlyFormValues()), isFalse);
    });
    test('mail', () {
      var values = const ContaktlyFormValues(
        name: 'Ana Souza',
        email: 'ana@example.com',
        message: 'Hello\nthere',
      );
      var message = contaktlyFormMailMessage(exampleForm(), values);
      expect(message.subject.v, '[contact_example] Ana Souza');
      expect(
        message.text.v,
        'Name: Ana Souza\nEmail: ana@example.com\n\nHello\nthere',
      );
      expect(message.replyTo.v!.single.email.v, 'ana@example.com');
      expect(message.replyTo.v!.single.name.v, 'Ana Souza');
      expect(
        contaktlyFormMailSubject(
          CvContaktlyForm()..name.v = 'Site',
          const ContaktlyFormValues(subject: 'Quote'),
        ),
        'Quote',
      );
      expect(
        contaktlyFormMailSubject(
          CvContaktlyForm()..name.v = 'Site',
          const ContaktlyFormValues(),
        ),
        'Site',
      );
    });
  });

  group('send', () {
    const values = ContaktlyFormValues(
      name: 'Ana',
      email: 'ana@example.com',
      message: 'Hello',
    );
    test('signed paths', () {
      expect(contaktlySignedPaths(['a']), ['a']);
      expect(contaktlySignedPaths(['a'], formId: 'f'), ['a', 'formId']);
      expect(contaktlyIsValidFormId('demo-1_A'), isTrue);
      expect(contaktlyIsValidFormId('no/slash'), isFalse);
      expect(contaktlyIsValidFormId(''), isFalse);
    });
    test('query', () {
      var sender = ContaktlyServiceSender(published: exampleFormPublished());
      expect(sender.commandUrl, contaktlyCommandUrlDartDev);
      var query = sender.query(values, timestamp: '2026-10-22T12:00:00Z');
      var map = query.toMap();
      expect(map['formId'], 'example');
      expect(map['serviceId'], 'examplecontactv1');
      expect(map.containsKey('trial'), isFalse);
      // The signature: the service paths, then the form id.
      var paths = contaktlySignedPaths(
        contaktlyFormDefaultEncPaths,
        formId: 'example',
      );
      var hashed = paths
          .map((path) => query.valueAtPath(keyPartsFromString(path)))
          .toList();
      expect(
        aesDecrypt(query.enc.v!, exampleFormEncPassword),
        md5Hash(jsonEncode(hashed)),
      );
      sender.close();
    });
    test('prod', () {
      var sender = ContaktlyServiceSender(
        published: exampleFormPublished()..app.v = contaktlyAppProd,
      );
      expect(sender.commandUrl, contaktlyCommandUrlDartProd);
      sender.close();
    });
    test('simulated', () async {
      expect(
        contaktlyFormSimulationParse('closed'),
        ContaktlyFormSimulation.closed,
      );
      expect(contaktlyFormSimulationParse('nope'), isNull);
      expect(contaktlyFormSimulationParse(null), isNull);
      ContaktlySimulatedSender sender(ContaktlyFormSimulation simulation) =>
          ContaktlySimulatedSender(simulation, delay: Duration.zero);
      var sent = sender(ContaktlyFormSimulation.sent);
      expect((await sent.send(values)).status, 'sent');
      expect(sent.sent.single.email, 'ana@example.com');
      expect(
        (await sender(ContaktlyFormSimulation.trial).send(values)).status,
        contaktlyMailStatusTrial,
      );
      Future<ContaktlyFormSendException> refused(
        ContaktlyFormSimulation simulation,
      ) async {
        try {
          await sender(simulation).send(values);
        } on ContaktlyFormSendException catch (e) {
          return e;
        }
        fail('should fail');
      }

      var closed = await refused(ContaktlyFormSimulation.closed);
      expect(closed.isClosed, isTrue);
      expect(closed.isLimited, isFalse);
      var limited = await refused(ContaktlyFormSimulation.limited);
      expect(limited.isLimited, isTrue);
      expect(limited.isClosed, isFalse);
      var error = await refused(ContaktlyFormSimulation.error);
      expect(error.isClosed || error.isLimited, isFalse);
    });
    test('function', () async {
      var sender = ContaktlyFunctionSender(
        (values) async => ContaktlyFormSendResult(status: values.name),
      );
      expect((await sender.send(values)).status, 'Ana');
    });
  });
  group('profile', () {
    test('round trip and strings', () {
      var form = CvContaktlyForm()
        ..languages.v = ['en', 'fr']
        ..profile.v = (CvContaktlyFormProfile()
          ..name.v = 'Olivia'
          ..pictureUrl.v = 'https://example.com/o.png');
      var copy = form.toMap().cv<CvContaktlyForm>();
      expect(copy.profile.v!.name.v, 'Olivia');
      expect(copy.profile.v!.imageUrl.v, isNull);
      expect(contaktlyFormStrings(form, 'fr').closedError, contains('fermé'));
      expect(contaktlyFormStrings(form).limitedError, contains('Too many'));
    });
  });
}
