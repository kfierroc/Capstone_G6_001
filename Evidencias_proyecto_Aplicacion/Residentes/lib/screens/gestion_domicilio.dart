import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/catalogos_residente_service.dart';
import '../services/gestion_residente_service.dart';
import '../services/registro_residente_service.dart';
import '../widgets/custom_widgets.dart';

/// Pantalla de domicilio con datos de `residencia`, `registro_v` y `piso_v`.
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

  static const List<String> _etiquetasMeses = [
    '1 mes',
    '2 meses',
    '3 meses',
    '4 meses',
    '5 meses',
    '6 meses',
    '1 año',
    'Más de 1 año',
  ];

  DomicilioVista? _dom;
  bool _loading = true;
  String? _error;
  String? _sinDatos;

  List<String> _tiposViviendaCatalogo = [];
  List<String> _estadosViviendaCatalogo = [];
  List<String> _materialesPisoCatalogo = [];

  List<PisoDomicilioVista> _pisosLocales = [];
  String? _materialPisoPendiente;
  String _materialDepartamentoSeleccion = '';

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  static int _mesesDesdeEtiqueta(String etiqueta) {
    switch (etiqueta) {
      case '1 mes':
        return 1;
      case '2 meses':
        return 2;
      case '3 meses':
        return 3;
      case '4 meses':
        return 4;
      case '5 meses':
        return 5;
      case '6 meses':
        return 6;
      case '1 año':
        return 12;
      case 'Más de 1 año':
        return 18;
      default:
        return 3;
    }
  }

  static String _etiquetaDesdeMeses(int meses) {
    final m = meses.clamp(1, 24);
    if (m <= 6) return m == 1 ? '1 mes' : '$m meses';
    if (m <= 12) return '1 año';
    return 'Más de 1 año';
  }

  static int _inferirMesesRenovacion(DomicilioVista d) {
    final a = DateTime(d.fechaUltConfirm.year, d.fechaUltConfirm.month, d.fechaUltConfirm.day);
    final b = DateTime(d.fechaExpiracion.year, d.fechaExpiracion.month, d.fechaExpiracion.day);
    var months = (b.year - a.year) * 12 + (b.month - a.month);
    if (b.day < a.day) months--;
    return months.clamp(1, 24);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _sinDatos = null;
    });
    final client = Supabase.instance.client;
    final cat = CatalogosResidenteService(client);
    final ges = GestionResidenteService(client);
    try {
      final tipos = await cat.tiposVivienda();
      final estados = await cat.estadosVivienda();
      final mats = await cat.materialesPiso();
      final dom = await ges.obtenerDomicilio();
      if (!mounted) return;
      setState(() {
        _tiposViviendaCatalogo = tipos;
        _estadosViviendaCatalogo = estados;
        _materialesPisoCatalogo = mats.isNotEmpty ? mats : ['Hormigón'];
        _dom = dom;
        _pisosLocales = dom == null ? [] : List<PisoDomicilioVista>.from(dom.pisos);
        _materialDepartamentoSeleccion = dom?.materialDepartamentoSiAplica ?? (_materialesPisoCatalogo.first);
        _sinDatos = dom == null ? 'No hay domicilio registrado para tu cuenta. Completa el registro inicial.' : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _recargar() async {
    final ges = GestionResidenteService(Supabase.instance.client);
    final dom = await ges.obtenerDomicilio();
    if (!mounted) return;
    setState(() {
      _dom = dom;
      if (dom != null) {
        _pisosLocales = List<PisoDomicilioVista>.from(dom.pisos);
        _materialDepartamentoSeleccion = dom.materialDepartamentoSiAplica ?? _materialDepartamentoSeleccion;
      }
    });
  }

  Future<void> _persistirPisos() async {
    final dom = _dom;
    if (dom == null) return;
    try {
      await GestionResidenteService(Supabase.instance.client).reemplazarPisos(
        idRegistro: dom.idRegistro,
        pisos: _pisosLocales,
      );
      await _recargar();
      if (!mounted) return;
      _snack('Pisos actualizados.');
    } on RegistroResidenteException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('No se pudieron guardar los pisos: $e');
    }
  }

  Future<void> _persistirDepartamentoUnPiso() async {
    final dom = _dom;
    if (dom == null) return;
    try {
      await GestionResidenteService(Supabase.instance.client).reemplazarPisos(
        idRegistro: dom.idRegistro,
        pisos: [
          PisoDomicilioVista(numerop: 1, materialPiso: _materialDepartamentoSeleccion),
        ],
      );
      await _recargar();
      if (!mounted) return;
      _snack('Material del departamento guardado.');
    } on RegistroResidenteException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('No se pudo guardar: $e');
    }
  }

  void _addFloor() {
    if (_materialPisoPendiente == null) return;
    setState(() {
      _pisosLocales.add(
        PisoDomicilioVista(numerop: _pisosLocales.length + 1, materialPiso: _materialPisoPendiente!),
      );
      _materialPisoPendiente = null;
    });
    _persistirPisos();
  }

  void _removeFloor(int index) {
    setState(() {
      _pisosLocales.removeAt(index);
      final materiales = _pisosLocales.map((p) => p.materialPiso).toList();
      _pisosLocales = [
        for (var i = 0; i < materiales.length; i++)
          PisoDomicilioVista(numerop: i + 1, materialPiso: materiales[i]),
      ];
    });
    _persistirPisos();
  }

  String get _lineaDireccion {
    final d = _dom;
    if (d == null) return '';
    final u = d.unidad?.trim();
    final base = '${d.calle} ${d.nroDireccion}';
    if (u != null && u.isNotEmpty) return '$base, $u';
    return base;
  }

  String get _interiorLinea {
    final d = _dom;
    if (d == null) return '';
    final desc = d.descDeptoCond?.trim();
    return desc == null || desc.isEmpty ? '—' : desc;
  }

  String get _tiempoEtiqueta {
    final d = _dom;
    if (d == null) return '—';
    return _etiquetaDesdeMeses(_inferirMesesRenovacion(d));
  }

  bool get _esDepartamento => _dom?.esDepartamento ?? false;

  void _editarDireccion() {
    final dom = _dom;
    if (dom == null) return;

    final calleCtrl = TextEditingController(text: dom.calle);
    final nroCtrl = TextEditingController(text: '${dom.nroDireccion}');
    final unidadCtrl = TextEditingController(text: dom.unidad ?? '');
    final descCtrl = TextEditingController(text: dom.descDeptoCond ?? '');
    final latCtrl = TextEditingController(text: dom.lat.toString());
    final lonCtrl = TextEditingController(text: dom.lon.toString());

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar dirección', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Calle', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: calleCtrl),
              const SizedBox(height: 12),
              const Text('Número', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: nroCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              const Text('Unidad / Depto (opcional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: unidadCtrl),
              const SizedBox(height: 12),
              const Text('Interior / referencia', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: descCtrl),
              const SizedBox(height: 12),
              const Text('Latitud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: latCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              const Text('Longitud', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: lonCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              const Text(
                'La comuna se recalcula al guardar según las coordenadas.',
                style: TextStyle(fontSize: 11, color: _textoGris),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final nro = int.tryParse(nroCtrl.text.trim());
              final lat = double.tryParse(latCtrl.text.trim().replaceAll(',', '.'));
              final lon = double.tryParse(lonCtrl.text.trim().replaceAll(',', '.'));
              if (calleCtrl.text.trim().isEmpty || nro == null || lat == null || lon == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Completa calle, número y coordenadas válidas.')),
                );
                return;
              }
              try {
                final ges = GestionResidenteService(Supabase.instance.client);
                await ges.guardarUbicacionResidencia(
                  idResidencia: dom.idResidencia,
                  calle: calleCtrl.text.trim(),
                  nroDireccion: nro,
                  lat: lat,
                  lon: lon,
                );
                await ges.guardarReferenciasRegistro(
                  idRegistro: dom.idRegistro,
                  unidad: unidadCtrl.text.trim().isEmpty ? null : unidadCtrl.text.trim(),
                  descDeptoCond: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  notasV: dom.notasV,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _recargar();
                if (!mounted) return;
                _snack('Dirección guardada.');
              } on RegistroResidenteException catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) {
      calleCtrl.dispose();
      nroCtrl.dispose();
      unidadCtrl.dispose();
      descCtrl.dispose();
      latCtrl.dispose();
      lonCtrl.dispose();
    });
  }

  void _editarDetallesVivienda() {
    final dom = _dom;
    if (dom == null) return;

    var tiempo = _tiempoEtiqueta;
    var tipo = dom.tipoVivienda;
    var estado = dom.estadoVivienda;
    var materialDept = _materialDepartamentoSeleccion;

    if (!_tiposViviendaCatalogo.contains(tipo) && _tiposViviendaCatalogo.isNotEmpty) {
      tipo = _tiposViviendaCatalogo.first;
    }
    if (!_estadosViviendaCatalogo.contains(estado) && _estadosViviendaCatalogo.isNotEmpty) {
      estado = _estadosViviendaCatalogo.first;
    }
    if (!_materialesPisoCatalogo.contains(materialDept)) {
      materialDept = _materialesPisoCatalogo.first;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
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
                    // ignore: deprecated_member_use
                    value: tiempo,
                    decoration: const InputDecoration(hintText: 'Selecciona'),
                    items: _etiquetasMeses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setD(() => tiempo = v ?? tiempo),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tipo de vivienda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: tipo,
                    decoration: const InputDecoration(hintText: 'Selecciona'),
                    items: _tiposViviendaCatalogo.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setD(() => tipo = v ?? tipo),
                  ),
                  const SizedBox(height: 12),
                  const Text('Estado de la vivienda', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: estado,
                    decoration: const InputDecoration(hintText: 'Selecciona'),
                    items: _estadosViviendaCatalogo.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setD(() => estado = v ?? estado),
                  ),
                  if (tipo == _tipoDepartamento) ...[
                    const SizedBox(height: 12),
                    const Text('Material del departamento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: materialDept,
                      decoration: const InputDecoration(hintText: 'Selecciona'),
                      items: _materialesPisoCatalogo.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setD(() => materialDept = v ?? materialDept),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  final meses = _mesesDesdeEtiqueta(tiempo);
                  try {
                    final ges = GestionResidenteService(Supabase.instance.client);
                    await ges.guardarTipoEstadoVivienda(
                      idRegistro: dom.idRegistro,
                      tipoViviendaEtiqueta: tipo,
                      estadoViviendaEtiqueta: estado,
                    );
                    await ges.renovarPermanenciaMeses(idRegistro: dom.idRegistro, meses: meses);
                    if (tipo == _tipoDepartamento) {
                      await ges.reemplazarPisos(
                        idRegistro: dom.idRegistro,
                        pisos: [
                          PisoDomicilioVista(numerop: 1, materialPiso: materialDept),
                        ],
                      );
                    } else {
                      if (_pisosLocales.isEmpty) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Para este tipo agrega al menos un piso en la sección inferior.'),
                          ),
                        );
                        return;
                      }
                      await ges.reemplazarPisos(idRegistro: dom.idRegistro, pisos: _pisosLocales);
                    }
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    setState(() => _materialDepartamentoSeleccion = materialDept);
                    await _recargar();
                    if (!mounted) return;
                    _snack('Detalles guardados.');
                  } on RegistroResidenteException catch (e) {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(e.message)));
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editarNotas() {
    final dom = _dom;
    if (dom == null) return;
    final ctrl = TextEditingController(text: dom.notasV ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Instrucciones especiales', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Información útil para emergencias (máx. 100 caracteres en BD)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await GestionResidenteService(Supabase.instance.client).guardarReferenciasRegistro(
                  idRegistro: dom.idRegistro,
                  unidad: dom.unidad,
                  descDeptoCond: dom.descDeptoCond,
                  notasV: ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _recargar();
                if (!mounted) return;
                _snack('Instrucciones guardadas.');
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
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
            child: Text('+ Agregar Piso ${_pisosLocales.length + 1}'),
          ),
          if (_pisosLocales.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Pisos registrados (${_pisosLocales.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ..._pisosLocales.asMap().entries.map((entry) {
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
                          Text('Piso ${floor.numerop}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            'Material: ${floor.materialPiso}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
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

  Widget _buildDepartamentoMaterial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Material principal del departamento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _materialDepartamentoSeleccion.isEmpty ? null : _materialDepartamentoSeleccion,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Selecciona',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _materialesPisoCatalogo
              .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() => _materialDepartamentoSeleccion = val);
            _persistirDepartamentoUnPiso();
          },
        ),
      ],
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
        'Se agregará: Piso ${_pisosLocales.length + 1}',
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
          // ignore: deprecated_member_use
          value: _materialPisoPendiente,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Selecciona',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _materialesPisoCatalogo
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _bootstrap,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_sinDatos != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_sinDatos!, textAlign: TextAlign.center, style: const TextStyle(color: _textoGris)),
        ),
      );
    }

    final dom = _dom!;

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
                    child: Text(
                      'Dirección',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _textoPrincipal),
                    ),
                  ),
                  _botonEditar(onTap: _editarDireccion),
                ],
              ),
              const SizedBox(height: 10),
              Text(_lineaDireccion, style: const TextStyle(fontSize: 14, color: _textoPrincipal, height: 1.4)),
              const SizedBox(height: 6),
              Text(_interiorLinea, style: const TextStyle(fontSize: 13, color: _textoGris)),
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
                    Text('Latitud: ${dom.lat}', style: const TextStyle(fontSize: 13, color: _textoGris)),
                    Text('Longitud: ${dom.lon}', style: const TextStyle(fontSize: 13, color: _textoGris)),
                    Text('Comuna: ${dom.comunaNombre}', style: const TextStyle(fontSize: 13, color: _textoGris)),
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
                    _filaDetalle('Tiempo en la residencia:', _tiempoEtiqueta),
                    _filaDetalle('Tipo de vivienda:', dom.tipoVivienda),
                    _filaDetalle('Estado de la vivienda:', dom.estadoVivienda),
                    if (_esDepartamento) ...[
                      _filaDetalle('Material del departamento:', dom.materialDepartamentoSiAplica ?? '—'),
                      const SizedBox(height: 8),
                      _buildDepartamentoMaterial(),
                    ] else ...[
                      const SizedBox(height: 4),
                      _buildPisosComoRegistro(),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Instrucciones especiales',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textoPrincipal),
                    ),
                  ),
                  _botonEditar(onTap: _editarNotas),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (dom.notasV == null || dom.notasV!.trim().isEmpty) ? 'Sin instrucciones registradas.' : dom.notasV!,
                style: const TextStyle(fontSize: 14, color: _textoGris, height: 1.4),
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
