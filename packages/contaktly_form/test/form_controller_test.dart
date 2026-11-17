import 'dart:async';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:test/test.dart';

import 'example_form.dart';

void main() {
  late DateTime now;
  var shownAt = DateTime(2026, 11, 17, 12);

  setUp(() {
    now = shownAt.add(const Duration(seconds: 30));
  });

  ContaktlyFormController controller(ContaktlyFormSender sender) =>
      ContaktlyFormController(
        form: exampleForm(),
        sender: sender,
        lang: 'en',
        shownAt: shownAt,
        now: () => now,
      );

  void fill(ContaktlyFormController controller) {
    controller
      ..setValue(contaktlyFormFieldName, 'Ana')
      ..setValue(contaktlyFormFieldEmail, 'ana@example.com')
      ..setValue(contaktlyFormFieldSubject, 'A question')
      ..setValue(contaktlyFormFieldMessage, 'Hello');
  }

  test('invalid: errors, nothing sent', () async {
    var sender = ContaktlySimulatedSender(
      ContaktlyFormSimulation.sent,
      delay: Duration.zero,
    );
    var form = controller(sender);
    var changes = 0;
    form.addListener(() => changes++);
    expect(await form.submit(), isNull);
    expect(form.status, ContaktlyFormStatus.editing);
    expect(form.errors, {
      'name': 'Required',
      'email': 'A valid email is required',
      'message': 'Required',
    });
    expect(form.errorOf(contaktlyFormFieldEmail), 'A valid email is required');
    expect(changes, 1);
    expect(sender.sent, isEmpty);
  });

  test('sent, then another', () async {
    var sender = ContaktlySimulatedSender(
      ContaktlyFormSimulation.sent,
      delay: Duration.zero,
    );
    var form = controller(sender);
    var statuses = <ContaktlyFormStatus>[];
    form.addListener(() => statuses.add(form.status));
    fill(form);
    var result = await form.submit();
    expect(result!.status, 'sent');
    expect(statuses, [ContaktlyFormStatus.sending, ContaktlyFormStatus.sent]);
    expect(form.result, result);
    expect(form.sentText, 'Thank you. The reply will go to ana@example.com.');
    expect(sender.sent.single.message, 'Hello');
    expect(sender.sent.single.subject, 'A question');

    now = now.add(const Duration(minutes: 1));
    form.another();
    expect(form.status, ContaktlyFormStatus.editing);
    expect(form.valueOf(contaktlyFormFieldEmail), 'ana@example.com');
    expect(form.valueOf(contaktlyFormFieldName), 'Ana');
    expect(form.valueOf(contaktlyFormFieldMessage), '');
    expect(form.valueOf(contaktlyFormFieldSubject), '');
    expect(form.shownAt, now);
    expect(form.result, isNull);
  });

  test('a robot sees it sent', () async {
    var sender = ContaktlySimulatedSender(
      ContaktlyFormSimulation.sent,
      delay: Duration.zero,
    );
    var form = controller(sender);
    fill(form);
    form.honeypot = 'http://spam.example.com';
    expect(await form.submit(), isNull);
    expect(form.status, ContaktlyFormStatus.sent);
    expect(sender.sent, isEmpty);

    // Too fast.
    form = controller(sender);
    fill(form);
    now = shownAt.add(const Duration(seconds: 1));
    await form.submit();
    expect(form.status, ContaktlyFormStatus.sent);
    expect(sender.sent, isEmpty);

    // Unless the check is off.
    form = ContaktlyFormController(
      form: exampleForm(),
      sender: sender,
      spamCheck: false,
      now: () => now,
    );
    fill(form);
    await form.submit();
    expect(sender.sent, hasLength(1));
  });

  test('failed: closed, limited, error, then sent again', () async {
    for (var (simulation, failure) in [
      (
        ContaktlyFormSimulation.closed,
        'This form is closed: it no longer takes messages.',
      ),
      (
        ContaktlyFormSimulation.limited,
        'Too many messages for now. Try again in a few minutes.',
      ),
      (
        ContaktlyFormSimulation.error,
        'The message could not be sent. Try again later.',
      ),
    ]) {
      var form = controller(
        ContaktlySimulatedSender(simulation, delay: Duration.zero),
      );
      fill(form);
      expect(await form.submit(), isNull);
      expect(form.status, ContaktlyFormStatus.failed);
      expect(form.failure, failure);
      expect(form.error, isA<ContaktlyFormSendException>());
    }
    var fail = true;
    var form = controller(
      ContaktlyFunctionSender((values) async {
        if (fail) {
          throw StateError('offline');
        }
        return ContaktlyFormSendResult(status: 'sent');
      }),
    );
    fill(form);
    await form.submit();
    expect(form.failure, 'The message could not be sent. Try again later.');
    fail = false;
    expect((await form.submit())!.status, 'sent');
    expect(form.status, ContaktlyFormStatus.sent);
    expect(form.failure, isEmpty);
  });

  test('sending: once at a time', () async {
    var completer = Completer<ContaktlyFormSendResult>();
    var sends = 0;
    var form = controller(
      ContaktlyFunctionSender((values) {
        sends++;
        return completer.future;
      }),
    );
    fill(form);
    var first = form.submit();
    expect(form.isSending, isTrue);
    expect(await form.submit(), isNull);
    completer.complete(ContaktlyFormSendResult(status: 'stored'));
    expect((await first)!.status, 'stored');
    expect(sends, 1);
  });

  test('custom strings, disposed', () async {
    var completer = Completer<ContaktlyFormSendResult>();
    var form = ContaktlyFormController(
      form: exampleForm(),
      sender: ContaktlyFunctionSender((values) => completer.future),
      lang: 'fr',
      strings: (strings) => strings.copyWith(requiredError: 'À remplir'),
      now: () => now,
      shownAt: shownAt,
    );
    expect(await form.submit(), isNull);
    expect(form.errorOf(contaktlyFormFieldMessage), 'À remplir');
    var cleared = 0;
    form.addListener(() => cleared++);
    form.clearError(contaktlyFormFieldMessage);
    expect(form.errorOf(contaktlyFormFieldMessage), isNull);
    expect(form.errorOf(contaktlyFormFieldEmail), isNotNull);
    form.clearError(contaktlyFormFieldMessage);
    expect(cleared, 1);
    // The texts are read from the form each time.
    (form.form as CvContaktlyForm).texts.v!.last.title.v = 'Écrire';
    expect(form.strings.title, 'Écrire');
    fill(form);
    var changes = 0;
    form.addListener(() => changes++);
    var sending = form.submit();
    expect(changes, 1);
    form.dispose();
    completer.complete(ContaktlyFormSendResult(status: 'sent'));
    await sending;
    expect(changes, 1);
  });
}
