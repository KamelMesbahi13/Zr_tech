import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zr_tech_app/main.dart';

void main() {
  testWidgets('ZRTechApp renders ShoppingTypeScreen choices and Help dialog works', (WidgetTester tester) async {
    await tester.pumpWidget(const ZRTechApp());

    expect(find.text('ZR Technologie'), findsOneWidget);
    expect(find.text('اختر نوع التسوق'), findsOneWidget);
    expect(find.text('بالجملة'), findsOneWidget);
    expect(find.text('بالتجزئة'), findsOneWidget);

    // Tap the Help (?) icon button and verify the help dialog opens
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('حول طرق التسوق'), findsOneWidget);
    expect(find.text('حسناً'), findsOneWidget);

    // Dismiss the dialog
    await tester.tap(find.text('حسناً'));
    await tester.pumpAndSettle();

    expect(find.text('حول طرق التسوق'), findsNothing);
  });
}
