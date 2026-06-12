import 'package:flutter_test/flutter_test.dart';

import 'package:starter_app/app/starter_app.dart';

void main() {
  testWidgets('shows setup message before Supabase config is provided',
      (tester) async {
    await tester.pumpWidget(const SetupRequiredApp());

    expect(find.text('Supabase config required'), findsOneWidget);
  });
}
