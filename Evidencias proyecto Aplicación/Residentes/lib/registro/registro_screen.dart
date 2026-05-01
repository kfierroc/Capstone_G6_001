import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import 'registro_paso_1.dart';
import 'registro_paso_2.dart';
import 'registro_paso_3.dart';
import 'registro_paso_4.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  int _currentStep = 1;

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Finalizar registro: ir a Gestión Familia
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/gestion-familia',
        (route) => false,
      );
    }
  }

  void _backStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  String _getSubtitle() {
    switch (_currentStep) {
      case 1:
        return "Configura la información de tu domicilio";
      case 2:
        return "Configura la información de tu domicilio";
      case 3:
        return "Configura la información de tu domicilio";
      case 4:
        return "Configura la información de tu domicilio";
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
          onNext: _nextStep,
          onBack: _backStep,
        );
      case 3:
        return RegistroPaso3(
          onNext: _nextStep,
          onBack: _backStep,
        );
      case 4:
        return RegistroPaso4(
          onNext: _nextStep,
          onBack: _backStep,
        );
      default:
        return const Center(child: Text("Error de paso"));
    }
  }
}
