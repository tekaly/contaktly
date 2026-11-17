import 'package:tekartik_mail/utils/mail_utils.dart' show validateEmail;
import 'package:tekartik_mail_tk/mail_tk.dart';

import 'form_files.dart';
import 'form_model.dart';
import 'form_texts.dart';

/// The longest name, subject and email.
const contaktlyFormShortMaxLength = 200;

/// The longest message.
const contaktlyFormMessageMaxLength = 10000;

/// A message sent sooner than this after the form showed is taken for a
/// robot's.
const contaktlyFormMinFillDuration = Duration(seconds: 3);

/// What a visitor typed in a form.
class ContaktlyFormValues {
  /// The name.
  final String? name;

  /// The email, the reply-to.
  final String? email;

  /// The subject.
  final String? subject;

  /// The message.
  final String? message;

  /// The hidden field a person never fills (robots do).
  final String? honeypot;

  /// When the form showed, for [contaktlyFormIsLikelySpam].
  final DateTime? shownAt;

  /// The files picked, for a form taking files; none by default.
  final List<ContaktlyFormFile> files;

  /// The values of a form.
  const ContaktlyFormValues({
    this.name,
    this.email,
    this.subject,
    this.message,
    this.honeypot,
    this.shownAt,
    this.files = const [],
  });

  /// The value of the field [key], trimmed, null when empty.
  String? valueOf(String key) {
    var value = switch (key) {
      contaktlyFormFieldName => name,
      contaktlyFormFieldEmail => email,
      contaktlyFormFieldSubject => subject,
      _ => message,
    };
    var trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// The errors of [values] in [form], by field key, empty when valid: a
/// required field left empty, an invalid email, a value too long; the files
/// under [contaktlyFormFilesKey] (the first error): too many, a type not
/// taken, too big. A hidden field is ignored.
Map<String, String> contaktlyFormValidate(
  ContaktlyFormMixin form,
  ContaktlyFormValues values,
  ContaktlyFormStrings strings,
) {
  var errors = <String, String>{};
  for (var field in form.shownFields) {
    var key = field.key.v!;
    var value = values.valueOf(key);
    var max = key == contaktlyFormFieldMessage
        ? contaktlyFormMessageMaxLength
        : contaktlyFormShortMaxLength;
    if (value == null) {
      if (field.required.v!) {
        errors[key] = key == contaktlyFormFieldEmail
            ? strings.emailError
            : strings.requiredError;
      }
    } else if (value.length > max) {
      errors[key] = strings.tooLongErrorFor(max);
    } else if (key == contaktlyFormFieldEmail && !validateEmail(value)) {
      errors[key] = strings.emailError;
    } else if (key == contaktlyFormFieldSubject &&
        strings.subjectChoices.isNotEmpty &&
        !strings.subjectChoices.contains(value)) {
      // Not one of the choices.
      errors[key] = strings.requiredError;
    }
  }
  var filesError = _filesError(form, values.files, strings);
  if (filesError != null) {
    errors[contaktlyFormFilesKey] = filesError;
  }
  return errors;
}

/// The first error of [files] in [form], null when none.
String? _filesError(
  ContaktlyFormMixin form,
  List<ContaktlyFormFile> files,
  ContaktlyFormStrings strings,
) {
  if (files.isEmpty) {
    return null;
  }
  if (files.length > form.maxFileCount) {
    return strings.fileError;
  }
  var types = form.fileTypesOrDefault;
  var maxFileSize = form.maxFileSizeOrDefault;
  var total = 0;
  for (var file in files) {
    var type = contaktlyFormFileTypeOf(file.name, file.bytes);
    if (type == null || !types.contains(type)) {
      return strings.fileTypeErrorFor(file.name);
    }
    if (file.size > maxFileSize) {
      return strings.fileTooBigErrorFor(file.name, maxFileSize);
    }
    total += file.size;
  }
  if (total > contaktlyFormFilesMaxSize) {
    return strings.filesTooBigErrorFor(contaktlyFormFilesMaxSize);
  }
  return null;
}

/// True when [values] look sent by a robot: the [ContaktlyFormValues.honeypot]
/// filled, or sent within [contaktlyFormMinFillDuration] of
/// [ContaktlyFormValues.shownAt]. The form then acts as if sent and sends
/// nothing.
bool contaktlyFormIsLikelySpam(ContaktlyFormValues values, {DateTime? now}) {
  if (values.honeypot?.trim().isNotEmpty ?? false) {
    return true;
  }
  var shownAt = values.shownAt;
  if (shownAt != null) {
    var elapsed = (now ?? DateTime.now()).difference(shownAt);
    if (elapsed < contaktlyFormMinFillDuration) {
      return true;
    }
  }
  return false;
}

/// The mail subject of [values]: `[<subjectTag>] ` then the subject, or the
/// name, or the email, or the form name.
String contaktlyFormMailSubject(
  ContaktlyFormMixin form,
  ContaktlyFormValues values,
) {
  var tag = form.subjectTag.v?.trim();
  var subject =
      values.valueOf(contaktlyFormFieldSubject) ??
      values.valueOf(contaktlyFormFieldName) ??
      values.valueOf(contaktlyFormFieldEmail) ??
      form.name.v ??
      'Contact form';
  return (tag == null || tag.isEmpty) ? subject : '[$tag] $subject';
}

/// The mail text of [values]: the name, email and subject lines given, a
/// blank line, the message.
String contaktlyFormMailText(ContaktlyFormValues values) {
  var name = values.valueOf(contaktlyFormFieldName);
  var email = values.valueOf(contaktlyFormFieldEmail);
  var subject = values.valueOf(contaktlyFormFieldSubject);
  return [
    if (name != null) 'Name: $name',
    if (email != null) 'Email: $email',
    if (subject != null) 'Subject: $subject',
    '',
    values.valueOf(contaktlyFormFieldMessage) ?? '',
  ].join('\n');
}

/// The message of [values] as the backend receives it: the visitor as the
/// reply-to, the subject and the text. The service decides the sender and
/// the recipients.
ApiMailMessage contaktlyFormMailMessage(
  ContaktlyFormMixin form,
  ContaktlyFormValues values,
) {
  var visitor = ApiMailRecipient()
    ..email.v = values.valueOf(contaktlyFormFieldEmail)
    ..name.v = values.valueOf(contaktlyFormFieldName);
  return ApiMailMessage()
    ..from.v = visitor
    ..replyTo.v = [visitor]
    ..subject.v = contaktlyFormMailSubject(form, values)
    ..text.v = contaktlyFormMailText(values);
}
