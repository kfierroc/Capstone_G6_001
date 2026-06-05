import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL']?.trim();
  final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();
  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw Exception(
      'Configura SUPABASE_URL y SUPABASE_ANON_KEY en el archivo .env (puedes copiar env.example).',
    );
  }
  await Supabase.initialize(url: url, anonKey: anonKey);
  runApp(const BomberosApp());
}

class BomberosApp extends StatelessWidget {
  const BomberosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bomberos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC62828),
          primary: const Color(0xFFC62828),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      home: const LoginScreen(),
    );
  }
}
