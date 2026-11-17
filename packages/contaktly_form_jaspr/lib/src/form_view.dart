import 'package:contaktly_form/contaktly_form.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'browser.dart';

/// The name of the hidden field a person never fills (robots do).
const contaktlyFormHoneypotName = 'website';

/// The contact form [form] in [lang]: its fields, validation and the send
/// through [sender], then the sent panel or the failure. Not an island: the
/// island of a site renders it with its sender ([ContaktlyFormIsland] for
/// the contaktly backend); on the server it renders the form as a visitor
/// first sees it.
class ContaktlyContactFormView extends StatefulComponent {
  /// The form.
  final ContaktlyFormMixin form;

  /// The language, the form's default when it does not have it.
  final String lang;

  /// Sends a valid message, null on the server.
  final ContaktlyFormSender? sender;

  /// Called once a message is sent.
  final void Function(ContaktlyFormSendResult result)? onSent;

  /// Called after each change of the form (a page in an iframe tells its
  /// height).
  final void Function()? onChanged;

  /// Where the form posts (`method="post"`, its fields by name, as
  /// `multipart/form-data` when it takes files: `file1`, `file2`...) when no
  /// script runs; without, its button waits for the island.
  final String? action;

  /// The robot check (honeypot, fill time), on by default.
  final bool spamCheck;

  /// The values shown at first by field key (`contaktlyFormFieldKeys`): a
  /// form prefilled, or posted again with its problems.
  final Map<String, String> values;

  /// Hidden fields posted with the form ([action]) by name, none by
  /// default.
  final Map<String, String> hiddenFields;

  /// Adapts the texts of the form (`(strings) => strings.copyWith(...)`),
  /// all of them: the line under the file fields shown disabled
  /// (`filesLocked`), the refusal and validation texts too.
  final ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings;

  /// The form [form].
  const ContaktlyContactFormView({
    super.key,
    required this.form,
    required this.lang,
    this.sender,
    this.onSent,
    this.onChanged,
    this.action,
    this.spamCheck = true,
    this.values = const {},
    this.hiddenFields = const {},
    this.strings,
  });

  @override
  State<ContaktlyContactFormView> createState() =>
      _ContaktlyContactFormViewState();
}

class _ContaktlyContactFormViewState extends State<ContaktlyContactFormView> {
  late ContaktlyFormController _form;

  @override
  void initState() {
    super.initState();
    _form = _newController();
  }

  ContaktlyFormController _newController() {
    var controller = ContaktlyFormController(
      form: component.form,
      // The sender of the component when used.
      sender: ContaktlyFunctionSender((values) {
        var sender = component.sender;
        if (sender == null) {
          throw StateError('No sender');
        }
        return sender.send(values);
      }),
      lang: component.lang,
      strings: component.strings,
      spamCheck: component.spamCheck,
      shownAt: _pageShownAt(),
    );
    for (var entry in component.values.entries) {
      controller.setValue(entry.key, entry.value);
    }
    return controller..addListener(_changed);
  }

  @override
  void didUpdateComponent(covariant ContaktlyContactFormView oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.form != component.form ||
        oldComponent.lang != component.lang ||
        oldComponent.spamCheck != component.spamCheck) {
      _form.dispose();
      _form = _newController();
    }
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _changed() {
    setState(() {});
  }

  @override
  void setState(void Function() fn) {
    super.setState(fn);
    component.onChanged?.call();
  }

  /// When the page showed: the form is rendered on the server, a visitor
  /// sees it (and may fill it) before the island is hydrated.
  static DateTime _pageShownAt() {
    var now = DateTime.now();
    if (!kIsWeb) {
      return now;
    }
    var sincePageStart = web.window.performance.now();
    return now.subtract(
      Duration(microseconds: (sincePageStart * 1000).round()),
    );
  }

  /// The values of the fields of [form] as the page shows them: what was
  /// typed (or filled by the browser) before the island was hydrated sent no
  /// input event.
  void _readPageValues(web.EventTarget? form) {
    if (form == null) {
      return;
    }
    var elements = (form as web.HTMLFormElement).elements;
    String? valueOf(String name) {
      var element = elements.namedItem(name);
      // An input, a textarea or a select: each has a value.
      return element == null ? null : (element as web.HTMLInputElement).value;
    }

    for (var key in contaktlyFormFieldKeys) {
      var value = valueOf(key);
      if (value != null) {
        _form.setValue(key, value);
      }
    }
    _form.honeypot = valueOf(contaktlyFormHoneypotName) ?? _form.honeypot;
  }

  /// Reading the files of the page before a send.
  var _reading = false;

  /// The files chosen in the page ([form]) given to the form, false when
  /// one is too big to read.
  Future<bool> _readPageFiles(web.EventTarget? form) async {
    var pageFiles = contaktlyFormPageFiles(form);
    var strings = _form.strings;
    var maxFileSize = _form.form.maxFileSizeOrDefault;
    var total = 0;
    for (var file in pageFiles) {
      total += file.size;
      if (file.size > maxFileSize) {
        _form.setError(
          contaktlyFormFilesKey,
          strings.fileTooBigErrorFor(file.name, maxFileSize),
        );
        return false;
      }
    }
    if (total > contaktlyFormFilesMaxSize) {
      _form.setError(
        contaktlyFormFilesKey,
        strings.filesTooBigErrorFor(contaktlyFormFilesMaxSize),
      );
      return false;
    }
    _form.setFiles([
      for (var file in pageFiles)
        ContaktlyFormFile(
          name: file.name,
          type: file.type,
          bytes: await file.read(),
        ),
    ]);
    return true;
  }

  Future<void> _submit(web.Event event) async {
    event.preventDefault();
    if (_form.isSending || _reading) {
      return;
    }
    _readPageValues(event.target);
    if (_form.form.takesFiles) {
      _reading = true;
      try {
        if (!await _readPageFiles(event.target)) {
          return;
        }
      } finally {
        _reading = false;
      }
    }
    var result = await _form.submit();
    if (result != null) {
      component.onSent?.call(result);
    }
  }

  @override
  Component build(BuildContext context) {
    if (_form.status == ContaktlyFormStatus.sent) {
      return _sentPanel();
    }
    var strings = _form.strings;
    var sending = _form.isSending;
    var action = component.action;
    var takesFiles = _form.form.takesFiles;
    return form(
      classes: 'cf-form',
      attributes: {
        'novalidate': '',
        if (action != null) ...{
          'action': action,
          'method': 'post',
          if (takesFiles) 'enctype': 'multipart/form-data',
        },
      },
      events: {'submit': (event) => _submit(event)},
      [
        if (strings.title.isNotEmpty)
          h1(classes: 'cf-title', [.text(strings.title)]),
        if (strings.intro.isNotEmpty)
          p(classes: 'cf-intro', [.text(strings.intro)]),
        for (var field in _form.form.shownFields) _field(field, strings),
        if (takesFiles) _files(strings),
        for (var entry in component.hiddenFields.entries)
          input<String>(
            type: InputType.hidden,
            name: entry.key,
            value: entry.value,
          ),
        // A field a person never sees, robots fill it.
        div(
          classes: 'cf-hp',
          attributes: const {'aria-hidden': 'true'},
          [
            input<String>(
              name: contaktlyFormHoneypotName,
              type: InputType.text,
              attributes: const {'tabindex': '-1', 'autocomplete': 'off'},
              onInput: (value) => _form.honeypot = value,
            ),
          ],
        ),
        if (strings.consent.isNotEmpty) _consent(strings),
        if (_form.status == ContaktlyFormStatus.failed)
          p(
            classes: 'cf-error',
            attributes: const {'role': 'alert'},
            [.text(_form.failure)],
          ),
        div(classes: 'cf-actions', [
          button(
            type: ButtonType.submit,
            classes: 'cf-button',
            // Without an action, disabled until hydrated: an early click (or
            // Enter) would submit the form as a GET, the values in the url.
            disabled: sending || (!kIsWeb && action == null),
            [.text(sending ? strings.sending : strings.submit)],
          ),
        ]),
      ],
    );
  }

  Component _consent(ContaktlyFormStrings strings) => p(classes: 'cf-consent', [
    .text(strings.consent),
    if (strings.privacyUrl.isNotEmpty) ...[
      const .text(' '),
      a(
        href: strings.privacyUrl,
        target: Target.blank,
        attributes: const {'rel': 'noopener'},
        [.text(strings.privacyUrl)],
      ),
    ],
  ]);

  Component _field(CvContaktlyFormField field, ContaktlyFormStrings strings) {
    var key = field.key.v!;
    var id = 'cf-$key';
    var error = _form.errorOf(key);
    var required = field.required.v!;
    var labelText = strings.labelOf(key);
    var value = _form.valueOf(key);
    var attributes = <String, String>{
      if (required) 'required': '',
      if (error != null) ...{
        'aria-invalid': 'true',
        'aria-describedby': '$id-error',
      },
      'autocomplete': switch (key) {
        contaktlyFormFieldName => 'name',
        contaktlyFormFieldEmail => 'email',
        _ => 'off',
      },
    };
    void onInput(String value) {
      _form
        ..setValue(key, value)
        ..clearError(key);
    }

    var choices = key == contaktlyFormFieldSubject
        ? strings.subjectChoices
        : const <String>[];
    return div(classes: error == null ? 'cf-field' : 'cf-field cf-invalid', [
      label(htmlFor: id, [.text(required ? '$labelText *' : labelText)]),
      if (choices.isNotEmpty)
        select(
          id: id,
          name: key,
          attributes: attributes,
          onChange: (values) => onInput(values.isEmpty ? '' : values.first),
          [
            // Nothing chosen yet.
            option(value: '', selected: value.isEmpty, const [.text('—')]),
            for (var choice in choices)
              option(value: choice, selected: value == choice, [.text(choice)]),
          ],
        )
      else if (key == contaktlyFormFieldMessage)
        textarea(
          id: id,
          name: key,
          rows: 6,
          attributes: attributes,
          onInput: onInput,
          [.text(value)],
        )
      else
        input<String>(
          id: id,
          name: key,
          type: key == contaktlyFormFieldEmail
              ? InputType.email
              : InputType.text,
          value: value.isEmpty ? null : value,
          attributes: attributes,
          onInput: onInput,
        ),
      if (error != null)
        p(id: '$id-error', classes: 'cf-field-error', [.text(error)]),
    ]);
  }

  /// The file inputs of a form taking files: one per file, the ones past its
  /// max shown disabled, the types and the size under them.
  Component _files(ContaktlyFormStrings strings) {
    var form = _form.form;
    var error = _form.errorOf(contaktlyFormFilesKey);
    var maxFiles = form.maxFileCount;
    var shown = form.shownFileCount;
    var types = form.fileTypesOrDefault;
    var accept = contaktlyFormFileAccept(types);
    var locked = shown > maxFiles && strings.filesLocked.isNotEmpty;
    var describedBy = [
      'cf-files-help',
      if (locked) 'cf-files-locked',
      if (error != null) 'cf-files-error',
    ].join(' ');
    return div(
      classes: error == null
          ? 'cf-field cf-files'
          : 'cf-field cf-files cf-invalid',
      [
        label(htmlFor: 'cf-file1', [.text(strings.filesLabel)]),
        for (var i = 0; i < shown; i++)
          input<String>(
            id: 'cf-file${i + 1}',
            name: 'file${i + 1}',
            type: InputType.file,
            classes: 'cf-file',
            disabled: i >= maxFiles,
            attributes: {
              'accept': accept,
              if (shown > 1) 'aria-label': '${strings.filesLabel} ${i + 1}',
              'aria-describedby': describedBy,
              if (error != null) 'aria-invalid': 'true',
            },
            events: {'change': (_) => _form.clearError(contaktlyFormFilesKey)},
          ),
        p(id: 'cf-files-help', classes: 'cf-help', [
          .text(strings.filesHelpFor(types, form.maxFileSizeOrDefault)),
        ]),
        if (locked)
          p(id: 'cf-files-locked', classes: 'cf-help', [
            .text(strings.filesLocked),
          ]),
        if (error != null)
          p(id: 'cf-files-error', classes: 'cf-field-error', [.text(error)]),
      ],
    );
  }

  Component _sentPanel() {
    var strings = _form.strings;
    return div(
      classes: 'cf-sent',
      attributes: const {'role': 'status'},
      [
        h1(classes: 'cf-title', [.text(strings.sentTitle)]),
        p([.text(_form.sentText)]),
        div(classes: 'cf-actions', [
          button(
            type: ButtonType.button,
            classes: 'cf-button cf-button-quiet',
            onClick: _form.another,
            [.text(strings.another)],
          ),
        ]),
      ],
    );
  }
}
