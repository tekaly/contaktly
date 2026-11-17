# contaktly_form_flutter

A contaktly contact form as a Flutter widget, on the host theme.

```yaml
dependencies:
  contaktly_form_flutter:
    git:
      url: https://github.com/tekaly/contaktly
      path: packages_flutter/contaktly_form_flutter
```

A form published on its forms site, loaded when shown (the latest version),
sending through the contaktly backend:

```dart
import 'package:contaktly_form_flutter/contaktly_form_flutter.dart';

final contactForm = ContaktlyPublishedForm(
  url: Uri.parse('https://contact.wannahub.com/f/<formId>/form.json'),
  lang: 'fr',
  // showTitle: false, // under a heading of the screen
  // applyLook: false, // the app theme only
  // strings: (strings) => strings.copyWith(submit: 'Envoyer'),
  // onSent: (result) {},
);
```

`ContaktlyContactForm(form:, sender:)` takes any `ContaktlyFormSender`
(`ContaktlyFunctionSender` for your own backend, `ContaktlySimulatedSender`
for tests); `ContaktlyContactForm.controller(controller)` shows a
`ContaktlyFormController` you read or drive.

## Files

A form taking files shows its file field when given a `filePicker` (the
package has no plugin: the picker of your app). With
[`file_selector`](https://pub.dev/packages/file_selector):

```dart
import 'package:file_selector/file_selector.dart';

Future<ContaktlyFormFile?> pickFile(List<String> types) async {
  var file = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: 'files',
        extensions: contaktlyFormFileExtensions(types),
        mimeTypes: types,
      ),
    ],
  );
  if (file == null) {
    return null;
  }
  return ContaktlyFormFile(
    name: file.name,
    type: file.mimeType ?? '',
    bytes: await file.readAsBytes(),
  );
}

final contactForm = ContaktlyPublishedForm(
  url: Uri.parse('https://contact.wannahub.com/f/<formId>/form.json'),
  filePicker: pickFile,
);
```
