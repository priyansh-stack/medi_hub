import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medi_hub/core/theme/app_theme.dart';
import 'package:medi_hub/presentation/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders branding, heading, and action buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    bool registerTapped = false;
    bool loginTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: WelcomeScreen(
          onNavigateToRegister: () {
            registerTapped = true;
          },
          onNavigateToLogin: () {
            loginTapped = true;
          },
        ),
      ),
    );

    // Verify Heading matching splash mockup
    expect(find.text('Your Health. Under One Roof.'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    // Tap Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    expect(registerTapped, isTrue);

    // Tap Log In
    await tester.tap(find.text('Log In'));
    await tester.pump();
    expect(loginTapped, isTrue);
  });
}
