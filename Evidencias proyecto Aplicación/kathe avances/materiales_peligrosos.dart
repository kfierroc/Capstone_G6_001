import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/material_peligroso.dart';

// ─────────────────────────────────────────────────────────────────────────────
// COLORES
// ─────────────────────────────────────────────────────────────────────────────
class _K {
  static const Color bg = Color(0xFFF0F4F8);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF111827);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textOrange = Color(0xFFEA580C);
  static const Color borderGray = Color(0xFFE5E7EB);
  static const Color borderOrange = Color(0xFFFED7AA);
  static const Color cardOrangeBg = Color(0xFFFFF7ED);
  static const Color btnOrangeBg = Color(0xFFFB923C);
  static const Color btnOrangeText = Colors.white;
  static const Color inputBorder = Color(0xFFD1D5DB);
  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color placeholderText = Color(0xFF9CA3AF);
  static const Color iconDelete = Color(0xFFEF4444);
  static const Color iconWarning = Color(0xFFF97316);
  static const Color registradosBorder = Color(0xFFFED7AA);
  static const Color registradosBg = Color(0xFFFFF7ED);
  static const Color registradosTitleOrange = Color(0xFFEA580C);
}

// ─────────────────────────────────────────────────────────────────────────────
// TIPOS DE MATERIAL
// ─────────────────────────────────────────────────────────────────────────────
const List<String> kTiposMaterial = [
  'Balón/Cilindro de gas',
  'Combustible líquido',
  'Productos químicos',
  'Explosivos',
  'Material radiactivo',
  'Otros',
];

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA
// ─────────────────────────────────────────────────────────────────────────────
class MaterialesPeligrososScreen extends StatefulWidget {
  const MaterialesPeligrososScreen({super.key});

  @override
  State<MaterialesPeligrososScreen> createState() =>
      _MaterialesPeligrososScreenState();
}

class _MaterialesPeligrososScreenState
    extends State<MaterialesPeligrososScreen> {
  String? _tipoSeleccionado;
  final TextEditingController _cantidadCtrl =
      TextEditingController(text: '1');
  final TextEditingController _notasCtrl = TextEditingController();

  final List<MaterialPeligroso> _registrados = [
    MaterialPeligroso(
        id: '1', tipo: 'Balón/Cilindro de gas', cantidad: 1),
  ];

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  void _agregarMaterial() {
    if (_tipoSeleccionado == null) return;
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 1;
    setState(() {
      _registrados.add(MaterialPeligroso(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tipo: _tipoSeleccionado!,
        cantidad: cantidad,
        notasAdicionales: _notasCtrl.text,
      ));
      _tipoSeleccionado = null;
      _cantidadCtrl.text = '1';
      _notasCtrl.clear();
    });
  }

  void _eliminarMaterial(String id) {
    setState(() => _registrados.removeWhere((m) => m.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: _K.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 20),
                        _buildRegistradosSection(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Encabezado ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 20, color: Color(0xFF374151)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Materiales Peligrosos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _K.textDark,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gestiona los materiales peligrosos presentes en tu domicilio',
                style: TextStyle(fontSize: 12.5, color: _K.textGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Formulario Agregar ─────────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _K.cardOrangeBg,
        border: Border.all(color: _K.borderOrange),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar material peligroso',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _K.textOrange,
            ),
          ),
          const SizedBox(height: 14),

          // Fila: Tipo de material + Cantidad
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de material
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 12.5, color: _K.textDark),
                        children: [
                          TextSpan(
                              text: 'Tipo de material ',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                              text: '*',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: _K.white,
                        border: Border.all(color: _K.inputBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tipoSeleccionado,
                          hint: const Text('Selecciona',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _K.placeholderText)),
                          isExpanded: true,
                          isDense: true,
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: _K.textGray),
                          items: kTiposMaterial
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _K.textDark)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _tipoSeleccionado = v),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Cantidad
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 12.5, color: _K.textDark),
                        children: [
                          TextSpan(
                              text: 'Cantidad ',
                              style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                              text: '*',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cantidadCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(
                          fontSize: 13, color: _K.textDark),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        filled: true,
                        fillColor: _K.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: _K.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: _K.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Color(0xFF60A5FA)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notas adicionales
          const Text(
            'Notas adicionales (opcional)',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _K.textDark),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notasCtrl,
            maxLines: 3,
            style: const TextStyle(fontSize: 13, color: _K.textDark),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Información adicional relevante para bomberos',
              hintStyle: const TextStyle(
                  fontSize: 13, color: _K.placeholderText),
              contentPadding: const EdgeInsets.all(10),
              filled: true,
              fillColor: _K.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _K.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _K.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: Color(0xFF60A5FA)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Botón Agregar Material
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _tipoSeleccionado != null ? _agregarMaterial : null,
              icon: const Icon(Icons.add, size: 17, color: _K.btnOrangeText),
              label: const Text(
                'Agregar Material',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _K.btnOrangeText),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _K.btnOrangeBg,
                disabledBackgroundColor: _K.btnOrangeBg.withOpacity(0.5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Lista de Registrados ───────────────────────────────────────────────────
  Widget _buildRegistradosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título "Registrados (N)"
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14.5),
            children: [
              const TextSpan(
                  text: 'Registrados ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _K.registradosTitleOrange)),
              TextSpan(
                text: '(${_registrados.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _K.registradosTitleOrange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tarjetas de materiales
        ..._registrados.map((m) => _buildMaterialCard(m)),
      ],
    );
  }

  Widget _buildMaterialCard(MaterialPeligroso m) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _K.white,
        border: Border.all(color: _K.registradosBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.tipo,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _K.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cantidad: ${m.cantidad}',
                  style: const TextStyle(
                      fontSize: 13, color: _K.textGray),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _eliminarMaterial(m.id),
            icon: const Icon(Icons.delete_outline,
                size: 20, color: _K.iconDelete),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB));
}
