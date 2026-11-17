import 'dart:convert';
import 'dart:typed_data';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:test/test.dart';

import 'example_form.dart';

const _docx =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

Uint8List _bytes(List<int> start, [int size = 0]) {
  var bytes = Uint8List(size > start.length ? size : start.length);
  bytes.setAll(0, start);
  return bytes;
}

final _pdf = _bytes(ascii.encode('%PDF-1.7 a cv'));
final _png = _bytes([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0]);
final _zip = _bytes([0x50, 0x4b, 0x03, 0x04, 0]);

/// [exampleForm] taking [maxFiles] files, [shownFiles] shown.
CvContaktlyForm _filesForm({
  int? maxFiles = 1,
  int? shownFiles,
  int? maxFileSize,
  List<String>? types,
}) {
  var attachments = CvContaktlyFormAttachments();
  // Only the ones given: a null still goes out as a key.
  for (var (field, value) in [
    (attachments.maxFiles, maxFiles),
    (attachments.shownFiles, shownFiles),
    (attachments.maxFileSize, maxFileSize),
  ]) {
    if (value != null) {
      field.v = value;
    }
  }
  if (types != null) {
    attachments.types.v = types;
  }
  return exampleForm()..attachments.v = attachments;
}

void main() {
  initContaktlyFormBuilders();
  group('files', () {
    test('types', () {
      expect(contaktlyFormFileTypeOf('cv.pdf', _pdf), 'application/pdf');
      // The content, not the name.
      expect(contaktlyFormFileTypeOf('cv.docx', _pdf), 'application/pdf');
      expect(contaktlyFormFileTypeOf('a', _png), 'image/png');
      expect(
        contaktlyFormFileTypeOf('a', _bytes([0xff, 0xd8, 0xff])),
        'image/jpeg',
      );
      expect(
        contaktlyFormFileTypeOf('a.gif', _bytes(ascii.encode('GIF89a'))),
        'image/gif',
      );
      expect(
        contaktlyFormFileTypeOf(
          'a',
          _bytes([
            ...ascii.encode('RIFF'),
            0,
            0,
            0,
            0,
            ...ascii.encode('WEBP'),
          ]),
        ),
        'image/webp',
      );
      // A zip: a document by its extension.
      expect(contaktlyFormFileTypeOf('CV.DOCX', _zip), _docx);
      expect(
        contaktlyFormFileTypeOf('a.ods', _zip),
        'application/vnd.oasis.opendocument.spreadsheet',
      );
      expect(contaktlyFormFileTypeOf('a.zip', _zip), isNull);
      expect(contaktlyFormFileTypeOf('a.pdf', _zip), isNull);
      expect(contaktlyFormFileTypeOf('a.docm', _zip), isNull);
      expect(contaktlyFormFileTypeOf('a.docx', _pdf.sublist(0, 2)), isNull);
      expect(contaktlyFormFileTypeOf('a.svg', utf8.encode('<svg/>')), isNull);
      expect(contaktlyFormFileTypeOf('a', Uint8List(0)), isNull);
      expect(contaktlyFormFileTypes.length, 11);
      expect(contaktlyFormFileExtensions(['image/jpeg', 'application/pdf']), [
        'jpg',
        'pdf',
        'jpeg',
      ]);
      expect(
        contaktlyFormFileAccept(['image/jpeg', 'application/pdf']),
        'image/jpeg,application/pdf,.jpg,.pdf,.jpeg',
      );
    });
    test('form', () {
      var form = exampleForm();
      expect(form.takesFiles, isFalse);
      expect(form.maxFileCount, 0);
      expect(form.shownFileCount, 0);
      form = _filesForm(maxFiles: null);
      expect(form.takesFiles, isTrue);
      expect(form.maxFileCount, 1);
      expect(form.shownFileCount, 1);
      form = _filesForm(shownFiles: 3);
      expect(form.maxFileCount, 1);
      expect(form.shownFileCount, 3);
      form = _filesForm(maxFiles: 3, shownFiles: 1);
      expect(form.shownFileCount, 3);
      expect(_filesForm(maxFiles: 0).takesFiles, isFalse);
      expect(form.maxFileSizeOrDefault, contaktlyFormFileMaxSize);
      expect(form.fileTypesOrDefault, contaktlyFormFileTypes.keys.toList());
      // Less, never more.
      form = _filesForm(
        maxFileSize: 1000,
        types: ['application/pdf', 'text/html'],
      );
      expect(form.maxFileSizeOrDefault, 1000);
      expect(form.fileTypesOrDefault, ['application/pdf']);
      expect(
        _filesForm(
          maxFileSize: contaktlyFormFileMaxSize * 2,
        ).maxFileSizeOrDefault,
        contaktlyFormFileMaxSize,
      );
      // Round trip.
      var map = _filesForm(maxFiles: 3, shownFiles: 3).toMap();
      expect(map['attachments'], {'maxFiles': 3, 'shownFiles': 3});
      expect((CvContaktlyForm()..fromMap(map)).maxFileCount, 3);
    });
    test('strings', () {
      var en = contaktlyFormStringsEn;
      expect(en.sizeText(5 * 1024 * 1024), '5 MB');
      expect(en.sizeText(1536 * 1024), '1.5 MB');
      expect(en.sizeText(2048), '2 KB');
      expect(en.sizeText(12), '12 B');
      expect(contaktlyFormStringsFr.sizeText(1536 * 1024), '1,5 Mo');
      expect(
        en.filesHelpFor(['image/png', 'application/pdf'], 5 * 1024 * 1024),
        'PNG, PDF, 5 MB at most per file',
      );
      expect(
        contaktlyFormStringsFr.filesHelpFor([_docx], 1024 * 1024),
        'DOCX, 1 Mo au plus par fichier',
      );
      expect(
        en.fileTypeErrorFor('a.zip'),
        'a.zip: this type of file is not taken',
      );
      expect(en.fileTooBigErrorFor('a.pdf', 1024), 'a.pdf: 1 KB at most');
      expect(en.filesTooBigErrorFor(10 * 1024 * 1024), '10 MB at most in all');
      expect(
        en.copyWith(filesLocked: 'More files with a plan').filesLocked,
        'More files with a plan',
      );
      // The form's own labels.
      var form = _filesForm()
        ..texts.v = [
          CvContaktlyFormTexts()
            ..lang.v = 'en'
            ..filesLabel.v = 'Your CV'
            ..filesHelp.v = 'A PDF',
        ];
      var strings = contaktlyFormStrings(form, 'en');
      expect(strings.filesLabel, 'Your CV');
      expect(strings.filesHelp, 'A PDF');
      expect(contaktlyFormStrings(form, 'fr').filesLabel, 'Fichiers');
    });
    test('validate', () {
      const strings = contaktlyFormStringsEn;
      ContaktlyFormValues values(List<ContaktlyFormFile> files) =>
          ContaktlyFormValues(
            name: 'Ana',
            email: 'ana@example.com',
            message: 'Hello',
            files: files,
          );
      Map<String, String> errors(
        CvContaktlyForm form,
        List<ContaktlyFormFile> files,
      ) => contaktlyFormValidate(form, values(files), strings);
      var pdf = ContaktlyFormFile(name: 'cv.pdf', bytes: _pdf);
      expect(errors(_filesForm(), [pdf]), isEmpty);
      expect(errors(_filesForm(), []), isEmpty);
      // A form without files, too many.
      expect(errors(exampleForm(), [pdf]), {
        contaktlyFormFilesKey: strings.fileError,
      });
      expect(errors(_filesForm(shownFiles: 3), [pdf, pdf]), {
        contaktlyFormFilesKey: strings.fileError,
      });
      expect(errors(_filesForm(maxFiles: 2), [pdf, pdf]), isEmpty);
      // A type not taken.
      var zip = ContaktlyFormFile(name: 'a.zip', bytes: _zip);
      expect(errors(_filesForm(), [zip]), {
        contaktlyFormFilesKey: 'a.zip: this type of file is not taken',
      });
      var png = ContaktlyFormFile(name: 'a.png', bytes: _png);
      expect(errors(_filesForm(types: ['application/pdf']), [png]), {
        contaktlyFormFilesKey: 'a.png: this type of file is not taken',
      });
      // Too big, each, in all.
      expect(errors(_filesForm(maxFileSize: 10), [pdf]), {
        contaktlyFormFilesKey: 'cv.pdf: 10 B at most',
      });
      var big = ContaktlyFormFile(
        name: 'big.pdf',
        bytes: _bytes(_pdf, 4 * 1024 * 1024),
      );
      expect(errors(_filesForm(maxFiles: 3), [big, big]), isEmpty);
      expect(errors(_filesForm(maxFiles: 3), [big, big, big]), {
        contaktlyFormFilesKey: '10 MB at most in all',
      });
    });
    test('controller', () async {
      var sent = <ContaktlyFormValues>[];
      var controller = ContaktlyFormController(
        form: _filesForm(maxFiles: 2),
        sender: ContaktlyFunctionSender((values) async {
          sent.add(values);
          return ContaktlyFormSendResult(status: 'stored');
        }),
        spamCheck: false,
      );
      var changes = 0;
      controller.addListener(() => changes++);
      controller
        ..setValue(contaktlyFormFieldName, 'Ana')
        ..setValue(contaktlyFormFieldEmail, 'ana@example.com')
        ..setValue(contaktlyFormFieldMessage, 'Hello');
      var zip = ContaktlyFormFile(name: 'a.zip', bytes: _zip);
      controller.addFile(zip);
      expect(changes, 1);
      expect(await controller.submit(), isNull);
      expect(controller.errorOf(contaktlyFormFilesKey), contains('a.zip'));
      controller.removeFile(0);
      // Its error gone.
      expect(controller.errors, isEmpty);
      var pdf = ContaktlyFormFile(name: 'cv.pdf', bytes: _pdf);
      controller
        ..addFile(pdf)
        ..addFile(pdf);
      expect(controller.files, [pdf, pdf]);
      expect(await controller.submit(), isNotNull);
      expect(sent.single.files, [pdf, pdf]);
      controller.another();
      expect(controller.files, isEmpty);
      expect(controller.values.files, isEmpty);
      controller.dispose();
    });
    test('send', () {
      var published = exampleFormPublished()..form.v = _filesForm();
      var sender = ContaktlyServiceSender(published: published);
      var values = ContaktlyFormValues(
        name: 'Ana',
        email: 'ana@example.com',
        message: 'Hello',
        files: [
          ContaktlyFormFile(name: 'cv.pdf', type: 'text/plain', bytes: _pdf),
        ],
      );
      var query = sender.query(values, timestamp: '2026-10-22T12:00:00Z');
      expect(query.toMap()['files'], [
        {
          'name': 'cv.pdf',
          // Read on the content.
          'type': 'application/pdf',
          'data': base64Encode(_pdf),
        },
      ]);
      // Not signed: the same signature without them.
      var withoutFiles = sender.query(
        const ContaktlyFormValues(
          name: 'Ana',
          email: 'ana@example.com',
          message: 'Hello',
        ),
        timestamp: '2026-10-22T12:00:00Z',
      );
      expect(withoutFiles.toMap().containsKey('files'), isFalse);
      expect(
        aesDecrypt(query.enc.v!, exampleFormEncPassword),
        aesDecrypt(withoutFiles.enc.v!, exampleFormEncPassword),
      );
      sender.close();
      // The backend refusing them.
      for (var message in ['File type', 'File too big', 'Too many files']) {
        expect(
          contaktlyFormSendErrorText(
            ContaktlyFormSendException(
              code: 'invalid-argument',
              message: message,
            ),
            contaktlyFormStringsEn,
          ),
          contaktlyFormStringsEn.fileError,
        );
      }
      expect(
        contaktlyFormSendErrorText(
          ContaktlyFormSendException(
            code: 'resource-exhausted',
            message: 'Too many files today',
          ),
          contaktlyFormStringsEn,
        ),
        contaktlyFormStringsEn.limitedError,
      );
    });
  });
}
