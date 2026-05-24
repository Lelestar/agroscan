import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agroscan/app.dart';

void main() {
  testWidgets('Home screen shows main CTA', (WidgetTester tester) async {
    WidgetsBinding.instance.deferFirstFrame();
    await tester.pumpWidget(
      const ProviderScope(child: AgroScanApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Diagnostiquer une feuille'), findsOneWidget);
    expect(find.text('Scanner une feuille'), findsOneWidget);
  });
}
