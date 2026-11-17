import 'dart:convert';
import 'dart:typed_data';

import 'package:cv/cv.dart';

/// The size of a file at most, unless the form says less (the contaktly
/// backend's).
const contaktlyFormFileMaxSize = 5 * 1024 * 1024;

/// The size of the files of a message at most (the contaktly backend's).
const contaktlyFormFilesMaxSize = 10 * 1024 * 1024;

/// The key of the errors of the files (`ContaktlyFormController.errorOf`).
const contaktlyFormFilesKey = 'files';

/// The Word document type.
const _docx =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/// The Excel workbook type.
const _xlsx =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// The PowerPoint presentation type.
const _pptx =
    'application/vnd.openxmlformats-officedocument.presentationml.presentation';

/// The types a form may take, with their extension: images, PDF, Office
/// and OpenDocument documents (the contaktly backend refuses the ones with
/// macros).
const contaktlyFormFileTypes = <String, String>{
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
  'image/gif': 'gif',
  'application/pdf': 'pdf',
  _docx: 'docx',
  _xlsx: 'xlsx',
  _pptx: 'pptx',
  'application/vnd.oasis.opendocument.text': 'odt',
  'application/vnd.oasis.opendocument.spreadsheet': 'ods',
  'application/vnd.oasis.opendocument.presentation': 'odp',
};

/// The document types, zips.
const _documentTypes = [
  _docx,
  _xlsx,
  _pptx,
  'application/vnd.oasis.opendocument.text',
  'application/vnd.oasis.opendocument.spreadsheet',
  'application/vnd.oasis.opendocument.presentation',
];

/// The other extensions of a type.
const _otherExtensions = {'jpeg': 'image/jpeg'};

/// The type of the file [name] holding [bytes], one of
/// [contaktlyFormFileTypes], null for another: the images and PDF by their
/// first bytes, the documents (a zip) by their extension. A quick check
/// before sending; the contaktly backend reads the documents themselves.
String? contaktlyFormFileTypeOf(String name, Uint8List bytes) {
  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (bytes.length < offset + prefix.length) {
      return false;
    }
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[offset + i] != prefix[i]) {
        return false;
      }
    }
    return true;
  }

  if (startsWith([0xff, 0xd8, 0xff])) {
    return 'image/jpeg';
  }
  if (startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return 'image/png';
  }
  if (startsWith(ascii.encode('RIFF')) && startsWith(ascii.encode('WEBP'), 8)) {
    return 'image/webp';
  }
  if (startsWith(ascii.encode('GIF87a')) ||
      startsWith(ascii.encode('GIF89a'))) {
    return 'image/gif';
  }
  if (startsWith(ascii.encode('%PDF-'))) {
    return 'application/pdf';
  }
  if (startsWith([0x50, 0x4b, 0x03, 0x04])) {
    var dot = name.lastIndexOf('.');
    var extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    for (var type in _documentTypes) {
      if (contaktlyFormFileTypes[type] == extension) {
        return type;
      }
    }
  }
  return null;
}

/// The extensions of [types] (`jpg`, `pdf`...), each of
/// [contaktlyFormFileTypes] once.
List<String> contaktlyFormFileExtensions(Iterable<String> types) => [
  for (var type in types) ?contaktlyFormFileTypes[type],
  for (var MapEntry(key: extension, value: type) in _otherExtensions.entries)
    if (types.contains(type)) extension,
];

/// The `accept` attribute of a file input taking [types]: the types and
/// their extensions.
String contaktlyFormFileAccept(Iterable<String> types) => [
  ...types,
  for (var extension in contaktlyFormFileExtensions(types)) '.$extension',
].join(',');

/// A file picked by a visitor: its name, the type its picker gave (the
/// sender reads the content), its bytes.
class ContaktlyFormFile {
  /// The file name.
  final String name;

  /// The type its picker gave, empty when unknown.
  final String type;

  /// The bytes.
  final Uint8List bytes;

  /// A file.
  const ContaktlyFormFile({
    required this.name,
    this.type = '',
    required this.bytes,
  });

  /// Its size in bytes.
  int get size => bytes.length;

  @override
  String toString() => 'ContaktlyFormFile($name, $type, $size bytes)';
}

/// The files a form takes: none without (the default).
class CvContaktlyFormAttachments extends CvModelBase {
  /// The files of a message at most, 1 when null.
  final maxFiles = CvField<int>('maxFiles');

  /// The file fields shown, [maxFiles] when null or less: the ones past
  /// [maxFiles] are shown disabled (more files with a plan).
  final shownFiles = CvField<int>('shownFiles');

  /// The size of a file at most in bytes, [contaktlyFormFileMaxSize] when
  /// null.
  final maxFileSize = CvField<int>('maxFileSize');

  /// The types taken (`image/png`...), all of [contaktlyFormFileTypes] when
  /// empty.
  final types = CvListField<String>('types');

  @override
  CvFields get fields => [maxFiles, shownFiles, maxFileSize, types];
}

/// A file of a send query: its name, its type, its bytes in base64 (not
/// signed: the contaktly backend checks it).
class CvContaktlyFormSendFile extends CvModelBase {
  /// The file name.
  final name = CvField<String>('name');

  /// The type read on its first bytes, or the one its picker gave.
  final type = CvField<String>('type');

  /// The bytes, base64.
  final data = CvField<String>('data');

  @override
  CvFields get fields => [name, type, data];
}
