import 'form_message.dart';
import 'form_texts.dart';

/// The stored status of a trial message: kept in the inbox, never mailed
/// (a status the backend may answer).
const contaktlyMailStatusTrial = 'trial';

/// The answer to a message.
class ContaktlyFormSendResult {
  /// `stored`, `sent`, `failed` or [contaktlyMailStatusTrial].
  final String? status;

  /// The stored mail id, null when the service only sends.
  final String? mailId;

  /// The provider message id, or the mail id when not sent.
  final String? messageId;

  /// The answer.
  ContaktlyFormSendResult({this.status, this.mailId, this.messageId});

  @override
  String toString() =>
      'ContaktlyFormSendResult($status, mail $mailId, message $messageId)';
}

/// Sends the messages of a form: the contaktly backend
/// (`ContaktlyServiceSender`), a simulation ([ContaktlySimulatedSender]), a
/// function of yours ([ContaktlyFunctionSender]) or any implementation.
///
/// A refusal throws, a [ContaktlyFormSendException] for the ones a form
/// explains (closed, limited).
abstract interface class ContaktlyFormSender {
  /// Sends [values], valid ones.
  Future<ContaktlyFormSendResult> send(ContaktlyFormValues values);
}

/// A sender calling [onSend].
class ContaktlyFunctionSender implements ContaktlyFormSender {
  /// Sends a message.
  final Future<ContaktlyFormSendResult> Function(ContaktlyFormValues values)
  onSend;

  /// A sender calling [onSend].
  ContaktlyFunctionSender(this.onSend);

  @override
  Future<ContaktlyFormSendResult> send(ContaktlyFormValues values) =>
      onSend(values);
}

/// The error code of a form whose service no longer takes messages.
const contaktlyFormErrorCodeClosed = 'failed-precondition';

/// The error message of a form whose service no longer takes messages
/// (expired, deleted, blocked, disabled), with
/// [contaktlyFormErrorCodeClosed].
const contaktlyFormErrorClosed = 'closed';

/// The error code of a message over the limits of the form.
const contaktlyFormErrorCodeLimited = 'resource-exhausted';

/// The backend refused a message (unknown service, bad signature, old
/// timestamp, closed, limited...).
class ContaktlyFormSendException implements Exception {
  /// The error code (`not-found`, `invalid-argument`...).
  final String? code;

  /// The error message.
  final String? message;

  /// A refusal.
  ContaktlyFormSendException({this.code, this.message});

  /// The service of the form no longer takes messages.
  bool get isClosed =>
      code == contaktlyFormErrorCodeClosed &&
      message == contaktlyFormErrorClosed;

  /// Over the limits of the form, for now.
  bool get isLimited => code == contaktlyFormErrorCodeLimited;

  @override
  String toString() => 'ContaktlyFormSendException($code: $message)';
}

/// The error text of [error], a failed send: closed, limited, or the
/// form's own.
String contaktlyFormSendErrorText(Object error, ContaktlyFormStrings strings) =>
    switch (error) {
      ContaktlyFormSendException(isClosed: true) => strings.closedError,
      ContaktlyFormSendException(isLimited: true) => strings.limitedError,
      _ => strings.error,
    };

/// What a [ContaktlySimulatedSender] answers.
enum ContaktlyFormSimulation {
  /// Sent.
  sent,

  /// A trial, stored, never mailed.
  trial,

  /// Refused: the form's service is closed (expired, deleted, blocked).
  closed,

  /// Refused: too many messages for now.
  limited,

  /// Not sent: any other error.
  error,
}

/// The simulation named [name] (`closed`...), null for none or an unknown
/// name.
ContaktlyFormSimulation? contaktlyFormSimulationParse(String? name) {
  for (var simulation in ContaktlyFormSimulation.values) {
    if (simulation.name == name) {
      return simulation;
    }
  }
  return null;
}

/// The time a simulated send takes, so that the sending state shows.
const contaktlyFormSimulationDelay = Duration(milliseconds: 600);

/// What a send answers with [simulate], after [delay], without a request:
/// the result, or the [ContaktlyFormSendException] of a refusal.
Future<ContaktlyFormSendResult> contaktlyFormSimulatedSend(
  ContaktlyFormSimulation simulate, {
  Duration delay = contaktlyFormSimulationDelay,
}) async {
  await Future<void>.delayed(delay);
  switch (simulate) {
    case ContaktlyFormSimulation.sent:
      return ContaktlyFormSendResult(status: 'sent', messageId: 'simulated');
    case ContaktlyFormSimulation.trial:
      return ContaktlyFormSendResult(
        status: contaktlyMailStatusTrial,
        mailId: 'simulated',
        messageId: 'simulated',
      );
    case ContaktlyFormSimulation.closed:
      throw ContaktlyFormSendException(
        code: contaktlyFormErrorCodeClosed,
        message: contaktlyFormErrorClosed,
      );
    case ContaktlyFormSimulation.limited:
      throw ContaktlyFormSendException(
        code: contaktlyFormErrorCodeLimited,
        message: 'Too many in an hour',
      );
    case ContaktlyFormSimulation.error:
      throw ContaktlyFormSendException(
        code: 'internal',
        message: 'Send failed',
      );
  }
}

/// A sender that never calls a server: it answers what [simulation] says
/// after [delay] (tests, previews, a page tried before its form exists).
class ContaktlySimulatedSender implements ContaktlyFormSender {
  /// The answer.
  final ContaktlyFormSimulation simulation;

  /// The time a send takes.
  final Duration delay;

  /// The values of each send, the last one last.
  final sent = <ContaktlyFormValues>[];

  /// A sender answering [simulation].
  ContaktlySimulatedSender(
    this.simulation, {
    this.delay = contaktlyFormSimulationDelay,
  });

  @override
  Future<ContaktlyFormSendResult> send(ContaktlyFormValues values) {
    sent.add(values);
    return contaktlyFormSimulatedSend(simulation, delay: delay);
  }
}
