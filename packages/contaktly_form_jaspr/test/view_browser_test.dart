/// The form view in a browser: a page rendered on the server shows the
/// form before its island is hydrated, the visitor may type in it (or the
/// browser fill it) by then.
@TestOn('browser')
library;

import 'package:contaktly_form/contaktly_form.dart';
import 'package:contaktly_form_jaspr/contaktly_form_jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

import 'example_form.dart';

/// Sets [value] in the field [key] as the page shows it, without an input
/// event: what typing before the hydration leaves.
void _fillWithoutEvent(String key, String value) {
  var element = web.document.querySelector('#cf-$key');
  (element as web.HTMLInputElement).value = value;
}

/// Submits the form as the send button does.
void _submit() {
  web.document
      .querySelector('form.cf-form')!
      .dispatchEvent(
        web.Event('submit', web.EventInit(bubbles: true, cancelable: true)),
      );
}

List<String> _fieldErrors() => [
  for (
    var i = 0;
    i < web.document.querySelectorAll('.cf-field-error').length;
    i++
  )
    web.document.querySelectorAll('.cf-field-error').item(i)!.textContent ?? '',
];

void main() {
  testClient('the values typed before the hydration are sent', (tester) async {
    // A page shown for a while: not a robot.
    while (web.window.performance.now() < 3500) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    var sender = ContaktlySimulatedSender(
      ContaktlyFormSimulation.closed,
      delay: const Duration(milliseconds: 100),
    );
    var changes = 0;
    tester.pumpComponent(
      ContaktlyContactFormView(
        form: exampleForm(),
        lang: 'en',
        sender: sender,
        onChanged: () => changes++,
      ),
    );
    await pumpEventQueue();
    _fillWithoutEvent(contaktlyFormFieldName, 'Ana Souza');
    _fillWithoutEvent(contaktlyFormFieldEmail, 'ana@example.com');
    _fillWithoutEvent(contaktlyFormFieldMessage, 'Hello');
    _submit();
    await pumpEventQueue();
    expect(_fieldErrors(), isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await pumpEventQueue();
    // Sent (the answer shown), not taken for a robot (the sent panel
    // without a send): the page showed long before the hydration.
    expect(sender.sent.single.email, 'ana@example.com');
    expect(web.document.querySelector('.cf-sent'), isNull);
    expect(
      web.document.querySelector('.cf-error')?.textContent,
      'This form is closed: it no longer takes messages.',
    );
    expect(changes, greaterThan(0));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
