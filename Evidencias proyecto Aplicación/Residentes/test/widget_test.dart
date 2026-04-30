import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:residentes/main.dart';

void main() {
  testWidgets('Verificar flujo de registro responsivo', (WidgetTester tester) async {
    // Iniciar la app
    await tester.pumpWidget(const FireDataApp());

    // 1. Ir a Registro desde Login
    final registerLink = find.text('¿No tienes cuenta? Regístrate aquí');
    expect(registerLink, findsOneWidget);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    // 2. Validar Paso 1: Crear Cuenta
    expect(find.text('Configuración inicial'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);

    // Ir a Paso 2 (Botón "Crear Cuenta" en el formulario del Paso 1)
    final createAccountButton = find.widgetWithText(ElevatedButton, 'Crear Cuenta');
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    // 3. Validar Paso 2: Datos del Titular
    expect(find.text('Datos del Titular'), findsAtLeast(1));
    expect(find.text('RUT (Titular)'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    
    // Verificar que existen las secciones de condiciones médicas
    expect(find.text('Enfermedades Crónicas'), findsOneWidget);
    expect(find.text('Movilidad y Sentidos'), findsOneWidget);

    // Botón Continuar en Paso 2
    expect(find.widgetWithText(ElevatedButton, 'Continuar'), findsOneWidget);
  });
}
