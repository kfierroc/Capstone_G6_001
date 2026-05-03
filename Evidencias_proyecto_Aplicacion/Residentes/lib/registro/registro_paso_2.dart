// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/chile_rut_formatter.dart';
import '../widgets/custom_widgets.dart';
import 'registro_models.dart';

class RegistroPaso2 extends StatefulWidget {
  final RegistroResidenteBorrador draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso2({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<RegistroPaso2> createState() => _RegistroPaso2State();
}

class _RegistroPaso2State extends State<RegistroPaso2> {
  final _rutController = TextEditingController();
  /// Solo 9 dígitos después de +56 (móvil chileno).
  final _telefonoSufijoController = TextEditingController();
  /// Solo año de nacimiento (modelo sigue usando `fechaNacimiento` como 1 de enero de ese año).
  int? _anioNacimiento;
  int? _edadPorAnio;

  final List<String> _selectedConditions = [];

  final Map<String, bool> _cronicasOptions = {
    "Epilepsia": false,
    "Asma o problemas para respirar": false,
    "Problemas del corazón": false,
  };

  final Map<String, bool> _movilidadOptions = {
    "Persona postrada": false,
    "Usa silla de ruedas": false,
    "Dificultad para moverse o caminar": false,
    "Problemas de vista": false,
    "Problemas de audición": false,
    "Vértigo o pérdida de equilibrio": false,
  };

  bool _isCronicaExpanded = false;
  bool _isMovilidadExpanded = false;

  final TextEditingController _otraCondicionController = TextEditingController();

  @override
  void dispose() {
    _rutController.dispose();
    _telefonoSufijoController.dispose();
    _otraCondicionController.dispose();
    super.dispose();
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _actualizarEdadDesdeAnio(int? anio) {
    if (anio == null) {
      setState(() => _edadPorAnio = null);
      return;
    }
    final y = DateTime.now().year;
    setState(() => _edadPorAnio = y - anio);
  }

  List<int> get _aniosDisponibles {
    final actual = DateTime.now().year;
    final minAnio = actual - 120;
    final maxAnio = actual - 16;
    return [for (var a = maxAnio; a >= minAnio; a--) a];
  }

  void _toggleCondition(String condition, bool isCronica) {
    setState(() {
      if (isCronica) {
        _cronicasOptions[condition] = !(_cronicasOptions[condition]!);
        if (_cronicasOptions[condition]!) {
          if (!_selectedConditions.contains(condition)) _selectedConditions.add(condition);
        } else {
          _selectedConditions.remove(condition);
        }
      } else {
        _movilidadOptions[condition] = !(_movilidadOptions[condition]!);
        if (_movilidadOptions[condition]!) {
          if (!_selectedConditions.contains(condition)) _selectedConditions.add(condition);
        } else {
          _selectedConditions.remove(condition);
        }
      }
    });
  }

  void _addManualCondition() {
    String text = _otraCondicionController.text.trim();
    if (text.isNotEmpty && !_selectedConditions.contains(text)) {
      setState(() {
        _selectedConditions.add(text);
        _otraCondicionController.clear();
      });
    }
  }

  void _continuar() {
    final rut = parsearRutChileno(_rutController.text);
    if (rut == null) {
      _showSnack('Ingresa un RUT válido (ej: 12345678-9).');
      return;
    }
    final tel = normalizarTelefonoSufijoChile(_telefonoSufijoController.text);
    if (tel == null) {
      _showSnack('Teléfono inválido: ingresa 9 dígitos empezando por 9 (ej: 912345678).');
      return;
    }
    if (_anioNacimiento == null) {
      _showSnack('Selecciona tu año de nacimiento.');
      return;
    }
    final edad = _edadPorAnio ?? 0;
    if (edad < 16 || edad > 120) {
      _showSnack('Como titular debes tener entre 16 y 120 años según el registro.');
      return;
    }

    final d = widget.draft;
    d.rutNum = rut.num;
    d.rutDv = rut.dv;
    d.telefonoNormalizado = tel;
    d.fechaNacimiento = DateTime(_anioNacimiento!, 1, 1);
    d.condicionesMedicas
      ..clear()
      ..addAll(_selectedConditions);

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person_outline, size: 24),
            SizedBox(width: 8),
            Text(
              "Datos del Titular",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Completa tu información como titular del domicilio",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const InputLabel(label: "RUT (Titular)", required: true),
        TextField(
          controller: _rutController,
          keyboardType: TextInputType.text,
          inputFormatters: [ChileRutInputFormatter()],
          decoration: const InputDecoration(
            hintText: "Escribe solo números y el dígito verificador",
          ),
        ),
        const InputLabel(label: "Teléfono", required: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: Text(
                '+56 ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _telefonoSufijoController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  hintText: '912345678',
                ),
              ),
            ),
          ],
        ),
        const InputLabel(label: "Año de nacimiento", required: true),
        DropdownButtonFormField<int>(
          value: _anioNacimiento,
          decoration: const InputDecoration(hintText: "Selecciona el año"),
          items: _aniosDisponibles
              .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
              .toList(),
          onChanged: (a) {
            setState(() => _anioNacimiento = a);
            _actualizarEdadDesdeAnio(a);
          },
        ),
        if (_edadPorAnio != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              "Edad aproximada: $_edadPorAnio años (por año de nacimiento)",
              style: const TextStyle(color: Color(0xFF00A84E), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          "Condiciones médicas o especiales",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        _buildExpandablePanel(
          title: "Enfermedades Crónicas",
          color: Colors.red.shade900,
          bgColor: const Color(0xFFFFEBEE),
          isExpanded: _isCronicaExpanded,
          onToggle: () => setState(() => _isCronicaExpanded = !_isCronicaExpanded),
          options: _cronicasOptions,
          isCronica: true,
        ),
        const SizedBox(height: 8),
        _buildExpandablePanel(
          title: "Movilidad y Sentidos",
          color: Colors.orange.shade900,
          bgColor: const Color(0xFFFFF3E0),
          isExpanded: _isMovilidadExpanded,
          onToggle: () => setState(() => _isMovilidadExpanded = !_isMovilidadExpanded),
          options: _movilidadOptions,
          isCronica: false,
        ),
        const SizedBox(height: 20),
        const Text("Otra condición especial", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _otraCondicionController,
                decoration: const InputDecoration(
                  hintText: "Diabetes",
                  fillColor: Color(0xFFF1F4F8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: _addManualCondition,
              ),
            )
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD0E3FF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Condiciones seleccionadas:",
                style: TextStyle(color: Color(0xFF2C5BA9), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (_selectedConditions.isEmpty)
                const Text("Ninguna seleccionada", style: TextStyle(color: Colors.grey, fontSize: 12))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedConditions.map((condition) => _buildChip(condition)).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text("Anterior"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continuar,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandablePanel({
    required String title,
    required Color color,
    required Color bgColor,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Map<String, bool> options,
    required bool isCronica,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.3),
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Column(
              children: options.keys.map((option) {
                return CheckboxListTile(
                  title: Text(option, style: const TextStyle(fontSize: 14)),
                  value: options[option],
                  activeColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (val) => _toggleCondition(option, isCronica),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              setState(() {
                _selectedConditions.remove(label);
                if (_cronicasOptions.containsKey(label)) _cronicasOptions[label] = false;
                if (_movilidadOptions.containsKey(label)) _movilidadOptions[label] = false;
              });
            },
            child: const Icon(Icons.close, size: 14, color: Color(0xFF1976D2)),
          ),
        ],
      ),
    );
  }
}
