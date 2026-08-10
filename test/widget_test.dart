import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homecare_app/main.dart';

void main() {
  testWidgets('shows the authentication screen when no session is stored', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: HomeCareApp()));
    await tester.pumpAndSettle();
    expect(find.text('HomeCare'), findsWidgets);
  });
}
