import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class RegistroPaso2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso2({super.key, required this.onNext, required this.onBack});

  @override
  State<RegistroPaso2> createState() => _RegistroPaso2State();
}

class _RegistroPaso2State extends State<RegistroPaso2> {
  DateTime? _selectedDate;
  int? _age;
  
  // Listas de condiciones seleccionadas
  final List<String> _selectedConditions = [];
  
  // Opciones para los paneles
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

  void _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    setState(() {
      _age = age;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A84E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _calculateAge(picked);
    }
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
        const TextField(decoration: InputDecoration(hintText: "XXXXXXXX-X")),
        
        const InputLabel(label: "Teléfono", required: true),
        const TextField(
          decoration: InputDecoration(hintText: "+56 9 1234 5678"),
          keyboardType: TextInputType.phone,
        ),

        const InputLabel(label: "Año de nacimiento", required: true),
        InkWell(
          onTap: () => _selectDate(context),
          child: IgnorePointer(
            child: TextField(
              decoration: InputDecoration(
                hintText: _selectedDate == null 
                    ? "1990" 
                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                suffixIcon: const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
              ),
            ),
          ),
        ),
        if (_age != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              "Edad: $_age años",
              style: const TextStyle(color: Color(0xFF00A84E), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

        const SizedBox(height: 20),
        const Text(
          "Condiciones médicas o especiales",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        
        // Panel Enfermedades Crónicas
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
        
        // Panel Movilidad y Sentidos
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
        
        // Recuadro de condiciones seleccionadas
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
                onPressed: widget.onNext,
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
                // También desmarcar en los mapas si existe
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
