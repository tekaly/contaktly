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
