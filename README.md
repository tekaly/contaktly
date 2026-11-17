# contaktly

Contact forms for Dart, jaspr and Flutter, sent through the
[Contaktly](https://contaktly.wannahub.com) backend or your own.

A form is made and published in the Contaktly app; its "Use this form"
panel gives the code below for that form.

| Package | |
|---|---|
| [contaktly_form](packages/contaktly_form) | Pure Dart: the form model, its texts, validation, a controller for any UI, the senders of a message |
| [contaktly_form_jaspr](packages/contaktly_form_jaspr) | A jaspr component (and its island) for a page of a jaspr site |
| [contaktly_form_flutter](packages_flutter/contaktly_form_flutter) | A Flutter widget |

Three ways to use a form, from the simplest:

1. **Ready to use**: `ContaktlyContactFormLoader` (jaspr) or
   `ContaktlyPublishedForm` (Flutter) with the url of the form's
   `form.json`.
2. **Adapted**: their options (no title, the host theme only, your texts
   with `strings: (strings) => strings.copyWith(...)`).
3. **Your own UI**: `ContaktlyFormController` with fields of your own, or
   `ContaktlyServiceSender` without any UI; another backend through a
   `ContaktlyFormSender` of yours.

The packages follow the tip of this repository (git dependencies).
