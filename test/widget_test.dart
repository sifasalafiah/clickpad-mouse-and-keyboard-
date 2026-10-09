import 'package:flutter_test/flutter_test.dart';
import 'package:clickpad/main.dart';
import 'package:clickpad/services/settings_service.dart';
import 'package:clickpad/services/connection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('ClickPadApp loads OnboardingScreen on fresh install', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    ConnectionService.instance.init();

    await tester.pumpWidget(const ClickPadApp());
    await tester.pump(const Duration(seconds: 9));

    expect(find.text('ClickPad'), findsOneWidget);
    expect(find.text('Use Phone as a Mouse'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('ClickPadApp loads BluetoothPairingScreen when already onboarded', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    await SettingsService.instance.init();
    ConnectionService.instance.init();

    await tester.pumpWidget(const ClickPadApp());
    await tester.pump(const Duration(seconds: 9));

    expect(find.text('ClickPad'), findsOneWidget);
    expect(find.text('PC Mouse & Keyboard'), findsOneWidget);
  });

  testWidgets('Completing onboarding transitions to pairing screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    ConnectionService.instance.init();

    await tester.pumpWidget(const ClickPadApp());
    await tester.pump(const Duration(seconds: 9));

    // Initially on Slide 1
    expect(find.text('Use Phone as a Mouse'), findsOneWidget);

    // Tap "Skip" to complete immediately
    await tester.tap(find.text('Skip'));
    await tester.pump(const Duration(milliseconds: 500));

    // Now should be on BluetoothPairingScreen
    expect(find.text('PC Mouse & Keyboard'), findsOneWidget);
    expect(SettingsService.instance.hasSeenOnboarding, isTrue);
  });
}
