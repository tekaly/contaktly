import 'dart:convert';

import 'package:cv/cv.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/hash.dart';
import 'package:tekartik_mail_tk/mail_contaktly.dart'
    show TkmailClientContaktly;
import 'package:tekartik_mail_tk/mail_tk_contaklty.dart'
    show
        ApiGetTimestampRequestContaktly,
        ApiSendMailQueryContaktly,
        ApiSendMailRequestContaktly,
        commandContaktlySendEmail;

import 'contaktly_constants.dart';
import 'form_files.dart';
import 'form_message.dart';
import 'form_model.dart';
import 'form_sender.dart';

/// The get timestamp command (`tekartik_mail_tk` keeps it private).
const _commandGetTimestamp = 'timestamp';

/// The send query of a form: the contaktly one, plus the form id (signed
/// when set, see [contaktlySignedPaths]) and the files (not signed).
class ContaktlyFormSendQuery extends ApiSendMailQueryContaktly {
  /// A query, the models of its files registered.
  ContaktlyFormSendQuery() {
    initContaktlyFormBuilders();
  }

  /// The form the message comes from.
  final formId = CvField<String>(contaktlyFormIdPath);

  /// The files of the message, for a form taking files.
  final files = CvModelListField<CvContaktlyFormSendFile>('files');

  @override
  CvFields get fields => [...super.fields, formId, files];
}

/// Sends the messages of a published form to the contaktly Dart backend,
/// from any runtime (JavaScript, Flutter, the VM): the server time, then
/// the message signed with the form's service.
///
/// The enc password of the published form is public by construction (it
/// is in its `form.json`): the backend protects the service (its sender and
/// recipients fixed, its limits).
class ContaktlyServiceSender implements ContaktlyFormSender {
  /// The published form: its id, app, service signature.
  final CvContaktlyFormPublished published;

  /// The command function, the Dart backend of the form's app by default.
  final Uri commandUrl;

  late final TkmailClientContaktly _client;

  /// A sender of [published], [client] for tests.
  ContaktlyServiceSender({
    required this.published,
    Uri? commandUrl,
    http.Client? client,
  }) : commandUrl =
           commandUrl ?? contaktlyCommandUrlDart(published.app.v ?? '') {
    initContaktlyFormBuilders();
    _client = TkmailClientContaktly(
      uri: this.commandUrl,
      app: published.app.v!,
      client: client,
    );
  }

  ContaktlyFormMixin get _form => published.form.v!;

  /// A new query, filled then signed by [query].
  @protected
  ContaktlyFormSendQuery newQuery() => ContaktlyFormSendQuery();

  /// The signed paths of [query]: the service's, then the form id when it
  /// has one.
  @protected
  List<String> signedPaths(ContaktlyFormSendQuery query) =>
      contaktlySignedPaths(
        published.encPaths.v ?? contaktlyFormDefaultEncPaths,
        formId: query.formId.v,
      );

  /// The signed send query of [values] at the server [timestamp].
  ContaktlyFormSendQuery query(
    ContaktlyFormValues values, {
    required String timestamp,
  }) {
    var query = newQuery()
      ..timestamp.v = timestamp
      ..serviceId.v = _form.serviceId.v
      ..message.v = contaktlyFormMailMessage(_form, values);
    // Only when set: a null still goes out as a key.
    var formId = published.formId.v;
    if (formId != null) {
      query.formId.v = formId;
    }
    if (values.files.isNotEmpty) {
      query.files.v = [
        for (var file in values.files)
          CvContaktlyFormSendFile()
            ..name.v = file.name
            ..type.v =
                contaktlyFormFileTypeOf(file.name, file.bytes) ?? file.type
            ..data.v = base64Encode(file.bytes),
      ];
    }
    var hashed = signedPaths(
      query,
    ).map((path) => query.valueAtPath(keyPartsFromString(path))).toList();
    query.enc.v = aesEncrypt(
      md5Hash(jsonEncode(hashed)),
      published.encPassword.v!,
    );
    return query;
  }

  /// Sends [values]: the server timestamp, then the signed message.
  @override
  Future<ContaktlyFormSendResult> send(ContaktlyFormValues values) async {
    var app = published.app.v!;
    var timestamp = (await _client.getTimestamp(
      ApiGetTimestampRequestContaktly()
        ..app.v = app
        ..command.v = _commandGetTimestamp,
    )).timestamp.v!;
    var request = ApiSendMailRequestContaktly()
      ..app.v = app
      ..command.v = commandContaktlySendEmail
      ..query.v = query(values, timestamp: timestamp);
    var response = asModel(await _client.send(commandUrl, request.toMap()));
    var error = response['error'];
    if (error is Map) {
      throw ContaktlyFormSendException(
        code: error['code']?.toString(),
        message: error['message']?.toString(),
      );
    }
    var result = response['result'];
    var map = result is Map ? result : const <String, Object?>{};
    return ContaktlyFormSendResult(
      status: map['status']?.toString(),
      mailId: map['mailId']?.toString(),
      messageId: map['messageId']?.toString(),
    );
  }

  /// Closes the http client.
  void close() => _client.close();
}
