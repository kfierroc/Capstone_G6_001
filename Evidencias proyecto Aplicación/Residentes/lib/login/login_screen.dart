import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import '../registro/registro_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CustomAppBar(
            title: "App para Residentes",
            subtitle: "Inicia sesión para continuar",
            showBack: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: ResponsiveContainer(
                child: Column(
                  children: [
                    const Text(
                      "Iniciar Sesión",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Accede a tu información familiar registrada",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const InputLabel(label: "Correo electrónico"),
                    const TextField(decoration: InputDecoration(hintText: "tu@email.com")),
                    const InputLabel(label: "Contraseña"),
                    const TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Tu contraseña",
                        suffixIcon: Icon(Icons.visibility_outlined, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Iniciar Sesión"),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistroScreen()),
                        );
                      },
                      child: const Text(
                        "¿No tienes cuenta? Regístrate aquí",
                        style: TextStyle(color: Color(0xFF00A84E), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
