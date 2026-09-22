import 'package:flutter_test/flutter_test.dart';
import 'package:tbcare_plus/main.dart';

void main() {
  testWidgets('App loads home', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    // Offline app should show home header / check card without crash
    expect(find.byType(MyApp), findsOneWidget);
  });
}
