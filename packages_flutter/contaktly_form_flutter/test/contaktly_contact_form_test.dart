import 'dart:async';
import 'dart:typed_data';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:contaktly_form_flutter/contaktly_form_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'example_form.dart';

void main() {
  late List<ContaktlyFormValues> sent;
  Object? sendError;

  setUp(() {
    sent = [];
    sendError = null;
  });

  final sender = ContaktlyFunctionSender((values) async {
    var error = sendError;
    if (error != null) {
      throw error;
    }
    sent.add(values);
    return ContaktlyFormSendResult(status: 'sent', mailId: 'mail1');
  });

  Future<void> pumpApp(WidgetTester tester, Widget form, {ThemeData? theme}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: SingleChildScrollView(child: form)),
        ),
      );

  Future<void> pumpForm(
    WidgetTester tester, {
    String? lang,
    bool spamCheck = false,
    ValueChanged<ContaktlyFormSendResult>? onSent,
    ContaktlyFormMixin? form,
    ContaktlyFormSender? formSender,
    ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings,
    bool showTitle = true,
  }) => pumpApp(
    tester,
    ContaktlyContactForm(
      form: form ?? exampleForm(),
      sender: formSender ?? sender,
      lang: lang,
      onSent: onSent,
      spamCheck: spamCheck,
      strings: strings,
      showTitle: showTitle,
    ),
  );

  Future<void> fill(WidgetTester tester, String key, String text) =>
      tester.enterText(find.byKey(contaktlyContactFormFieldKey(key)), text);

  Future<void> fillValid(WidgetTester tester) async {
    await fill(tester, contaktlyFormFieldName, 'Ana Souza');
    await fill(tester, contaktlyFormFieldEmail, 'ana@example.com');
    await fill(tester, contaktlyFormFieldMessage, 'Hello');
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byKey(contaktlyContactFormSubmitKey));
    await tester.pumpAndSettle();
  }

  testWidgets('fields and texts per language', (tester) async {
    await pumpForm(tester);
    expect(find.text('Write to us'), findsOneWidget);
    expect(find.text('Name *'), findsOneWidget);
    expect(find.text('Email *'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
    expect(find.text('Message *'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    await pumpForm(tester, lang: 'fr');
    expect(find.text('Écrivez-nous'), findsOneWidget);
    expect(find.text('Nom *'), findsOneWidget);
    expect(find.text('Objet'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
  });

  testWidgets('custom texts, no title', (tester) async {
    await pumpForm(
      tester,
      showTitle: false,
      strings: (strings) => strings.copyWith(submit: 'Write'),
    );
    expect(find.text('Write to us'), findsNothing);
    expect(find.text('Write'), findsOneWidget);
  });

  testWidgets('validation, the error cleared when typing', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.byKey(contaktlyContactFormSubmitKey));
    await tester.pump();
    expect(find.text('Required'), findsNWidgets(2));
    expect(find.text('A valid email is required'), findsOneWidget);
    expect(sent, isEmpty);

    await fill(tester, contaktlyFormFieldName, 'Ana');
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    await fill(tester, contaktlyFormFieldEmail, 'not an email');
    await tester.tap(find.byKey(contaktlyContactFormSubmitKey));
    await tester.pump();
    expect(find.text('A valid email is required'), findsOneWidget);
    expect(sent, isEmpty);
  });

  testWidgets('send, sent panel, another message', (tester) async {
    ContaktlyFormSendResult? result;
    await pumpForm(tester, onSent: (value) => result = value);
    await fillValid(tester);
    await fill(tester, contaktlyFormFieldSubject, 'Quote');
    await submit(tester);
    expect(sent.single.valueOf(contaktlyFormFieldName), 'Ana Souza');
    expect(sent.single.valueOf(contaktlyFormFieldSubject), 'Quote');
    expect(result?.mailId, 'mail1');
    expect(find.text('Message sent'), findsOneWidget);
    expect(
      find.text('Thank you. The reply will go to ana@example.com.'),
      findsOneWidget,
    );

    // The name and the email are kept, the subject and the message cleared.
    await tester.tap(find.byKey(contaktlyContactFormAnotherKey));
    await tester.pumpAndSettle();
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('Quote'), findsNothing);
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('subject choices', (tester) async {
    var form = exampleForm()
      ..formFields.v = [
        CvContaktlyFormField()
          ..key.v = contaktlyFormFieldSubject
          ..required.v = true,
      ]
      ..texts.v = [
        CvContaktlyFormTexts()
          ..lang.v = 'en'
          ..subjectChoices.v = ['Quote', 'Support'],
      ];
    await pumpForm(tester, form: form);
    await fillValid(tester);
    await tester.tap(find.byKey(contaktlyContactFormSubmitKey));
    await tester.pump();
    // The subject, required, not chosen.
    expect(find.text('Required'), findsOneWidget);
    await tester.tap(find.byKey(contaktlyContactFormFieldKey('subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Support').last);
    await tester.pumpAndSettle();
    await submit(tester);
    expect(sent.single.valueOf(contaktlyFormFieldSubject), 'Support');
  });

  testWidgets('a send error keeps the message', (tester) async {
    sendError = StateError('backend down');
    await pumpForm(tester);
    await fillValid(tester);
    await submit(tester);
    expect(
      find.text('The message could not be sent. Try again later.'),
      findsOneWidget,
    );
    expect(find.text('Hello'), findsOneWidget);

    sendError = null;
    await submit(tester);
    expect(sent, hasLength(1));
    expect(find.text('Message sent'), findsOneWidget);
  });

  testWidgets('closed by the server, limited simulated', (tester) async {
    sendError = ContaktlyFormSendException(
      code: contaktlyFormErrorCodeClosed,
      message: contaktlyFormErrorClosed,
    );
    await pumpForm(tester, lang: 'fr');
    await fill(tester, contaktlyFormFieldName, 'Ana Souza');
    await fill(tester, contaktlyFormFieldEmail, 'ana@example.com');
    await fill(tester, contaktlyFormFieldMessage, 'Bonjour');
    await submit(tester);
    expect(find.textContaining('Ce formulaire est fermé'), findsOneWidget);

    var simulated = ContaktlySimulatedSender(ContaktlyFormSimulation.limited);
    await pumpForm(tester, formSender: simulated);
    await fillValid(tester);
    await tester.tap(find.byKey(contaktlyContactFormSubmitKey));
    await tester.pump();
    expect(find.text('Sending…'), findsOneWidget);
    await tester.pump(contaktlyFormSimulationDelay);
    await tester.pumpAndSettle();
    expect(find.textContaining('Too many messages for now'), findsOneWidget);
    expect(simulated.sent, hasLength(1));
  });

  testWidgets('the profile of a user form', (tester) async {
    var form = exampleForm()
      ..profile.v = (CvContaktlyFormProfile()
        ..name.v = 'Olivia Owner'
        ..pictureUrl.v = 'https://example.com/olivia.png');
    await pumpForm(tester, form: form);
    // The network image fails in tests: its placeholder.
    await tester.pumpAndSettle();
    expect(find.byKey(contaktlyContactFormProfileKey), findsOneWidget);
    expect(find.text('Olivia Owner'), findsOneWidget);
    await pumpForm(tester);
    expect(find.byKey(contaktlyContactFormProfileKey), findsNothing);
  });

  testWidgets('a robot (too fast) sees it sent, nothing is sent', (
    tester,
  ) async {
    await pumpForm(tester, spamCheck: true);
    await fillValid(tester);
    await submit(tester);
    expect(find.text('Message sent'), findsOneWidget);
    expect(sent, isEmpty);
  });

  testWidgets('a controller of its own', (tester) async {
    var completer = Completer<ContaktlyFormSendResult>();
    var controller = ContaktlyFormController(
      form: exampleForm(),
      sender: ContaktlyFunctionSender((values) => completer.future),
      spamCheck: false,
    );
    addTearDown(controller.dispose);
    await pumpApp(tester, ContaktlyContactForm.controller(controller));
    String fieldText(String key) => tester
        .widget<TextField>(find.byKey(contaktlyContactFormFieldKey(key)))
        .controller!
        .text;

    // Filled by its owner, sent from there.
    controller
      ..setValue(contaktlyFormFieldName, 'Ana')
      ..setValue(contaktlyFormFieldEmail, 'ana@example.com')
      ..setValue(contaktlyFormFieldMessage, 'Hi');
    unawaited(controller.submit());
    await tester.pump();
    expect(fieldText(contaktlyFormFieldName), 'Ana');
    expect(find.text('Sending…'), findsOneWidget);
    completer.complete(ContaktlyFormSendResult(status: 'stored'));
    await tester.pumpAndSettle();
    expect(controller.status, ContaktlyFormStatus.sent);
    expect(find.text('Message sent'), findsOneWidget);

    // Typed in the widget: in the controller.
    await tester.tap(find.byKey(contaktlyContactFormAnotherKey));
    await tester.pumpAndSettle();
    await fill(tester, contaktlyFormFieldMessage, 'Again');
    expect(controller.valueOf(contaktlyFormFieldMessage), 'Again');
  });

  testWidgets('the look over a theme with explicit colours', (tester) async {
    var form = exampleForm()
      ..look.v = (CvContaktlyFormLook()
        ..accent.v = '#00897b'
        ..radius.v = 4);
    await pumpApp(
      tester,
      ContaktlyContactForm(form: form, sender: sender),
      theme: ThemeData(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
        ),
      ),
    );
    var button = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(contaktlyContactFormSubmitKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(button.color, const Color(0xFF00897B));
    var decoration = Theme.of(
      tester.element(find.byKey(contaktlyContactFormSubmitKey)),
    ).inputDecorationTheme;
    expect(
      (decoration.enabledBorder as OutlineInputBorder).borderRadius,
      BorderRadius.circular(4),
    );
  });

  testWidgets('files: picked, checked, removed, sent', (tester) async {
    // The whole form on screen.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var form = exampleForm()
      ..attachments.v = (CvContaktlyFormAttachments()
        ..maxFiles.v = 2
        ..shownFiles.v = 3);
    var picks = <ContaktlyFormFile?>[];
    List<String>? pickedTypes;
    Future<void> pump({ContaktlyFormFilePicker? filePicker}) => pumpApp(
      tester,
      ContaktlyContactForm(
        form: form,
        sender: sender,
        spamCheck: false,
        filePicker: filePicker,
      ),
    );
    // Without a picker: no files.
    await pump();
    expect(find.text('Files'), findsNothing);
    await pump(
      filePicker: (types) async {
        pickedTypes = types;
        return picks.removeAt(0);
      },
    );
    expect(find.text('Files'), findsOneWidget);
    expect(
      find.text(
        'JPG, PNG, WEBP, GIF, PDF, DOCX, XLSX, PPTX, ODT, ODS, ODP, '
        '5 MB at most per file',
      ),
      findsOneWidget,
    );
    // One to add, one shown disabled.
    expect(find.text('Add a file'), findsNWidgets(2));
    var zip = ContaktlyFormFile(
      name: 'a.zip',
      bytes: Uint8List.fromList([0x50, 0x4b, 0x03, 0x04]),
    );
    var pdf = ContaktlyFormFile(
      name: 'cv.pdf',
      bytes: Uint8List.fromList('%PDF-1.7 a cv'.codeUnits),
    );
    picks.addAll([null, zip, pdf]);
    // Cancelled.
    await tester.tap(find.byKey(contaktlyContactFormFileAddKey));
    await tester.pumpAndSettle();
    expect(pickedTypes, contaktlyFormFileTypes.keys.toList());
    expect(find.textContaining('a.zip'), findsNothing);
    await tester.tap(find.byKey(contaktlyContactFormFileAddKey));
    await tester.pumpAndSettle();
    expect(find.text('a.zip (4 B)'), findsOneWidget);
    await fillValid(tester);
    await submit(tester);
    expect(sent, isEmpty);
    expect(find.text('a.zip: this type of file is not taken'), findsOneWidget);
    await tester.tap(find.byKey(contaktlyContactFormFileRemoveKey(0)));
    await tester.pumpAndSettle();
    expect(find.text('a.zip: this type of file is not taken'), findsNothing);
    await tester.tap(find.byKey(contaktlyContactFormFileAddKey));
    await tester.pumpAndSettle();
    expect(find.text('cv.pdf (13 B)'), findsOneWidget);
    await submit(tester);
    expect(sent.single.files, [pdf]);
    // Another message: no files.
    await tester.tap(find.byKey(contaktlyContactFormAnotherKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('cv.pdf'), findsNothing);
  });
}
