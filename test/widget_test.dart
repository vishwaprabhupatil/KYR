// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kyy/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await Supabase.initialize(url: 'http://localhost', anonKey: 'anon');
    await tester.pumpWidget(const KyyApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('KYY – Know Your Rights'), findsWidgets);
  }, skip: true);
}
