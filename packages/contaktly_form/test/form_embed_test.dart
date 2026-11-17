import 'dart:convert';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'example_form.dart';

final _site = Uri.parse('https://forms.example.com');

void main() {
  test('urls', () {
    expect(
      '${contaktlyFormPageUrl(_site, 'example')}',
      'https://forms.example.com/f/example',
    );
    expect(
      '${contaktlyFormPageUrl(_site, 'example', lang: 'fr', embed: true)}',
      'https://forms.example.com/f/example/fr?embed=1',
    );
    expect(
      '${contaktlyFormJsonUrl(_site, 'example')}',
      'https://forms.example.com/f/example/form.json',
    );
  });

  test('load form.json', () async {
    var published = exampleFormPublished();
    var client = MockClient((request) async {
      if (request.url.path == '/f/example/form.json') {
        return http.Response.bytes(
          utf8.encode(jsonEncode(published.toMap())),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    var loaded = await contaktlyFormPublishedLoad(
      contaktlyFormJsonUrl(_site, 'example'),
      client: client,
    );
    expect(loaded.toMap(), published.toMap());
    expect(
      () => contaktlyFormPublishedLoad(
        contaktlyFormJsonUrl(_site, 'none'),
        client: client,
      ),
      throwsStateError,
    );
  });
}
