import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login/login_screen.dart';
import '../models/bombero_perfil.dart';
import '../screens/home_bombero_screen.dart';
import 'bombero_access.dart';

/// Al abrir la app, restaura la sesión de Supabase (persistida en el dispositivo)
/// y envía al home si el bombero sigue autenticado; si no, al login.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _rojo = Color(0xFFC62828);

  BomberoPerfil? _perfil;
  bool _resolviendo = true;

  @override
  void initState() {
    super.initState();
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    final client = Supabase.instance.client;

    try {
      final perfil = await resolverPerfilSesionActual(client);
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _resolviendo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolviendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolviendo) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F4F2),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 56, color: _rojo),
              SizedBox(height: 20),
              Text(
                'Bomberos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _rojo),
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: _rojo),
              ),
            ],
          ),
        ),
      );
    }

    if (_perfil != null) {
      return HomeBomberoScreen(perfil: _perfil!);
    }
    return const LoginScreen();
  }
}
