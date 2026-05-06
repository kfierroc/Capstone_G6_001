import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

/// Maqueta: información del domicilio. Misma envoltura que Familia/Mascotas.
///
/// **Departamento:** muestra material único (sin bloque de pisos), alineado al mock.
/// **Cualquier otro tipo** (Casa, etc.): bloque de pisos como en [RegistroPaso4].
class GestionDomicilioScreen extends StatefulWidget {
  const GestionDomicilioScreen({super.key});

  @override
  State<GestionDomicilioScreen> createState() => _GestionDomicilioScreenState();
}

class _GestionDomicilioScreenState extends State<GestionDomicilioScreen> {
  static const _verdeApp = Color(0xFF00A84E);
  static const _azul = Color(0xFF3D7BF5);
  static const _azulTitulo = Color(0xFF2C5BA9);
  static const _azulFondo = Color(0xFFF0F7FF);
  static const _azulBorde = Color(0xFFD0E3FF);
  static const _bordeGris = Color(0xFFE0E0E0);
  static const _fondoPagina = Color(0xFFF2F4F7);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);
  static const _inputFill = Color(0xFFF9FAFB);
  static const _navDomicilioBg = Color(0xFFE8F4FF);

  static const String _tipoDepartamento = 'Departamento';

  static const List<String> _tiposVivienda = [
    'Casa',
    'Departamento',
    'Empresa',
    'Local comercial',
    'Oficina',
    'Bodega',
    'Otro',
  ];

  /// Materiales para piso (mismo criterio que registro paso 4).
  static const List<String> _materialesPiso = ['Ladrillo', 'Madera', 'Hormigón', 'Metal'];

  /// Material global del departamento (solo si tipo == Departamento).
  static const List<String> _materialesDepartamento = [
    'Ladrillo',
    'Madera',
    'Hormigón/Concreto',
    'Metal',
  ];

  String _direccion = 'Av. Libertador 1234, Depto 5B, Las Condes, Santiago';
  String _interior = 'Casa interior: A';
  String _latitud = '-33.4489';
  String _longitud = '-70.6693';
  String _comuna = 'Las Condes';

  String _tiempoResidencia = '3 meses';
  String _tipoVivienda = _tipoDepartamento;
  String _estadoVivienda = 'Bueno';
  String _materialDepartamento = 'Hormigón/Concreto';

  final String _instrucciones = 'Llave de emergencia con portero.';

  final List<Map<String, String>> _pisos = [];

  String? _materialPisoPendiente;

  bool get _esDepartamento => _tipoVivienda == _tipoDepartamento;

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  void _addFloor() {
    if (_materialPisoPendiente == null) return;
    setState(() {
      _pisos.add({
        'number': '${_pisos.length + 1}',
        'material': _materialPisoPendiente!,
      });
      _materialPisoPendiente = null;
    });
  }

  void _removeFloor(int index) {
    setState(() {
      _pisos.removeAt(index);
      for (var i = 0; i < _pisos.length; i++) {
        _pisos[i]['number'] = '${i + 1}';
      }
    });
  }

  void _editarDireccion() {
    final dirCtrl = TextEditingController(text: _direccion);
    final intCtrl = TextEditingController(text: _interior);
    final latCtrl = TextEditingController(text: _latitud);
    final lonCtrl = TextEditingController(text: _longitud);
    final comCtrl = TextEditingController(text: _comuna);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar dirección', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dirección', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: dirCtrl, maxLines: 2),
              const SizedBox(height: 12),
              const Text('Interior / referencia', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: intCtrl),
              const SizedBox(height: 12),
              const Text('Latitud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: latCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              const Text('Longitud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: lonCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              const Text('Comuna', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: comCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _direccion = dirCtrl.text.trim();
                _interior = intCtrl.text.trim();
                _latitud = latCtrl.text.trim();
                _longitud = lonCtrl.text.trim();
                _comuna = comCtrl.text.trim();
              });
              Navigator.pop(ctx);
              _snack('Dirección actualizada (maqueta).');
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) {
      dirCtrl.dispose();
      intCtrl.dispose();
      latCtrl.dispose();
      lonCtrl.dispose();
      comCtrl.dispose();
    });
  }

  void _editarDetallesVivienda() {
    String tiempo = _tiempoResidencia;
    String tipo = _tipoVivienda;
    String estado = _estadoVivienda;
    String materialDept = _materialDepartamento;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Detalles de la vivienda', style: TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tiempo en la residencia', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: tiempo,
                    decoration: const InputDecoration(hintText: 'Selecciona'),
                    items: ['1 mes', '2 meses', '3 meses', '4 meses', '5 meses', '6 meses', '1 año', 'Más de 1 año']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setD(() => tiempo = v ?? tiempo),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tipo de vivienda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(hintText: 'Selecciona'),
                    items: _tiposVivienda.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setD(() => tipo = v ?? tipo),
                  ),
                  const SizedBox(height: 12),
                  const Text('Estado de la vivienda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: estado,
                    decoration: const InputDecoration(hintText: 'Selecciona'),
                    items: ['Excelente', 'Bueno', 'Regular', 'Deteriorado']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setD(() => estado = v ?? estado),
                  ),
                  if (tipo == _tipoDepartamento) ...[
                    const SizedBox(height: 12),
                    const Text('Material del departamento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: materialDept,
                      decoration: const InputDecoration(hintText: 'Selecciona'),
                      items: _materialesDepartamento
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setD(() => materialDept = v ?? materialDept),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    final anteriorTipo = _tipoVivienda;
                    _tiempoResidencia = tiempo;
                    _tipoVivienda = tipo;
                    _estadoVivienda = estado;
                    if (tipo == _tipoDepartamento) {
                      _materialDepartamento = materialDept;
                      _pisos.clear();
                      _materialPisoPendiente = null;
                    } else {
                      if (anteriorTipo == _tipoDepartamento) {
                        _materialPisoPendiente = null;
                      }
                    }
                  });
                  Navigator.pop(ctx);
                  _snack('Detalles actualizados (maqueta).');
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _botonEditar({required VoidCallback onTap, bool azul = false}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.edit_outlined, size: 18, color: azul ? _azul : _textoPrincipal),
      label: Text('Editar', style: TextStyle(color: azul ? _azul : _textoPrincipal, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: azul ? _azul : _textoPrincipal,
        side: BorderSide(color: azul ? _azulBorde : _bordeGris),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _filaDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _textoPrincipal)),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 14, color: _textoGris, height: 1.35)),
        ],
      ),
    );
  }

  /// Bloque de pisos reutilizando el patrón de [RegistroPaso4] (solo si no es departamento).
  Widget _buildPisosComoRegistro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pisos de la vivienda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 350;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNextFloorIndicator(),
                    const SizedBox(height: 12),
                    _buildMaterialDropdownPiso(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 2, child: _buildNextFloorIndicator()),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: _buildMaterialDropdownPiso()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _materialPisoPendiente != null ? _addFloor : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BA9FF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('+ Agregar Piso ${_pisos.length + 1}'),
          ),
          if (_pisos.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Pisos agregados (${_pisos.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ..._pisos.asMap().entries.map((entry) {
              final idx = entry.key;
              final floor = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _azulBorde),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Piso ${floor['number']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Material: ${floor['material']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
    );
  }

  Widget _buildNextFloorIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: _azulFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _azulBorde),
      ),
      child: Text(
        'Se agregará: Piso ${_pisos.length + 1}',
        style: const TextStyle(color: _azulTitulo, fontSize: 13),
      ),
    );
  }

  Widget _buildMaterialDropdownPiso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Material del piso *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _materialPisoPendiente,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Selecciona',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _materialesPiso
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _materialPisoPendiente = val),
        ),
      ],
    );
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/gestion-familia');
      case 1:
        Navigator.pushReplacementNamed(context, '/gestion-mascotas');
      case 2:
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/gestion-peligrosos');
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
                  Icon(Icons.home_outlined, size: 24, color: _textoPrincipal),
                  SizedBox(width: 8),
                  Text(
                    'Información del Domicilio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textoPrincipal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Revisa y actualiza los datos de tu domicilio',
                style: TextStyle(fontSize: 13, color: _textoGris),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text('Dirección', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textoPrincipal)),
                  ),
                  _botonEditar(onTap: _editarDireccion),
                ],
              ),
              const SizedBox(height: 10),
              Text(_direccion, style: const TextStyle(fontSize: 14, color: _textoPrincipal, height: 1.4)),
              const SizedBox(height: 6),
              Text(_interior, style: const TextStyle(fontSize: 13, color: _textoGris)),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _bordeGris),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: _textoGris),
                        SizedBox(width: 8),
                        Text('Información de ubicación', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Latitud: $_latitud', style: const TextStyle(fontSize: 13, color: _textoGris)),
                    Text('Longitud: $_longitud', style: const TextStyle(fontSize: 13, color: _textoGris)),
                    Text('Comuna: $_comuna', style: const TextStyle(fontSize: 13, color: _textoGris)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _azulFondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _azulBorde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Detalles de la Vivienda',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: _azulTitulo,
                            ),
                          ),
                        ),
                        _botonEditar(onTap: _editarDetallesVivienda, azul: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _filaDetalle('Tiempo en la residencia:', _tiempoResidencia),
                    _filaDetalle('Tipo de vivienda:', _tipoVivienda),
                    _filaDetalle('Estado de la vivienda:', _estadoVivienda),
                    if (_esDepartamento)
                      _filaDetalle('Material del departamento:', _materialDepartamento)
                    else ...[
                      const SizedBox(height: 4),
                      _buildPisosComoRegistro(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Instrucciones especiales',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textoPrincipal),
              ),
              const SizedBox(height: 8),
              Text(_instrucciones, style: const TextStyle(fontSize: 14, color: _textoGris, height: 1.4)),
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
              final selected = i == 2;
              final highlightBg = selected ? _navDomicilioBg : Colors.transparent;
              final iconColor = selected ? _azul : _textoGris;
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
