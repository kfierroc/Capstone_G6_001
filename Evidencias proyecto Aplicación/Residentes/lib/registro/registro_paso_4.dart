import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class RegistroPaso4 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso4({super.key, required this.onNext, required this.onBack});

  @override
  State<RegistroPaso4> createState() => _RegistroPaso4State();
}

class _RegistroPaso4State extends State<RegistroPaso4> {
  String? _selectedTipo;
  String? _selectedEstado;
  String? _selectedMaterial;
  String? _selectedTiempo;
  final List<Map<String, String>> _floors = [];

  void _addFloor() {
    if (_selectedMaterial != null) {
      setState(() {
        _floors.add({
          "number": "${_floors.length + 1}",
          "material": _selectedMaterial!,
        });
        _selectedMaterial = null;
      });
    }
  }

  void _removeFloor(int index) {
    setState(() {
      _floors.removeAt(index);
      for (int i = 0; i < _floors.length; i++) {
        _floors[i]["number"] = "${i + 1}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home_outlined, size: 24),
            SizedBox(width: 8),
            Text(
              "Detalles de la Vivienda",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Proporciona información adicional sobre tu vivienda que ayudará a los bomberos en caso de emergencia",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
        
        const InputLabel(label: "Tiempo en la residencia", required: true),
        DropdownButtonFormField<String>(
          initialValue: _selectedTiempo,
          decoration: const InputDecoration(hintText: "Selecciona el tiempo de permanencia"),
          items: ["1 mes", "2 meses", "3 meses", "4 meses", "5 meses", "6 meses", "1 año", "Más de 1 año"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _selectedTiempo = val),
        ),
        
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0E3FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF2C5BA9)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Cuando el tiempo en la residencia se agota, automáticamente se desvincula el grupo familiar de la residencia.",
                  style: TextStyle(color: Color(0xFF2C5BA9), fontSize: 11),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const InputLabel(label: "Tipo de vivienda", required: true),
        DropdownButtonFormField<String>(
          initialValue: _selectedTipo,
          decoration: const InputDecoration(hintText: "Selecciona el tipo de vivienda"),
          items: ["Casa", "Departamento", "Empresa", "Local comercial", "Oficina", "Bodega", "Otro"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _selectedTipo = val),
        ),

        if (_selectedTipo != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Agregar pisos de la vivienda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isNarrow = constraints.maxWidth < 350;
                    return isNarrow 
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNextFloorIndicator(),
                            const SizedBox(height: 12),
                            _buildMaterialDropdown(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(flex: 2, child: _buildNextFloorIndicator()),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: _buildMaterialDropdown()),
                          ],
                        );
                  }
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _selectedMaterial != null ? _addFloor : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8BA9FF),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text("+ Agregar Piso ${_floors.length + 1}"),
                ),
                if (_floors.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text("Pisos agregados (${_floors.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ..._floors.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Map<String, String> floor = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Piso ${floor['number']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text("Material: ${floor['material']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _removeFloor(idx),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],

        const InputLabel(label: "Estado general de la vivienda", required: true),
        DropdownButtonFormField<String>(
          initialValue: _selectedEstado,
          decoration: const InputDecoration(hintText: "Selecciona el estado"),
          items: ["Excelente", "Bueno", "Regular", "Deteriorado"]
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _selectedEstado = val),
        ),

        const InputLabel(label: "Instrucciones especiales"),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Información adicional relevante para bomberos (accesos especiales, llaves, etc.)",
          ),
        ),

        const SizedBox(height: 24),
        
        // --- RESUMEN DE INFORMACIÓN (RESPONSIVO SEGÚN AUDIO) ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Resumen de tu información",
                    style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Agrupamos los ítems según el audio
                  Widget group1 = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryItem("Dirección:", ""),
                      _buildSummaryItem("Comuna:", "No disponible"),
                      _buildSummaryItem("Tiempo en la residencia:", _selectedTiempo ?? "No especificado"),
                    ],
                  );

                  Widget group2 = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryItem("Tipo:", _selectedTipo ?? "No especificado"),
                      _buildSummaryItem("Pisos:", _floors.isEmpty ? "No especificado" : "${_floors.length}"),
                      _buildSummaryItem("Estado:", _selectedEstado ?? "No especificado"),
                    ],
                  );

                  // Si el ancho es pequeño (Móvil), mostramos los 6 hacia abajo
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        group1,
                        group2,
                      ],
                    );
                  } else {
                    // Si hay espacio (Tablet/Web), dividimos en dos columnas (3 y 3)
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: group1),
                        const SizedBox(width: 12),
                        Expanded(child: group2),
                      ],
                    );
                  }
                },
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
                child: const Text("Completar configuración"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 11, height: 1.4),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildNextFloorIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E3FF)),
      ),
      child: Text(
        "Se agregará: Piso ${_floors.length + 1}",
        style: const TextStyle(color: Color(0xFF2C5BA9), fontSize: 13),
      ),
    );
  }

  Widget _buildMaterialDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Material del piso *", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _selectedMaterial,
          isExpanded: true, // Esto hace que el contenido se ajuste al ancho disponible
          decoration: const InputDecoration(
            hintText: "Selecciona el material",
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: ["Ladrillo", "Madera", "Hormigón", "Metal"]
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis, // Esto añade los "..."
                    ),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedMaterial = val),
        ),
      ],
    );
  }
}
