import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_reader/main.dart';

void main() {
  testWidgets('PDF Reader app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('PDF Reader'), findsOneWidget);
  });
}