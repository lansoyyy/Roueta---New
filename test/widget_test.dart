import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roueta/main.dart';

void main() {
  testWidgets('RouetaApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RouetaApp());

    // Verify that the welcome text is displayed.
    expect(find.text('Welcome to Roueta'), findsOneWidget);
  });
}
