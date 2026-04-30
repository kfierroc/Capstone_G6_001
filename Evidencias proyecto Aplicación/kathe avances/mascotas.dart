import 'package:flutter/material.dart';

import '../models/mascota.dart';

class GestionMascotasScreen extends StatefulWidget {
  const GestionMascotasScreen({super.key});

  @override
  State<GestionMascotasScreen> createState() => _GestionMascotasScreenState();
}

class _GestionMascotasScreenState extends State<GestionMascotasScreen> {
  static const _azulBoton = Color(0xFF2563EB);
  static const _fondoApp = Color(0xFFF2FBFF);
  static const _fondoInput = Color(0xFFF6F7FB);
  static const _bordeGris = Color(0xFFE5E7EB);
  static const _textoPrincipal = Color(0xFF111827);
  static const _textoSecundario = Color(0xFF6B7280);
  static const _rojoIcono = Color(0xFFDC2626);
  static const _verdeTarjeta = Color(0xFFF1FFF7);
  static const _rojoSuave = Color(0xFFFFF5F5);
  static const _naranjaSuave = Color(0xFFFFFAF1);
  static const _azulSuave = Color(0xFFF3F8FF);
  static const _rojoBorde = Color(0xFFF3C7C7);
  static const _naranjaBorde = Color(0xFFF5DEB3);
  static const _azulBorde = Color(0xFFD6E7FF);

  static const List<String> _cronicas = [
    'Epilepsia',
    'Asma o problemas para respirar',
    'Problemas del corazón',
  ];

  static const List<String> _movilidad = [
    'Persona postrada',
    'Usa silla de ruedas',
    'Dificultad para moverse o caminar',
    'Problemas de vista',
    'Problemas de audición',
    'Vértigo o pérdida de equilibrio',
  ];

  final _anioController = TextEditingController(text: '1990');
  final _otraCondicionController = TextEditingController();

  final Set<String> _cronicasSeleccionadas = {};
  final Set<String> _movilidadSeleccionada = {};
  final List<String> _condicionesExtra = [];

  bool _expandirCronicas = false;
  bool _expandirMovilidad = false;
  int? _indiceEditando;

  final List<MiembroFamilia> _miembros = [
    MiembroFamilia(
      anioNacimiento: 1979,
      condiciones: ['Diabetes', 'Problemas cardíacos'],
    ),
    MiembroFamilia(
      anioNacimiento: 1977,
      condiciones: ['Movilidad reducida'],
    ),
  ];

  @override
  void dispose() {
    _anioController.dispose();
    _otraCondicionController.dispose();
    super.dispose();
  }

  List<String> get _condicionesSeleccionadas => [
    ..._movilidadSeleccionada,
    ..._cronicasSeleccionadas,
    ..._condicionesExtra,
  ];

  void _agregarCondicionExtra() {
    final texto = _otraCondicionController.text.trim();
    if (texto.isEmpty) return;
    if (_condicionesSeleccionadas.any(
      (condicion) => condicion.toLowerCase() == texto.toLowerCase(),
    )) {
      _otraCondicionController.clear();
      return;
    }

    setState(() {
      _condicionesExtra.add(texto);
      _otraCondicionController.clear();
    });
  }

  void _quitarCondicion(String condicion) {
    setState(() {
      _cronicasSeleccionadas.remove(condicion);
      _movilidadSeleccionada.remove(condicion);
      _condicionesExtra.remove(condicion);
    });
  }

  void _limpiarFormulario() {
    _anioController.text = '1990';
    _otraCondicionController.clear();
    _cronicasSeleccionadas.clear();
    _movilidadSeleccionada.clear();
    _condicionesExtra.clear();
    _expandirCronicas = false;
    _expandirMovilidad = false;
    _indiceEditando = null;
  }

  void _guardarMiembro() {
    final anio = int.tryParse(_anioController.text.trim());
    if (anio == null || anio < 1900 || anio > DateTime.now().year) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un año de nacimiento válido')),
      );
      return;
    }

    if (_condicionesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos una condición relevante'),
        ),
      );
      return;
    }

    final miembro = MiembroFamilia(
      anioNacimiento: anio,
      condiciones: [..._movilidadSeleccionada, ..._cronicasSeleccionadas],
      condicionesPersonalizadas: [..._condicionesExtra],
    );

    setState(() {
      if (_indiceEditando != null) {
        _miembros[_indiceEditando!] = miembro;
      } else {
        _miembros.add(miembro);
      }
      _limpiarFormulario();
    });
  }

  void _cargarMiembroEnFormulario(int index) {
    final miembro = _miembros[index];
    setState(() {
      _indiceEditando = index;
      _anioController.text = miembro.anioNacimiento.toString();
      _cronicasSeleccionadas
        ..clear()
        ..addAll(
          miembro.condiciones.where((condicion) => _cronicas.contains(condicion)),
        );
      _movilidadSeleccionada
        ..clear()
        ..addAll(
          miembro.condiciones.where((condicion) => _movilidad.contains(condicion)),
        );
      _condicionesExtra
        ..clear()
        ..addAll(miembro.condicionesPersonalizadas);
      _expandirCronicas = _cronicasSeleccionadas.isNotEmpty;
      _expandirMovilidad = _movilidadSeleccionada.isNotEmpty;
    });
  }

  void _eliminarMiembro(int index) {
    setState(() {
      _miembros.removeAt(index);
      if (_indiceEditando == index) {
        _limpiarFormulario();
      } else if (_indiceEditando != null && _indiceEditando! > index) {
        _indiceEditando = _indiceEditando! - 1;
      }
    });
  }

  String _tituloMiembro(int index) {
    if (index == 0) return 'Titular';
    return 'Residente ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoApp,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _bordeGris),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.people_outline, color: _textoPrincipal, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Gestión de Familia',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _textoPrincipal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Agrega y gestiona los miembros de tu familia',
                  style: TextStyle(fontSize: 14, color: _textoSecundario),
                ),
                const SizedBox(height: 22),
                _buildFormulario(),
                const SizedBox(height: 24),
                Text(
                  'Miembros de la familia (${_miembros.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textoPrincipal,
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(
                  _miembros.length,
                  (index) => _buildMiembroCard(_miembros[index], index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bordeGris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _indiceEditando == null
                ? 'Agregar nuevo integrante'
                : 'Editar integrante',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Año de nacimiento',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _anioController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(hint: '1990'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Condiciones médicas o especiales',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoriaCondiciones(
            titulo: 'Enfermedades Crónicas',
            expandido: _expandirCronicas,
            textoColor: const Color(0xFF9F1D1D),
            fondo: _rojoSuave,
            borde: _rojoBorde,
            opciones: _cronicas,
            seleccionadas: _cronicasSeleccionadas,
            onToggleExpanded: () {
              setState(() {
                _expandirCronicas = !_expandirCronicas;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildCategoriaCondiciones(
            titulo: 'Movilidad y Sentidos',
            expandido: _expandirMovilidad,
            textoColor: const Color(0xFFB45309),
            fondo: _naranjaSuave,
            borde: _naranjaBorde,
            opciones: _movilidad,
            seleccionadas: _movilidadSeleccionada,
            onToggleExpanded: () {
              setState(() {
                _expandirMovilidad = !_expandirMovilidad;
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _bordeGris),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Otra condición especial',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textoPrincipal,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _otraCondicionController,
                        decoration: _inputDecoration(
                          hint:
                              'Ingrese solo condiciones relevantes para el rescate',
                        ),
                        onSubmitted: (_) => _agregarCondicionExtra(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _bordeGris),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _agregarCondicionExtra,
                        icon: const Icon(Icons.add, color: _textoSecundario),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_condicionesSeleccionadas.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _azulSuave,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _azulBorde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Condiciones seleccionadas:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF315D95),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _condicionesSeleccionadas
                        .map(
                          (condicion) => Chip(
                            label: Text(condicion),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => _quitarCondicion(condicion),
                            backgroundColor: const Color(0xFFE8F0FF),
                            side: BorderSide.none,
                            labelStyle: const TextStyle(
                              color: Color(0xFF355E96),
                              fontSize: 12,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _guardarMiembro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _azulBoton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    _indiceEditando == null
                        ? 'Agregar Residente'
                        : 'Guardar cambios',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (_indiceEditando != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => setState(_limpiarFormulario),
                  child: const Text('Cancelar edición'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCondiciones({
    required String titulo,
    required bool expandido,
    required Color textoColor,
    required Color fondo,
    required Color borde,
    required List<String> opciones,
    required Set<String> seleccionadas,
    required VoidCallback onToggleExpanded,
  }) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggleExpanded,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _bordeGris),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      color: textoColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  expandido ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  color: _textoPrincipal,
                ),
              ],
            ),
          ),
        ),
        if (expandido) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borde),
            ),
            child: Column(
              children: opciones.map((opcion) {
                return CheckboxListTile(
                  value: seleccionadas.contains(opcion),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        seleccionadas.add(opcion);
                      } else {
                        seleccionadas.remove(opcion);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    opcion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textoPrincipal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: _textoPrincipal,
                  side: const BorderSide(color: _bordeGris),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiembroCard(MiembroFamilia miembro, int index) {
    final esTitular = index == 0;
    final titulo = _tituloMiembro(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esTitular ? _verdeTarjeta : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: esTitular ? const Color(0xFFCBEFDB) : _bordeGris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: titulo,
                            style: const TextStyle(
                              color: _textoPrincipal,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '  (${miembro.edadAproximada} años)',
                            style: const TextStyle(
                              color: _textoSecundario,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Año de nacimiento: ${miembro.anioNacimiento}',
                      style: const TextStyle(
                        color: _textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    color: _azulBoton,
                    onPressed: () => _cargarMiembroEnFormulario(index),
                  ),
                  if (!esTitular) ...[
                    const SizedBox(width: 10),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      color: _rojoIcono,
                      onPressed: () => _eliminarMiembro(index),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Condiciones:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: miembro.todasLasCondiciones
                .map(
                  (condicion) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      condicion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textoPrincipal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordeGris),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _fondoInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _azulBorde),
      ),
    );
  }
}
