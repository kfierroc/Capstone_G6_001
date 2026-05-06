import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/maps_loader.dart';
import 'login/login_screen.dart';
import 'screens/gestion_familia.dart';
import 'screens/gestion_mascotas.dart';
import 'screens/gestion_domicilio.dart';
import 'screens/gestion_peligrosos.dart';
import 'screens/gestion_configuracion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  try {
    await loadGoogleMapsScript(dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');
  } catch (e, st) {
    // No bloquear login/Supabase si falla el CDN o la key en web.
    debugPrint('No se pudo precargar Google Maps JS: $e\n$st');
  }
  final url = dotenv.env['SUPABASE_URL']?.trim();
  final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw Exception('Configura SUPABASE_URL y SUPABASE_ANON_KEY en el archivo .env');
  }
  await Supabase.initialize(url: url, anonKey: anonKey);
  runApp(const FireDataApp());
}

class FireDataApp extends StatelessWidget {
  const FireDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FireData',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F9FC),
        primaryColor: const Color(0xFF00A84E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A84E),
          primary: const Color(0xFF00A84E),
        ),
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A84E),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF1F4F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
        ),
      ),
      routes: {
        '/gestion-familia': (_) => const GestionFamiliaScreen(),
        '/gestion-mascotas': (_) => const GestionMascotasScreen(),
        '/gestion-domicilio': (_) => const GestionDomicilioScreen(),
        '/gestion-peligrosos': (_) => const GestionPeligrososScreen(),
        '/gestion-configuracion': (_) => const GestionConfiguracionScreen(),
      },
      home: const LoginScreen(),
    );
  }
}
