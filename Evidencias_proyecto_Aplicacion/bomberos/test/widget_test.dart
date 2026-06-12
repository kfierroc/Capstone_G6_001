import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bomberos/login/login_screen.dart';

void main() {
  testWidgets('Login muestra encabezado de bomberos', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );
    expect(find.text('App Bomberos'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
