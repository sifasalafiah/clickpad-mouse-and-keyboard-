import 'package:flutter_test/flutter_test.dart';
import 'package:clickpad/main.dart';
import 'package:clickpad/services/settings_service.dart';
import 'package:clickpad/services/connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ClickPadApp loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    ConnectionService.instance.init();

    await tester.pumpWidget(const ClickPadApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('ClickPad'), findsOneWidget);
    expect(find.text('PC Mouse & Keyboard'), findsOneWidget);
  });
}
