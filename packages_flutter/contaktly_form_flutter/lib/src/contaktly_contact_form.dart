import 'package:contaktly_form/contaktly_form.dart';
import 'package:material_ui/material_ui.dart';

/// The key of the field [key] (`name`, `email`, `subject`, `message`), for
/// tests and screenshots.
Key contaktlyContactFormFieldKey(String key) => ValueKey('contaktly_form_$key');

/// The key of the send button.
const contaktlyContactFormSubmitKey = ValueKey('contaktly_form_submit');

/// The key of the "write another message" button of the sent panel.
const contaktlyContactFormAnotherKey = ValueKey('contaktly_form_another');

/// A contaktly contact form: the shown fields of a form in a language,
/// their validation, the send button, then the sent panel, or the failure.
///
/// It follows the host theme; with [applyLook], the form's accent colour,
/// corner radius and density go over it.
class ContaktlyContactForm extends StatefulWidget {
  /// The form, null with [controller].
  final ContaktlyFormMixin? form;

  /// Sends a valid message, null with [controller].
  final ContaktlyFormSender? sender;

  /// The state of the form when given (to read its status, or drive it),
  /// the form's own otherwise.
  final ContaktlyFormController? controller;

  /// The language, the form's default when null or not one of its own.
  final String? lang;

  /// Adapts the texts of the form: `(strings) => strings.copyWith(...)`.
  final ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings;

  /// Called once a message is sent, with the answer.
  final ValueChanged<ContaktlyFormSendResult>? onSent;

  /// The form's look (accent, radius, compact) over the host theme.
  final bool applyLook;

  /// Robot check (honeypot, fill time): a message that looks like a robot's
  /// shows as sent and is not sent. Off in tests that type fast.
  final bool spamCheck;

  /// The title of the form above it, true by default; false under a heading
  /// of the page.
  final bool showTitle;

  /// The image, the photo and the name of a user form's owner above it,
  /// true by default.
  final bool showProfile;

  /// The form [form] in [lang], sending through [sender].
  const ContaktlyContactForm({
    super.key,
    required ContaktlyFormMixin this.form,
    required ContaktlyFormSender this.sender,
    this.lang,
    this.strings,
    this.onSent,
    this.applyLook = true,
    this.spamCheck = true,
    this.showTitle = true,
    this.showProfile = true,
  }) : controller = null;

  /// The form of [controller], its state: its form, sender, language and
  /// texts.
  const ContaktlyContactForm.controller(
    ContaktlyFormController this.controller, {
    super.key,
    this.onSent,
    this.applyLook = true,
    this.showTitle = true,
    this.showProfile = true,
  }) : form = null,
       sender = null,
       lang = null,
       strings = null,
       spamCheck = true;

  @override
  State<ContaktlyContactForm> createState() => _ContaktlyContactFormState();
}

class _ContaktlyContactFormState extends State<ContaktlyContactForm> {
  late ContaktlyFormController _form;
  var _ownController = false;
  final _texts = {
    for (var key in contaktlyFormFieldKeys) key: TextEditingController(),
  };
  final _honeypot = TextEditingController();

  @override
  void initState() {
    super.initState();
    _attach();
  }

  /// Uses the given controller, or a new one of the form keeping what was
  /// typed.
  void _attach() {
    var controller = widget.controller;
    if (controller != null) {
      _ownController = false;
      _form = controller;
    } else {
      _ownController = true;
      _form = ContaktlyFormController(
        form: widget.form!,
        // The sender and the texts of the widget when used.
        sender: ContaktlyFunctionSender(
          (values) => widget.sender!.send(values),
        ),
        lang: widget.lang,
        strings: (strings) => widget.strings?.call(strings) ?? strings,
        spamCheck: widget.spamCheck,
      );
      for (var entry in _texts.entries) {
        if (entry.value.text.isNotEmpty) {
          _form.setValue(entry.key, entry.value.text);
        }
      }
    }
    _form.addListener(_onChange);
    _syncTexts();
  }

  void _detach() {
    _form.removeListener(_onChange);
    if (_ownController) {
      _form.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant ContaktlyContactForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.form != widget.form ||
        oldWidget.lang != widget.lang ||
        oldWidget.spamCheck != widget.spamCheck) {
      _detach();
      _attach();
    }
  }

  /// The fields show the values of the controller (emptied for another
  /// message, filled by its owner).
  void _syncTexts() {
    for (var entry in _texts.entries) {
      var value = _form.valueOf(entry.key);
      if (entry.value.text != value) {
        entry.value.text = value;
      }
    }
    if (_honeypot.text != _form.honeypot) {
      _honeypot.text = _form.honeypot;
    }
  }

  void _onChange() {
    if (mounted) {
      setState(_syncTexts);
    }
  }

  @override
  void dispose() {
    _detach();
    for (var controller in _texts.values) {
      controller.dispose();
    }
    _honeypot.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _form.honeypot = _honeypot.text;
    var result = await _form.submit();
    if (result != null && mounted) {
      widget.onSent?.call(result);
    }
  }

  void _changed(String key, String value) {
    _form.setValue(key, value);
    _form.clearError(key);
  }

  @override
  Widget build(BuildContext context) {
    // Built under the look: its colours and corners reach every part.
    Widget content(BuildContext context) {
      var body = _form.status == ContaktlyFormStatus.sent
          ? _sentPanel(context)
          : _fields(context);
      var profile = widget.showProfile ? _form.form.profile.v : null;
      if (profile == null) {
        return body;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ContaktlyContactFormProfile(profile: profile),
          body,
        ],
      );
    }

    return widget.applyLook
        ? _withLook(context, Builder(builder: content))
        : content(context);
  }

  Widget _fields(BuildContext context) {
    var strings = _form.strings;
    var text = Theme.of(context).textTheme;
    var compact = widget.applyLook && (_form.form.look.v?.compact.v ?? false);
    var gap = compact ? 10.0 : 16.0;
    var sending = _form.isSending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showTitle && strings.title.isNotEmpty) ...[
          Text(strings.title, style: text.headlineSmall),
          SizedBox(height: gap / 2),
        ],
        if (strings.intro.isNotEmpty) ...[
          Text(strings.intro, style: text.bodyMedium),
          SizedBox(height: gap),
        ],
        for (var field in _form.form.shownFields) ...[
          _field(field, strings),
          SizedBox(height: gap),
        ],
        // A field a person never sees, robots fill it.
        ExcludeFocus(
          child: Offstage(child: TextField(controller: _honeypot)),
        ),
        if (strings.consent.isNotEmpty) ...[
          Text(strings.consent, style: text.bodySmall),
          SizedBox(height: gap),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            key: contaktlyContactFormSubmitKey,
            onPressed: sending ? null : _submit,
            child: Text(sending ? strings.sending : strings.submit),
          ),
        ),
        if (_form.status == ContaktlyFormStatus.failed) ...[
          SizedBox(height: gap),
          Text(
            _form.failure.isEmpty ? strings.error : _form.failure,
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(CvContaktlyFormField field, ContaktlyFormStrings strings) {
    var key = field.key.v!;
    var isMessage = key == contaktlyFormFieldMessage;
    var isEmail = key == contaktlyFormFieldEmail;
    var label = strings.labelOf(key);
    var sending = _form.isSending;
    var choices = key == contaktlyFormFieldSubject
        ? strings.subjectChoices
        : const <String>[];
    if (choices.isNotEmpty) {
      var current = _form.valueOf(key);
      // A new one after "write another message" (emptied).
      return KeyedSubtree(
        key: ValueKey(_form.shownAt),
        child: DropdownButtonFormField<String>(
          key: contaktlyContactFormFieldKey(key),
          initialValue: choices.contains(current) ? current : null,
          items: [
            for (var choice in choices)
              DropdownMenuItem(value: choice, child: Text(choice)),
          ],
          onChanged: sending
              ? null
              : (value) {
                  _texts[key]!.text = value ?? '';
                  _changed(key, value ?? '');
                },
          decoration: InputDecoration(
            labelText: field.required.v! ? '$label *' : label,
            errorText: _form.errorOf(key),
          ),
        ),
      );
    }
    return TextField(
      key: contaktlyContactFormFieldKey(key),
      controller: _texts[key],
      enabled: !sending,
      keyboardType: isEmail
          ? TextInputType.emailAddress
          : (isMessage ? TextInputType.multiline : TextInputType.text),
      autocorrect: !isEmail,
      minLines: isMessage ? 4 : 1,
      maxLines: isMessage ? 10 : 1,
      decoration: InputDecoration(
        labelText: field.required.v! ? '$label *' : label,
        errorText: _form.errorOf(key),
        alignLabelWithHint: isMessage,
      ),
      onChanged: (value) => _changed(key, value),
    );
  }

  Widget _sentPanel(BuildContext context) {
    var strings = _form.strings;
    var text = Theme.of(context).textTheme;
    var scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mark_email_read_outlined, size: 40, color: scheme.primary),
        const SizedBox(height: 12),
        Text(strings.sentTitle, style: text.headlineSmall),
        const SizedBox(height: 8),
        Text(_form.sentText, style: text.bodyMedium),
        const SizedBox(height: 16),
        OutlinedButton(
          key: contaktlyContactFormAnotherKey,
          onPressed: _form.another,
          child: Text(strings.another),
        ),
      ],
    );
  }

  /// The form's accent colour and corner radius over the host theme: its
  /// colour scheme, and the button colours and field borders a theme may
  /// set explicitly (the festenao ones do).
  Widget _withLook(BuildContext context, Widget child) {
    var look = _form.form.look.v;
    var accent = _parseColor(look?.accent.v);
    var radius = look?.radius.v;
    if (accent == null && radius == null) {
      return child;
    }
    var theme = Theme.of(context);
    var scheme = accent == null
        ? theme.colorScheme
        : ColorScheme.fromSeed(
            seedColor: accent,
            brightness: theme.brightness,
          ).copyWith(primary: accent);
    var borderRadius = radius == null
        ? null
        : BorderRadius.circular(radius.toDouble());
    var shape = borderRadius == null
        ? null
        : RoundedRectangleBorder(borderRadius: borderRadius);

    /// [border] with the corners of the look, [color] its line.
    InputBorder? reshape(InputBorder? border, {Color? color}) {
      if (border is OutlineInputBorder) {
        return border.copyWith(
          borderRadius: borderRadius,
          borderSide: color == null
              ? null
              : border.borderSide.copyWith(color: color),
        );
      }
      if (borderRadius == null) {
        return border;
      }
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: color == null
            ? const BorderSide()
            : BorderSide(color: color),
      );
    }

    var input = theme.inputDecorationTheme;
    return Theme(
      data: theme.copyWith(
        colorScheme: scheme,
        inputDecorationTheme: input.copyWith(
          border: reshape(input.border),
          enabledBorder: reshape(input.enabledBorder),
          focusedBorder: reshape(input.focusedBorder, color: accent),
          errorBorder: reshape(input.errorBorder),
          focusedErrorBorder: reshape(input.focusedErrorBorder),
          floatingLabelStyle: accent == null
              ? input.floatingLabelStyle
              : (input.floatingLabelStyle ?? const TextStyle()).copyWith(
                  color: accent,
                ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: accent == null ? null : scheme.onPrimary,
            shape: shape,
          ).merge(theme.filledButtonTheme.style),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: shape,
          ).merge(theme.outlinedButtonTheme.style),
        ),
      ),
      child: child,
    );
  }
}

/// The key of the profile above a user form.
const contaktlyContactFormProfileKey = ValueKey('contaktly_form_profile');

/// The image, the photo and the name of a user form's owner, above the
/// form.
class ContaktlyContactFormProfile extends StatelessWidget {
  /// The profile of the form.
  final CvContaktlyFormProfile profile;

  /// The profile.
  const ContaktlyContactFormProfile({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var imageUrl = profile.imageUrl.v;
    var pictureUrl = profile.pictureUrl.v;
    var name = profile.name.v ?? '';
    Widget placeholder() => ColoredBox(color: scheme.surfaceContainerHighest);
    return Column(
      key: contaktlyContactFormProfileKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 3,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (pictureUrl != null) ...[
          Row(
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 56,
                  child: Image.network(
                    pictureUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => placeholder(),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// `#RRGGBB` as a colour, null if not one.
Color? _parseColor(String? hex) {
  var match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex ?? '');
  if (match == null) {
    return null;
  }
  return Color(0xFF000000 | int.parse(match.group(1)!, radix: 16));
}
