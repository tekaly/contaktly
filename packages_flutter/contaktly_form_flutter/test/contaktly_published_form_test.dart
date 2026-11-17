import 'dart:convert';

import 'package:contaktly_form_flutter/contaktly_form_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'example_form.dart';

void main() {
  final client = MockClient((request) async {
    if (request.url.path == '/f/example/form.json') {
      return http.Response.bytes(
        utf8.encode(jsonEncode(exampleFormPublished().toMap())),
        200,
      );
    }
    return http.Response('{}', 404);
  });

  Future<void> pumpForm(WidgetTester tester, String path) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ContaktlyPublishedForm(
              url: Uri.parse('https://forms.example.com$path'),
              lang: 'fr',
              client: client,
              loadingBuilder: (_) => const Text('Loading'),
              errorBuilder: (_, error) => Text('Failed: $error'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('loaded, in its language', (tester) async {
    await tester.runAsync(() => pumpForm(tester, '/f/example/form.json'));
    expect(find.text('Loading'), findsOneWidget);
    for (var i = 0; i < 10 && find.text('Loading').evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('Écrivez-nous'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
  });

  testWidgets('not found', (tester) async {
    await tester.runAsync(() => pumpForm(tester, '/f/none/form.json'));
    for (var i = 0; i < 10 && find.text('Loading').evaluate().isNotEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.textContaining('Failed: Bad state'), findsOneWidget);
  });
}
