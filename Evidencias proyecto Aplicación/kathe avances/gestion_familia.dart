// lib/screens/gestion_familia.dart

import 'package:flutter/material.dart';
import '../models/miembro_familia.dart';

class GestionFamiliaScreen extends StatefulWidget {
  const GestionFamiliaScreen({super.key});

  @override
  State<GestionFamiliaScreen> createState() => _GestionFamiliaScreenState();
}

class _GestionFamiliaScreenState extends State<GestionFamiliaScreen> {
  // ─── Colores ─────────────────────────────────────────────────────────────────
  static const _azul = Color(0xFF3D7BF5);
  static const _rojoCat = Color(0xFFD94F3D);
  static const _naranjaCat = Color(0xFFE07B3A);
  static const _bordeGris = Color(0xFFE0E0E0);
  static const _fondo = Color(0xFFF4F6FB);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);
  static const _fondoVerde = Color(0xFFEFF8F0);
  static const _bordeVerde = Color(0xFFB6DFB8);

  // ─── Categorías de condiciones ───────────────────────────────────────────────
  static const Map<String, List<String>> _categorias = {
    'Enfermedades Crónicas': [
      'Epilepsia',
      'Asma o problemas para respirar',
      'Problemas del corazón',
    ],
    'Movilidad y Sentidos': [
      'Persona postrada',
      'Usa silla de ruedas',
      'Dificultad para moverse o caminar',
      'Problemas de vista',
      'Problemas de audición',
      'Vértigo o pérdida de equilibrio',
    ],
  };

  // ─── Estado formulario ───────────────────────────────────────────────────────
  final _anioController = TextEditingController(text: '1990');
  final _otraCondController = TextEditingController();
  final Map<String, bool> _expandido = {
    'Enfermedades Crónicas': false,
    'Movilidad y Sentidos': false,
  };
  final Set<String> _seleccionadas = {};

  // ─── Lista de miembros ───────────────────────────────────────────────────────
  final List<MiembroFamilia> _miembros = [
    MiembroFamilia(
      rol: 'Titular',
      anioNacimiento: 1979,
      condiciones: ['Diabetes', 'Problemas cardíacos'],
    ),
    MiembroFamilia(
      rol: 'Residente 2',
      anioNacimiento: 1977,
      condiciones: ['Movilidad reducida'],
    ),
  ];

  int _contadorResidentes = 3;

  @override
  void dispose() {
    _anioController.dispose();
    _otraCondController.dispose();
    super.dispose();
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  void _agregarResidente() {
    final anio = int.tryParse(_anioController.text.trim());
    if (anio == null || anio < 1900 || anio > DateTime.now().year) {
      _snack('Ingresa un año de nacimiento válido.');
      return;
    }
    if (_seleccionadas.isEmpty) {
      _snack('Selecciona al menos una condición.');
      return;
    }
    setState(() {
      _miembros.add(
        MiembroFamilia(
          rol: 'Residente $_contadorResidentes',
          anioNacimiento: anio,
          condiciones: _seleccionadas.toList(),
        ),
      );
      _contadorResidentes++;
      _limpiarFormulario();
    });
  }

  void _editarMiembro(int index) {
    final m = _miembros[index];
    final anioEdit = TextEditingController(text: m.anioNacimiento.toString());
    final Set<String> condEdit = Set.from(m.condiciones);
    final Map<String, bool> expEdit = {
      'Enfermedades Crónicas': false,
      'Movilidad y Sentidos': false,
    };
    final otraEdit = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setD) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Editar ${m.rol}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textoPrincipal,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Año de nacimiento',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _inputField(
                    controller: anioEdit,
                    hint: 'Ej: 1985',
                    teclado: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  ..._categorias.entries.map(
                    (entry) => Column(
                      children: [
                        _buildCategoriaTile(
                          titulo: entry.key,
                          opciones: entry.value,
                          seleccionadas: condEdit,
                          expandido: expEdit[entry.key]!,
                          onToggleExpand: () => setD(
                            () => expEdit[entry.key] = !expEdit[entry.key]!,
                          ),
                          onToggleItem: (item) => setD(() {
                            condEdit.contains(item)
                                ? condEdit.remove(item)
                                : condEdit.add(item);
                          }),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Condiciones seleccionadas
                  if (condEdit.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildChipsSeleccionados(
                      condEdit,
                      (c) => setD(() => condEdit.remove(c)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: _textoGris),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final anio = int.tryParse(anioEdit.text.trim());
                if (anio == null) return;
                setState(() {
                  _miembros[index].anioNacimiento = anio;
                  _miembros[index].condiciones = condEdit.toList();
                });
                Navigator.pop(context);
                _snack('${m.rol} actualizado.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _eliminarMiembro(int index) {
    final rol = _miembros[index].rol;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar miembro',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textoPrincipal),
        ),
        content: Text(
          '¿Eliminar a $rol de la familia?',
          style: const TextStyle(color: _textoGris),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _textoGris)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _miembros.removeAt(index));
              Navigator.pop(context);
              _snack('$rol eliminado.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    _anioController.text = '1990';
    _otraCondController.clear();
    _seleccionadas.clear();
    _expandido.updateAll((_, __) => false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEncabezado(),
              const SizedBox(height: 24),
              _buildTarjetaFormulario(),
              const SizedBox(height: 28),
              _buildSeccionMiembros(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Row(
      children: [
        const Icon(Icons.person_outline, color: _textoPrincipal, size: 26),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Gestión de Familia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textoPrincipal,
              ),
            ),
            Text(
              'Agrega y gestiona los miembros de tu familia',
              style: TextStyle(fontSize: 13, color: _textoGris),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTarjetaFormulario() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _bordeGris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agregar nuevo integrante',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Año de nacimiento',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          _inputField(
            controller: _anioController,
            hint: 'Ej: 1990',
            teclado: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text(
            'Condiciones médicas o especiales',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textoPrincipal,
            ),
          ),
          const SizedBox(height: 10),

          // Categorías expandibles
          ..._categorias.entries.map(
            (entry) => Column(
              children: [
                _buildCategoriaTile(
                  titulo: entry.key,
                  opciones: entry.value,
                  seleccionadas: _seleccionadas,
                  expandido: _expandido[entry.key]!,
                  onToggleExpand: () => setState(
                    () => _expandido[entry.key] = !_expandido[entry.key]!,
                  ),
                  onToggleItem: (item) => setState(() {
                    _seleccionadas.contains(item)
                        ? _seleccionadas.remove(item)
                        : _seleccionadas.add(item);
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Otra condición
          _buildOtraCondicion(),
          const SizedBox(height: 12),

          // Chips seleccionadas
          if (_seleccionadas.isNotEmpty) ...[
            _buildChipsSeleccionados(
              _seleccionadas,
              (c) => setState(() => _seleccionadas.remove(c)),
            ),
            const SizedBox(height: 16),
          ],

          // Botón agregar
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _agregarResidente,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Agregar Residente',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaTile({
    required String titulo,
    required List<String> opciones,
    required Set<String> seleccionadas,
    required bool expandido,
    required VoidCallback onToggleExpand,
    required ValueChanged<String> onToggleItem,
  }) {
    final esEnfermedad = titulo == 'Enfermedades Crónicas';
    final colorTitulo = esEnfermedad ? _rojoCat : _naranjaCat;
    final colorFondo = esEnfermedad
        ? const Color(0xFFFFF0EE)
        : const Color(0xFFFFF8F0);
    final colorBorde = esEnfermedad
        ? const Color(0xFFFFD5D0)
        : const Color(0xFFFFE5C8);

    return Column(
      children: [
        // Header colapsable
        GestureDetector(
          onTap: onToggleExpand,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _bordeGris),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorTitulo,
                    ),
                  ),
                ),
                Icon(
                  expandido
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: colorTitulo,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        // Opciones expandibles
        if (expandido)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorFondo,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorBorde),
            ),
            child: Column(
              children: opciones.map((opcion) {
                final marcado = seleccionadas.contains(opcion);
                return GestureDetector(
                  onTap: () => onToggleItem(opcion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: marcado ? _azul : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: marcado ? _azul : _bordeGris,
                              width: 1.5,
                            ),
                          ),
                          child: marcado
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          opcion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textoPrincipal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildOtraCondicion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _bordeGris),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Otra condición especial',
            style: TextStyle(fontSize: 13, color: _textoGris),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _otraCondController,
                  style: const TextStyle(fontSize: 13, color: _textoPrincipal),
                  decoration: const InputDecoration(
                    hintText:
                        'Ingrese solo condiciones relevantes para el rescate; no registre enf',
                    hintStyle: TextStyle(color: _textoGris, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final val = _otraCondController.text.trim();
                  if (val.isNotEmpty) {
                    setState(() {
                      _seleccionadas.add(val);
                      _otraCondController.clear();
                    });
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: _textoGris),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipsSeleccionados(
    Set<String> condiciones,
    ValueChanged<String> onRemove,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBDD1FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Condiciones seleccionadas:',
            style: TextStyle(
              fontSize: 12,
              color: _azul,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: condiciones
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _bordeGris),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textoPrincipal,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => onRemove(c),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: _textoGris,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Lista miembros ───────────────────────────────────────────────────────────

  Widget _buildSeccionMiembros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Miembros de la familia (${_miembros.length})',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _textoPrincipal,
          ),
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _miembros.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _buildItemMiembro(_miembros[index], index),
        ),
      ],
    );
  }

  Widget _buildItemMiembro(MiembroFamilia m, int index) {
    final esTitular = m.rol == 'Titular';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: esTitular ? _fondoVerde : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: esTitular ? _bordeVerde : _bordeGris),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.rol,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _textoPrincipal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${m.edad} años)',
                      style: const TextStyle(fontSize: 13, color: _textoGris),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Año de nacimiento: ${m.anioNacimiento}',
                  style: const TextStyle(fontSize: 12, color: _textoGris),
                ),
                if (m.condiciones.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Condiciones:',
                    style: TextStyle(fontSize: 12, color: _textoGris),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: m.condiciones
                        .map(
                          (c) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _bordeGris),
                            ),
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textoPrincipal,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          // Botones editar / eliminar
          Row(
            children: [
              IconButton(
                onPressed: () => _editarMiembro(index),
                icon: const Icon(Icons.edit_outlined, color: _azul, size: 20),
                tooltip: 'Editar',
                splashRadius: 20,
              ),
              if (!esTitular)
                IconButton(
                  onPressed: () => _eliminarMiembro(index),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  tooltip: 'Eliminar',
                  splashRadius: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required TextInputType teclado,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      style: const TextStyle(fontSize: 14, color: _textoPrincipal),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textoGris, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _bordeGris),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _bordeGris),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _azul, width: 1.5),
        ),
      ),
    );
  }
}
