# contaktly_form_jaspr

A contaktly contact form for jaspr sites.

```yaml
dependencies:
  contaktly_form_jaspr:
    git:
      url: https://github.com/tekaly/contaktly
      path: packages/contaktly_form_jaspr
```

In a page, server side: the published form is loaded when the page renders
(a static site gets the version published when it builds), its island
joins the site's client bundle and sends through the contaktly backend.

```dart
import 'package:contaktly_form_jaspr/server.dart';

final contactForm = ContaktlyContactFormLoader(
  url: Uri.parse('https://contact.wannahub.com/f/<formId>/form.json'),
  lang: 'fr',
  // card: false, // no border nor background: the page's
  // showTitle: false, // under a heading of the page
  // strings: (strings) => strings.copyWith(submit: 'Envoyer'),
);
```

Its css is scoped under `.cf-root` (the page keeps its font): set its
variables (`--cf-accent`, `--cf-radius`...) in the site's css to adapt it.

Another sender (your own backend, a simulation): an island of your own
rendering `ContaktlyContactFormView(form:, lang:, sender:)`; with `action:`
the form also posts by itself where no script runs.
