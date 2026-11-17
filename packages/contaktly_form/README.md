# contaktly_form

Contact forms in pure Dart (no `dart:io`: the VM, Flutter, the web):

- the model of a published form (`CvContaktlyFormPublished`, its fields, texts
  and look), loaded from its `form.json` (`contaktlyFormPublishedLoad`);
- its texts in English and French, the form's own over the defaults
  (`contaktlyFormStrings`, `copyWith` to adapt them);
- validation and a robot check (honeypot, fill time);
- `ContaktlyFormController`: the state of a form for any UI (values, errors,
  sending, sent, failed);
- the senders of a message, behind `ContaktlyFormSender`: the contaktly
  backend (`ContaktlyServiceSender`), a simulation
  (`ContaktlySimulatedSender`), a function of yours
  (`ContaktlyFunctionSender`).

```yaml
dependencies:
  contaktly_form:
    git:
      url: https://github.com/tekaly/contaktly
      path: packages/contaktly_form
```

```dart
import 'package:contaktly_form/contaktly_form.dart';

Future<void> main() async {
  var published = await contaktlyFormPublishedLoad(
    Uri.parse('https://contact.wannahub.com/f/<formId>/form.json'),
  );
  var sender = ContaktlyServiceSender(published: published);
  var form = ContaktlyFormController(
    form: published.form.v!,
    sender: sender,
    lang: 'en',
  )
    ..setValue(contaktlyFormFieldEmail, 'ana@example.com')
    ..setValue(contaktlyFormFieldMessage, 'Hello');
  await form.submit();
  print(form.status); // sent, or failed with form.failure
  sender.close();
}
```

The enc password of a published form is public by construction (it is in its
`form.json`): the backend protects the service (its sender and recipients
fixed, its limits).

## Files

A form taking files has `attachments` (`CvContaktlyFormAttachments`:
`maxFiles`, `shownFiles` (more fields shown, the ones past `maxFiles`
disabled), `maxFileSize`, `types`), set by the contaktly backend for a form
published there. Images, PDF, Office and OpenDocument documents, 5 MB a file
and 10 MB in all at most. The files go in `ContaktlyFormValues.files`
(`controller.addFile(ContaktlyFormFile(name:, bytes:))`), checked by
`contaktlyFormValidate` (their count, size and type on their first bytes)
and sent in the request by `ContaktlyServiceSender` (not signed: the backend
reads their content and refuses the documents with macros).
