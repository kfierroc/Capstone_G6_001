import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/admin_access.dart';
import 'models/admin_bombero_perfil.dart';
import 'screens/admin_home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF283593)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Restaura sesión solo si el usuario sigue siendo administrador.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  AdminBomberoPerfil? _perfil;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    final row = await obtenerBomberoAdminPorUsuario(client);
    if (row == null) {
      await client.auth.signOut();
      if (mounted) setState(() => _checking = false);
      return;
    }

    if (mounted) {
      setState(() {
        _perfil = AdminBomberoPerfil.fromMap(row);
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_perfil != null) {
      return AdminHomeScreen(perfil: _perfil!);
    }

    return const LoginScreen();
  }
}
