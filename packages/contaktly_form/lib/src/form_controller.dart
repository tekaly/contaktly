import 'form_files.dart';
import 'form_message.dart';
import 'form_model.dart';
import 'form_sender.dart';
import 'form_texts.dart';

/// Where a form is.
enum ContaktlyFormStatus {
  /// Being filled (again after a failure, [ContaktlyFormController.failure]
  /// then set).
  editing,

  /// Sending a message.
  sending,

  /// Sent: the sent panel.
  sent,

  /// Not sent: [ContaktlyFormController.failure] says why; the form can be
  /// sent again.
  failed,
}

/// The state of a form, for any UI (the Flutter widget, the jaspr island,
/// fields of your own): the values typed, their validation, the robot
/// check, the send through [sender], then the sent panel or the failure.
///
/// The listeners are called after each change of [status], [errors],
/// [failure] or [files]; [setValue] calls none (the fields show what is
/// typed).
class ContaktlyFormController {
  /// The form: its fields, their configuration, its texts.
  final ContaktlyFormMixin form;

  /// Sends a valid message.
  final ContaktlyFormSender sender;

  /// The language asked, the form's default one when null or not one of
  /// its own.
  final String? lang;

  /// Adapts the texts of the form (`(strings) => strings.copyWith(...)`),
  /// none by default.
  final ContaktlyFormStrings Function(ContaktlyFormStrings strings)?
  stringsAdapter;

  /// Robot check (honeypot, fill time): a message that looks like a robot's
  /// shows as sent and is not sent. Off in tests that type fast.
  final bool spamCheck;

  final DateTime Function() _now;
  final _values = <String, String>{};
  var _files = const <ContaktlyFormFile>[];
  final _listeners = <void Function()>[];
  late DateTime _shownAt;
  var _status = ContaktlyFormStatus.editing;
  var _errors = const <String, String>{};
  var _sentEmail = '';
  var _failure = '';
  Object? _error;
  ContaktlyFormSendResult? _result;
  var _disposed = false;

  /// The controller of [form] in [lang] (the form's default language when
  /// null or not one of its own), sending through [sender]; [strings]
  /// adapts its texts, [shownAt] is when the visitor first saw the form (now
  /// by default), [now] for tests.
  ContaktlyFormController({
    required this.form,
    required this.sender,
    this.lang,
    ContaktlyFormStrings Function(ContaktlyFormStrings strings)? strings,
    this.spamCheck = true,
    DateTime? shownAt,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       stringsAdapter = strings {
    _shownAt = shownAt ?? _now();
  }

  /// The texts: the form's own in [lang] (read each time: a form being
  /// edited shows its new texts), adapted by [stringsAdapter].
  ContaktlyFormStrings get strings {
    var strings = contaktlyFormStrings(form, lang);
    return stringsAdapter?.call(strings) ?? strings;
  }

  /// The value typed in the field [key] (one of `contaktlyFormFieldKeys`).
  String valueOf(String key) => _values[key] ?? '';

  /// Sets the value of the field [key], no listener called.
  void setValue(String key, String value) {
    _values[key] = value;
  }

  /// The files picked, in their order.
  List<ContaktlyFormFile> get files => _files;

  /// Sets the files picked, their error cleared, listeners called.
  void setFiles(List<ContaktlyFormFile> files) {
    _files = List.unmodifiable(files);
    if (_errors.containsKey(contaktlyFormFilesKey)) {
      _errors = {..._errors}..remove(contaktlyFormFilesKey);
    }
    _notify();
  }

  /// Adds [file] to the files picked ([setFiles]).
  void addFile(ContaktlyFormFile file) => setFiles([..._files, file]);

  /// Removes the file picked at [index] ([setFiles]).
  void removeFile(int index) => setFiles([..._files]..removeAt(index));

  /// The hidden field a person never fills (robots do).
  var honeypot = '';

  /// When the visitor saw the form, for the robot check.
  DateTime get shownAt => _shownAt;

  /// The values to send.
  ContaktlyFormValues get values => ContaktlyFormValues(
    name: _values[contaktlyFormFieldName],
    email: _values[contaktlyFormFieldEmail],
    subject: _values[contaktlyFormFieldSubject],
    message: _values[contaktlyFormFieldMessage],
    honeypot: honeypot,
    shownAt: _shownAt,
    files: _files,
  );

  /// Where the form is.
  ContaktlyFormStatus get status => _status;

  /// True while a message is sent.
  bool get isSending => _status == ContaktlyFormStatus.sending;

  /// The errors of the last [submit] by field key, empty when none.
  Map<String, String> get errors => _errors;

  /// The error of the field [key], null when none.
  String? errorOf(String key) => _errors[key];

  /// Sets the error of the field [key] (a check of the UI: a file too big
  /// to read), listeners called.
  void setError(String key, String error) {
    _errors = {..._errors, key: error};
    _notify();
  }

  /// Clears the error of the field [key] (the visitor types again),
  /// listeners called when it had one.
  void clearError(String key) {
    if (_errors.containsKey(key)) {
      _errors = {..._errors}..remove(key);
      _notify();
    }
  }

  /// The email the last message was sent from.
  String get sentEmail => _sentEmail;

  /// The text of the sent panel.
  String get sentText => strings.sentTextFor(_sentEmail);

  /// Why the last send failed (closed, limited, or the form's error), empty
  /// when it did not.
  String get failure => _failure;

  /// The error of the last failed send.
  Object? get error => _error;

  /// The answer to the last message sent.
  ContaktlyFormSendResult? get result => _result;

  /// Validates and sends the values; the answer, or null when not sent
  /// (invalid values, a robot, a failure, already sending).
  Future<ContaktlyFormSendResult?> submit() async {
    if (_disposed || isSending) {
      return null;
    }
    var values = this.values;
    var errors = contaktlyFormValidate(form, values, strings);
    if (errors.isNotEmpty) {
      _errors = errors;
      _notify();
      return null;
    }
    var email = values.valueOf(contaktlyFormFieldEmail)!;
    _errors = const {};
    if (spamCheck && contaktlyFormIsLikelySpam(values, now: _now())) {
      // A robot: it sees the message sent.
      _sentEmail = email;
      _status = ContaktlyFormStatus.sent;
      _notify();
      return null;
    }
    _failure = '';
    _error = null;
    _status = ContaktlyFormStatus.sending;
    _notify();
    try {
      var result = await sender.send(values);
      if (_disposed) {
        return result;
      }
      _result = result;
      _sentEmail = email;
      _status = ContaktlyFormStatus.sent;
      _notify();
      return result;
    } catch (e) {
      if (!_disposed) {
        _error = e;
        _failure = contaktlyFormSendErrorText(e, strings);
        _status = ContaktlyFormStatus.failed;
        _notify();
      }
      return null;
    }
  }

  /// Back to the form for another message: the name and the email kept,
  /// the subject, the message and the files emptied.
  void another() {
    _values
      ..remove(contaktlyFormFieldSubject)
      ..remove(contaktlyFormFieldMessage);
    _files = const [];
    _shownAt = _now();
    _errors = const {};
    _failure = '';
    _error = null;
    _result = null;
    _status = ContaktlyFormStatus.editing;
    _notify();
  }

  /// Calls [listener] after each change.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Stops calling [listener].
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// No listener called anymore; the sender is not closed (its owner
  /// closes it).
  void dispose() {
    _disposed = true;
    _listeners.clear();
  }

  void _notify() {
    for (var listener in List.of(_listeners)) {
      listener();
    }
  }
}
