import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/bombero_access.dart';
import '../models/bombero_perfil.dart';
import '../screens/home_bombero_screen.dart';
import '../services/registro_bombero_service.dart';
import '../widgets/bomberos_registro_widgets.dart';
import 'registro_models.dart';
import 'registro_paso_1.dart';
import 'registro_paso_2.dart';
import 'registro_paso_3.dart';

/// Flujo de registro en 3 pasos (misma idea que [RegistroScreen] en Residentes).
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  int _currentStep = 1;
  final _draft = RegistroBomberoBorrador();
  bool _enviando = false;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _backStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _irALogin() {
    Navigator.of(context).pop();
  }

  String _stepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Credenciales de Acceso';
      case 2:
        return 'Información Personal';
      case 3:
        return 'Ubicación y Compañía';
      default:
        return '';
    }
  }

  Future<void> _finalizarRegistro() async {
    setState(() => _enviando = true);
    try {
      await RegistroBomberoService(Supabase.instance.client).registrar(_draft);
      if (!mounted) return;
      final row = await obtenerBomberoPorUsuario(Supabase.instance.client);
      if (!mounted) return;
      if (row == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro guardado. Inicia sesión para continuar.'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      final perfil = BomberoPerfil.fromMap(row);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => HomeBomberoScreen(perfil: perfil)),
        (_) => false,
      );
    } on RegistroBomberoException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _cardContent() {
    switch (_currentStep) {
      case 1:
        return RegistroPaso1(
          draft: _draft,
          onNext: _nextStep,
          onIrALogin: _irALogin,
        );
      case 2:
        return RegistroPaso2(
          draft: _draft,
          onNext: _nextStep,
          onBack: _backStep,
          onIrALogin: _irALogin,
        );
      case 3:
        return RegistroPaso3(
          draft: _draft,
          onComplete: _finalizarRegistro,
          onBack: _backStep,
          enviando: _enviando,
          onIrALogin: _irALogin,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final maxW = screenW >= 900 ? 560.0 : screenW >= 600 ? 520.0 : double.infinity;
    final horizontal = screenW >= 600 ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: kBomberosFondoCrema,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BomberosRegistroAppBar(onVolver: _backStep),
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: BomberosRegistroStepIndicator(
                  currentStep: _currentStep,
                  stepTitle: _stepTitle(),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxW),
                  child: Card(
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(screenW >= 600 ? 28 : 22),
                      child: _cardContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
