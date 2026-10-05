import 'package:flutter_test/flutter_test.dart';
import 'package:mouse_and_keyboard_for_desktop/main.dart';
import 'package:mouse_and_keyboard_for_desktop/services/settings_service.dart';
import 'package:mouse_and_keyboard_for_desktop/services/connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('DeskRemoteApp loads successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    ConnectionService.instance.init();

    await tester.pumpWidget(const DeskRemoteApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('DeskRemote'), findsOneWidget);
    expect(find.text('Bluetooth Hardware Remote'), findsOneWidget);
  });
}
