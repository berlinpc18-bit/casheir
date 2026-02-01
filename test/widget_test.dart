// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../lib/main.dart';
import '../lib/app_state.dart';

void main() {
  testWidgets('Cashier app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MyApp(),
      ),
    );

    // Verify that the app loads with the title.
    expect(find.text('BERLIN GAMING'), findsOneWidget);
    
    // Verify that the tabs are present.
    expect(find.text('Pc'), findsOneWidget);
    expect(find.text('Arabia'), findsOneWidget);
    expect(find.text('Tables'), findsOneWidget);
    expect(find.text('Reservation'), findsOneWidget);
  });
}
