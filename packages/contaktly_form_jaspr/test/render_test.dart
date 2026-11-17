/// Renders the components on the server, as a site build does.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:contaktly_form/contaktly_form.dart';
import 'package:contaktly_form_jaspr/server.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

import 'example_form.dart';

/// What jaspr_builder generates in a site using the component.
ServerOptions get _options => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    ContaktlyFormIsland: ClientTarget<ContaktlyFormIsland>(
      'contaktly_form_jaspr:form_island',
      params: (island) => {
        'published': island.published,
        'lang': island.lang,
        'commandUrl': island.commandUrl,
      },
    ),
  },
);

/// The island data of a rendered page.
Map<String, Object?> _islandData(String body) {
  var match = RegExp(
    r'<!--@contaktly_form_jaspr:form_island data=(.*?)-->',
  ).firstMatch(body)!;
  return jsonDecode(match.group(1)!) as Map<String, Object?>;
}

void main() {
  setUpAll(() {
    Jaspr.initializeApp(options: _options);
  });

  testServer('the component in a page of another site', (tester) async {
    tester.pumpComponent(
      ContaktlyContactForm(
        published: exampleFormPublished(),
        lang: 'fr',
        commandUrl: '/api/command',
      ),
    );
    var response = await tester.request('/');
    var document = response.document!;
    var root = document.querySelector('.cf-root')!;
    expect(root.querySelector('style')!.text, contains('.cf-root {'));
    expect(root.querySelector('.cf-card h1')?.text, 'Écrivez-nous');
    expect(document.querySelectorAll('.cf-field'), hasLength(4));
    expect(document.querySelector('.cf-hp input'), isNotNull);
    // Enabled once hydrated only.
    expect(document.querySelector('.cf-button')?.attributes['disabled'], '');
    var data = _islandData(response.body);
    expect(data['lang'], 'fr');
    expect(data['commandUrl'], '/api/command');
    expect((data['published'] as Map)['formId'], 'example');
  });

  testServer('without its title, texts adapted', (tester) async {
    tester.pumpComponent(
      ContaktlyContactForm(
        published: exampleFormPublished(),
        lang: 'fr',
        showTitle: false,
        strings: (strings) =>
            strings.copyWith(submit: 'Écrire', subjectChoices: ['A', 'B']),
      ),
    );
    var response = await tester.request('/');
    var document = response.document!;
    expect(document.querySelector('.cf-card h1'), isNull);
    expect(document.querySelector('.cf-intro')?.text, contains('Une question'));
    expect(document.querySelector('.cf-button')?.text, 'Écrire');
    var options = document.querySelectorAll('select#cf-subject option');
    expect(options.map((option) => option.text), ['—', 'A', 'B']);
    // The island gets the same texts.
    var published = _islandData(response.body)['published'] as Map;
    var texts = ((published['form'] as Map)['texts'] as List)
        .cast<Map>()
        .firstWhere((texts) => texts['lang'] == 'fr');
    expect(texts['submit'], 'Écrire');
    expect(texts['title'], '');
  });

  testServer('a user form: its owner', (tester) async {
    var published = exampleFormPublished();
    published.form.v!.profile.v = CvContaktlyFormProfile()
      ..name.v = 'Olivia Owner'
      ..pictureUrl.v = 'https://example.com/olivia.png';
    tester.pumpComponent(ContaktlyContactForm(published: published));
    var document = (await tester.request('/')).document!;
    expect(
      document.querySelector('.cf-root .cf-profile-name')?.text,
      'Olivia Owner',
    );
    var photo = document.querySelector('.cf-profile img')!;
    expect(photo.attributes['referrerpolicy'], 'no-referrer');
    expect(document.querySelector('.cf-cover'), isNull);
    tester.pumpComponent(
      ContaktlyContactForm(published: published, showProfile: false),
    );
    document = (await tester.request('/')).document!;
    expect(document.querySelector('.cf-profile'), isNull);
  });

  testServer('loaded from form.json', (tester) async {
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(exampleFormPublished().toMap()))
        ..close();
    });
    tester.pumpComponent(
      ContaktlyContactFormLoader(
        url: Uri.parse('http://127.0.0.1:${server.port}/f/example/form.json'),
        card: false,
      ),
    );
    var response = await tester.request('/');
    var document = response.document!;
    expect(document.querySelector('.cf-embed h1')?.text, 'Write to us');
  });

  testServer('the view posting without a script', (tester) async {
    tester.pumpComponent(
      ContaktlyContactFormView(
        form: exampleForm(),
        lang: 'en',
        action: '/contact/send',
        values: const {
          contaktlyFormFieldName: 'Ana',
          contaktlyFormFieldSubject: 'Hi',
        },
        hiddenFields: const {'t': '1234'},
      ),
    );
    var document = (await tester.request('/')).document!;
    var form = document.querySelector('form.cf-form')!;
    expect(form.attributes['action'], '/contact/send');
    expect(form.attributes['method'], 'post');
    expect(
      document.querySelector('.cf-button')?.attributes['disabled'],
      isNull,
    );
    expect(
      document.querySelector('.cf-hp input')?.attributes['name'],
      contaktlyFormHoneypotName,
    );
    expect(document.querySelector('#cf-name')?.attributes['value'], 'Ana');
    expect(document.querySelector('#cf-subject')?.attributes['value'], 'Hi');
    var hidden = document.querySelector('input[type="hidden"]')!;
    expect(hidden.attributes['name'], 't');
    expect(hidden.attributes['value'], '1234');
  });

  testServer('a form taking files: one input per file', (tester) async {
    var form = exampleForm()
      ..attachments.v = (CvContaktlyFormAttachments()
        ..maxFiles.v = 1
        ..shownFiles.v = 3
        ..types.v = ['application/pdf', 'image/png']);
    tester.pumpComponent(
      ContaktlyContactFormView(form: form, lang: 'en', action: '/send'),
    );
    var document = (await tester.request('/')).document!;
    expect(
      document.querySelector('form.cf-form')!.attributes['enctype'],
      'multipart/form-data',
    );
    var inputs = document.querySelectorAll('input[type="file"]');
    expect(inputs.map((input) => input.attributes['name']), [
      'file1',
      'file2',
      'file3',
    ]);
    // The ones past the max shown disabled.
    expect(inputs.map((input) => input.attributes.containsKey('disabled')), [
      false,
      true,
      true,
    ]);
    expect(
      inputs.first.attributes['accept'],
      'application/pdf,image/png,.pdf,.png',
    );
    expect(document.querySelector('label[for="cf-file1"]')?.text, 'Files');
    expect(
      document.querySelector('#cf-files-help')?.text,
      'PDF, PNG, 5 MB at most per file',
    );
    // Without files: none, urlencoded.
    tester.pumpComponent(
      ContaktlyContactFormView(form: exampleForm(), lang: 'en', action: '/s'),
    );
    document = (await tester.request('/')).document!;
    expect(document.querySelector('input[type="file"]'), isNull);
    expect(
      document.querySelector('form.cf-form')!.attributes['enctype'],
      isNull,
    );
  });

  test('the look in the css', () {
    var css = contaktlyFormCss(
      accent: '#00897b',
      radius: 4,
      brightness: 'dark',
      compact: true,
    );
    expect(css, contains('--cf-accent: #00897b;'));
    expect(css, contains('--cf-radius: 4px;'));
    expect(css, contains('color-scheme: dark;'));
    expect(css, isNot(contains('prefers-color-scheme')));
    expect(css, contains('.cf-card { padding: 16px; }'));
    var system = contaktlyFormCss();
    expect(system, contains('@media (prefers-color-scheme: dark)'));
    expect(system, contains('--cf-radius: 12px;'));
    var light = contaktlyFormCss(brightness: 'light');
    expect(light, contains('color-scheme: light;'));
    expect(light, isNot(contains('#1d1f25')));
  });

  test('scoped css: the variables on the root, no page rules', () {
    var css = contaktlyFormCss(root: '.cf-root', brightness: 'dark');
    expect(css, contains('.cf-root {\n  --cf-accent'));
    expect(css, contains('.cf-root, .cf-root * { box-sizing: border-box; }'));
    expect(css, isNot(contains(':root')));
    expect(css, isNot(contains('body')));
    // A page: its own page css.
    expect(
      contaktlyFormCss(pageCss: 'body { margin: 0; }'),
      contains('body {'),
    );
  });
}
