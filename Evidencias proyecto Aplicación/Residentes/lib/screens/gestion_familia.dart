import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

/// Home del residente: barra superior verde + contenido en tarjeta blanca + navegación inferior.
/// La lógica de familia es solo local (maqueta, sin integraciones).
class GestionFamiliaScreen extends StatefulWidget {
  const GestionFamiliaScreen({super.key});

  @override
  State<GestionFamiliaScreen> createState() => _GestionFamiliaScreenState();
}

class _GestionFamiliaScreenState extends State<GestionFamiliaScreen> {
  static const _verdeApp = Color(0xFF00A84E);
  static const _azul = Color(0xFF3D7BF5);
  static const _rojoCat = Color(0xFFD94F3D);
  static const _naranjaCat = Color(0xFFE07B3A);
  static const _bordeGris = Color(0xFFE0E0E0);
  static const _fondoPagina = Color(0xFFF2F4F7);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);
  static const _fondoVerde = Color(0xFFEFF8F0);
  static const _bordeVerde = Color(0xFFB6DFB8);
  static const _inputFill = Color(0xFFF9FAFB);

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

  final _anioController = TextEditingController(text: '1990');
  final _otraCondController = TextEditingController();

  final Map<String, bool> _expandido = {
    'Enfermedades Crónicas': false,
    'Movilidad y Sentidos': false,
  };

  final Set<String> _seleccionadas = {'Asma o problemas para respirar'};

  final List<_MiembroLocal> _miembros = [
    _MiembroLocal(
      rol: 'Titular',
      anioNacimiento: 1979,
      condiciones: ['Diabetes', 'Problemas cardíacos'],
    ),
    _MiembroLocal(
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

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _limpiarFormulario() {
    _anioController.text = '1990';
    _otraCondController.clear();
    _seleccionadas.clear();
    for (final k in _expandido.keys) {
      _expandido[k] = false;
    }
  }

  void _agregarResidenteMaqueta() {
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
        _MiembroLocal(
          rol: 'Residente $_contadorResidentes',
          anioNacimiento: anio,
          condiciones: List<String>.from(_seleccionadas),
        ),
      );
      _contadorResidentes++;
      _limpiarFormulario();
    });
    _snack('Integrante agregado (solo en pantalla).');
  }

  void _editarMiembro(int index) {
    final m = _miembros[index];
    final anioEdit = TextEditingController(text: '${m.anioNacimiento}');
    final condEdit = Set<String>.from(m.condiciones);
    final expEdit = Map<String, bool>.from(_expandido);

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: anioEdit,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Ej: 1985'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Condiciones',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._categorias.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCategoriaTile(
                          titulo: entry.key,
                          opciones: entry.value,
                          seleccionadas: condEdit,
                          expandido: expEdit[entry.key] ?? false,
                          onToggleExpand: () => setDialog(
                            () => expEdit[entry.key] = !(expEdit[entry.key] ?? false),
                          ),
                          onToggleItem: (item) => setDialog(() {
                            if (condEdit.contains(item)) {
                              condEdit.remove(item);
                            } else {
                              condEdit.add(item);
                            }
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: _textoGris)),
              ),
              ElevatedButton(
                onPressed: () {
                  final anio = int.tryParse(anioEdit.text.trim());
                  if (anio == null) {
                    _snack('Año inválido.');
                    return;
                  }
                  setState(() {
                    m.anioNacimiento = anio;
                    m.condiciones = condEdit.toList();
                  });
                  Navigator.pop(context);
                  _snack('Cambios aplicados en la maqueta.');
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    ).then((_) => anioEdit.dispose());
  }

  void _eliminarMiembro(int index) {
    final rol = _miembros[index].rol;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar miembro',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textoPrincipal),
        ),
        content: Text(
          '¿Quitar a $rol de la lista?',
          style: const TextStyle(color: _textoGris),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: _textoGris)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() => _miembros.removeAt(index));
              Navigator.pop(context);
              _snack('Miembro quitado de la lista.');
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoPagina,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Mi Información Familiar',
            subtitle: 'Gestiona la información de tu domicilio',
            showBack: true,
            onBack: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            trailing: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _snack('Acción de ejemplo (sin integración).'),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.notifications_none_rounded, color: _verdeApp, size: 22),
                ),
              ),
            ),
          ),
          Expanded(child: _buildFamiliaTab()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFamiliaTab() {
    return ColoredBox(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_outline, size: 24, color: _textoPrincipal),
                  SizedBox(width: 8),
                  Text(
                    'Gestión de Familia',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textoPrincipal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Agrega y gestiona los miembros de tu familia',
                style: TextStyle(fontSize: 13, color: _textoGris),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _bordeGris),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar nuevo integrante',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Año de nacimiento',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _anioController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: _textoPrincipal),
                      decoration: InputDecoration(
                        hintText: 'Ej: 1990',
                        hintStyle: const TextStyle(color: _textoGris, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    ),
                    const SizedBox(height: 16),
                    ..._categorias.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildCategoriaTile(
                          titulo: entry.key,
                          opciones: entry.value,
                          seleccionadas: _seleccionadas,
                          expandido: _expandido[entry.key] ?? false,
                          onToggleExpand: () => setState(
                            () => _expandido[entry.key] = !(_expandido[entry.key] ?? false),
                          ),
                          onToggleItem: (item) => setState(() {
                            if (_seleccionadas.contains(item)) {
                              _seleccionadas.remove(item);
                            } else {
                              _seleccionadas.add(item);
                            }
                          }),
                        ),
                      );
                    }),
                    _buildOtraCondicion(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _agregarResidenteMaqueta,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(
                          'Agregar Residente',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _azul,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildItemMiembro(_miembros[index], index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/gestion-mascotas');
      case 2:
        Navigator.pushReplacementNamed(context, '/gestion-domicilio');
      case 3:
        Navigator.pushReplacementNamed(context, '/gestion-peligrosos');
      case 4:
        Navigator.pushReplacementNamed(context, '/gestion-configuracion');
    }
  }

  Widget _buildBottomNav() {
    const items = <({IconData icon, IconData iconActive, String label})>[
      (icon: Icons.people_outline, iconActive: Icons.people, label: 'Familia'),
      (icon: Icons.favorite_border, iconActive: Icons.favorite, label: 'Mascotas'),
      (icon: Icons.home_outlined, iconActive: Icons.home, label: 'Domicilio'),
      (icon: Icons.warning_amber_outlined, iconActive: Icons.warning_amber, label: 'Peligrosos'),
      (icon: Icons.settings_outlined, iconActive: Icons.settings, label: 'Configuración'),
    ];

    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final selected = i == 0;
              return Expanded(
                child: InkWell(
                  onTap: () => _onNavTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFE8F5E9) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selected ? it.iconActive : it.icon,
                            size: 24,
                            color: selected ? _verdeApp : _textoGris,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? _verdeApp : _textoGris,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(10),
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
                    expandido ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: colorTitulo,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
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
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onToggleItem(opcion),
                    borderRadius: BorderRadius.circular(8),
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
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              opcion,
                              style: const TextStyle(fontSize: 14, color: _textoPrincipal),
                            ),
                          ),
                        ],
                      ),
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
      margin: const EdgeInsets.only(top: 8),
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
                    hintText: 'Describe otra condición relevante',
                    hintStyle: TextStyle(color: _textoGris, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final val = _otraCondController.text.trim();
                  if (val.isEmpty) return;
                  setState(() {
                    _seleccionadas.add(val);
                    _otraCondController.clear();
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F0F0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18, color: _textoGris),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemMiembro(_MiembroLocal m, int index) {
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
                      '(${m.edadAproximada} años)',
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
                    children: m.condiciones.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _bordeGris),
                        ),
                        child: Text(
                          c,
                          style: const TextStyle(fontSize: 11, color: _textoPrincipal),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _editarMiembro(index),
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.edit_outlined, color: _azul, size: 20),
                  ),
                ),
              ),
              if (!esTitular) ...[
                const SizedBox(height: 6),
                IconButton(
                  onPressed: () => _eliminarMiembro(index),
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                  tooltip: 'Eliminar',
                  splashRadius: 20,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiembroLocal {
  _MiembroLocal({
    required this.rol,
    required this.anioNacimiento,
    required this.condiciones,
  });

  final String rol;
  int anioNacimiento;
  List<String> condiciones;

  int get edadAproximada {
    final year = DateTime.now().year;
    return (year - anioNacimiento).clamp(0, 130);
  }
}
