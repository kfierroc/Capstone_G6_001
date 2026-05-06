import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/registro_residente_service.dart';
import '../widgets/custom_widgets.dart';
import 'registro_models.dart';
import 'registro_paso_1.dart';
import 'registro_paso_2.dart';
import 'registro_paso_3.dart';
import 'registro_paso_4.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key, this.saltarRegistroAuth = false});

  /// Si es true (p. ej. usuario ya autenticado sin `grupofamiliar`), empieza en el paso 2.
  final bool saltarRegistroAuth;

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  late int _currentStep;
  final _draft = RegistroResidenteBorrador();
  bool _enviando = false;

  int get _minStep => widget.saltarRegistroAuth ? 2 : 1;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.saltarRegistroAuth ? 2 : 1;
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _backStep() {
    if (_currentStep > _minStep) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _finalizarRegistro() async {
    setState(() => _enviando = true);
    try {
      await RegistroResidenteService(Supabase.instance.client).registrar(_draft);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/gestion-familia',
        (route) => false,
      );
    } on RegistroResidenteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case 1:
        return "Crea tu cuenta de residente";
      case 2:
        return "Datos del titular";
      case 3:
        return "Ubicación de la residencia";
      case 4:
        return "Detalle de la vivienda";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            title: "Configuración inicial",
            subtitle: _getSubtitle(),
            onBack: _backStep,
          ),
          StepIndicator(currentStep: _currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: ResponsiveContainer(
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return RegistroPaso1(
          onNext: _nextStep,
          onCancel: () => Navigator.pop(context),
        );
      case 2:
        return RegistroPaso2(
          draft: _draft,
          onNext: _nextStep,
          onBack: _backStep,
        );
      case 3:
        return RegistroPaso3(
          draft: _draft,
          onNext: _nextStep,
          onBack: _backStep,
        );
      case 4:
        return RegistroPaso4(
          draft: _draft,
          onComplete: _finalizarRegistro,
          onBack: _backStep,
          enviando: _enviando,
        );
      default:
        return const Center(child: Text("Error de paso"));
    }
  }
}
