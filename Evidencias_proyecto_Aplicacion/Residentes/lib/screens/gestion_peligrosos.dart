import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

/// Maqueta: materiales peligrosos en el domicilio.
class GestionPeligrososScreen extends StatefulWidget {
  const GestionPeligrososScreen({super.key});

  @override
  State<GestionPeligrososScreen> createState() => _GestionPeligrososScreenState();
}

class _GestionPeligrososScreenState extends State<GestionPeligrososScreen> {
  static const _verdeApp = Color(0xFF00A84E);
  static const _fondoPagina = Color(0xFFF2F4F7);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);

  static const _duraznoFondo = Color(0xFFFFF5F0);
  static const _duraznoBorde = Color(0xFFFFD8C2);
  static const _duraznoBoton = Color(0xFFEA8C55);
  static const _duraznoTituloLista = Color(0xFF9A3412);
  static const _duraznoItemBorde = Color(0xFFFDBA74);
  static const _navPeligrososBg = Color(0xFFFFEDD5);
  static const _navPeligrosos = Color(0xFFEA580C);

  static const List<String> _tiposMaterial = [
    'Balón/Cilindro de gas',
    'Productos químicos',
    'Combustibles',
    'Pinturas o solventes',
    'Baterías o pilas',
    'Otro',
  ];

  String? _tipoSeleccionado;
  final _cantidadController = TextEditingController(text: '1');
  final _notasController = TextEditingController();

  final List<_MaterialPeligroso> _registrados = [
    _MaterialPeligroso(tipo: 'Balón/Cilindro de gas', cantidad: 1, notas: ''),
  ];

  @override
  void dispose() {
    _cantidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  void _agregar() {
    if (_tipoSeleccionado == null) {
      _snack('Selecciona el tipo de material.');
      return;
    }
    final c = int.tryParse(_cantidadController.text.trim());
    if (c == null || c < 1) {
      _snack('Ingresa una cantidad válida.');
      return;
    }
    setState(() {
      _registrados.add(
        _MaterialPeligroso(
          tipo: _tipoSeleccionado!,
          cantidad: c,
          notas: _notasController.text.trim(),
        ),
      );
      _tipoSeleccionado = null;
      _cantidadController.text = '1';
      _notasController.clear();
    });
    _snack('Material agregado (maqueta).');
  }

  void _eliminar(int index) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar material', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('¿Quitar "${_registrados[index].tipo}" de la lista?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _registrados.removeAt(index));
              Navigator.pop(ctx);
              _snack('Material eliminado.');
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/gestion-familia');
      case 1:
        Navigator.pushReplacementNamed(context, '/gestion-mascotas');
      case 2:
        Navigator.pushReplacementNamed(context, '/gestion-domicilio');
      case 3:
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/gestion-configuracion');
    }
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
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
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
                  Icon(Icons.warning_amber_rounded, size: 24, color: _textoPrincipal),
                  SizedBox(width: 8),
                  Text(
                    'Materiales Peligrosos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textoPrincipal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestiona los materiales peligrosos presentes en tu domicilio',
                style: TextStyle(fontSize: 13, color: _textoGris),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _duraznoFondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _duraznoBorde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar material peligroso',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tipo de material *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoSeleccionado,
                      decoration: InputDecoration(
                        hintText: 'Selecciona',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _tiposMaterial.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _tipoSeleccionado = v),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Cantidad *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Notas adicionales (opcional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notasController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Información adicional relevante para bomberos',
                        hintStyle: TextStyle(color: _textoGris, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _agregar,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Agregar Material', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _duraznoBoton,
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
                'Registrados (${_registrados.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _duraznoTituloLista,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _registrados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final m = _registrados[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _duraznoItemBorde),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.tipo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _duraznoTituloLista,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cantidad: ${m.cantidad}',
                                style: const TextStyle(fontSize: 13, color: _textoGris),
                              ),
                              if (m.notas.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(m.notas, style: const TextStyle(fontSize: 12, color: _textoGris, height: 1.3)),
                              ],
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: InkWell(
                              onTap: () => _eliminar(index),
                              borderRadius: BorderRadius.circular(10),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              final selected = i == 3;
              final highlightBg = selected ? _navPeligrososBg : Colors.transparent;
              final iconColor = selected ? _navPeligrosos : _textoGris;
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
                            color: highlightBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selected ? it.iconActive : it.icon,
                            size: 24,
                            color: iconColor,
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
                            color: iconColor,
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
}

class _MaterialPeligroso {
  _MaterialPeligroso({required this.tipo, required this.cantidad, required this.notas});

  final String tipo;
  final int cantidad;
  final String notas;
}
