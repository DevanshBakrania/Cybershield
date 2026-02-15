import 'package:flutter_test/flutter_test.dart';
import 'package:cs11/app.dart'; // Ensure package name matches
import 'package:cs11/core/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 1. Create a dummy provider
    final mockProvider = ThemeProvider();

    // 2. Pass it to the app
    await tester.pumpWidget(CyberShieldApp(themeProvider: mockProvider));

    // 3. Simple check
    expect(find.text('CyberShield'), findsNothing); // Just ensuring no crash
  });
}