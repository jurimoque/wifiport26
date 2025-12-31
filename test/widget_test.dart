// WiFiPort widget tests

import 'package:flutter_test/flutter_test.dart';
import 'package:wifiport/main.dart';

void main() {
  testWidgets('WiFiPort app loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WiFiPortApp());

    // Allow time for initial build
    await tester.pumpAndSettle();

    // Verify we can find the app title
    expect(find.text('WiFiPort'), findsOneWidget);
    
    // Verify the main buttons are present
    expect(find.text('Emitir Audio'), findsOneWidget);
    expect(find.text('Escuchar Audio'), findsOneWidget);
  });
}
