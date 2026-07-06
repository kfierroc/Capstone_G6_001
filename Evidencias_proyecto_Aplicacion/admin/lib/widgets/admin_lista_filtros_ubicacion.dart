import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_catalog_service.dart';
import '../services/ubicacion_catalog_service.dart';
import '../theme/admin_theme.dart';
import 'admin_action_bar.dart';

/// Barra de filtros región / comuna / ID (+ búsqueda general opcional).
class AdminListaFiltrosUbicacion extends StatefulWidget {
  const AdminListaFiltrosUbicacion({
    super.key,
    required this.idController,
    required this.onChanged,
    this.onIdChanged,
    this.onBusquedaChanged,
    this.busquedaController,
    this.idHint = 'Buscar por ID...',
    this.busquedaHint,
    this.mostrarCampoId = true,
    this.trailing,
  });

  final TextEditingController idController;
  final TextEditingController? busquedaController;
  final String idHint;
  final String? busquedaHint;
  final bool mostrarCampoId;
  final VoidCallback onChanged;
  final VoidCallback? onIdChanged;
  final VoidCallback? onBusquedaChanged;
  final Widget? trailing;

  @override
  State<AdminListaFiltrosUbicacion> createState() => AdminListaFiltrosUbicacionState();
}

class AdminListaFiltrosUbicacionState extends State<AdminListaFiltrosUbicacion> {
  UbicacionCatalogData? _catalogo;
  int? _cutReg;
  int? _cutCom;

  int? get cutRegFiltro => _cutReg;
  int? get cutComFiltro => _cutCom;
  Map<int, int> get comunaARegion => _catalogo?.comunaARegion ?? const {};

  /// Etiqueta legible del filtro activo (p. ej. «Región de Valparaíso · Viña del Mar»).
  String get etiquetaFiltroActivo {
    if (_catalogo == null) return 'Cargando…';
    if (_cutCom != null) {
      for (final c in _catalogo!.comunas) {
        if (c.cutCom == _cutCom) return '${c.regionNombre} · ${c.nombre}';
      }
    }
    if (_cutReg != null) {
      for (final r in _catalogo!.regiones) {
        if (r.id == _cutReg) return r.label;
      }
    }
    return 'Todo Chile';
  }

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    final data = await UbicacionCatalogService(Supabase.instance.client).cargar();
    if (mounted) setState(() => _catalogo = data);
  }

  void _notificar() => widget.onChanged();

  List<CatalogItem> get _comunasOpciones => _catalogo?.comunasDropdown(cutReg: _cutReg) ?? const [];

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;
    final cargando = _catalogo == null;

    final filtros = cargando
        ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        : esAncho
            ? Row(
                children: [
                  Expanded(flex: 2, child: _dropdownRegion()),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _dropdownComuna()),
                  if (widget.mostrarCampoId) ...[
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _campoId()),
                  ],
                  if (widget.busquedaController != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: AdminSearchBar(
                        controller: widget.busquedaController!,
                        hint: widget.busquedaHint ?? 'Buscar...',
                        onChanged: (_) => (widget.onBusquedaChanged ?? widget.onChanged)(),
                      ),
                    ),
                  ],
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 16),
                    widget.trailing!,
                  ],
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dropdownRegion(),
                  const SizedBox(height: 12),
                  _dropdownComuna(),
                  if (widget.mostrarCampoId) ...[
                    const SizedBox(height: 12),
                    _campoId(),
                  ],
                  if (widget.busquedaController != null) ...[
                    const SizedBox(height: 12),
                    AdminSearchBar(
                      controller: widget.busquedaController!,
                      hint: widget.busquedaHint ?? 'Buscar...',
                      onChanged: (_) => (widget.onBusquedaChanged ?? widget.onChanged)(),
                    ),
                  ],
                  if (widget.trailing != null) ...[
                    const SizedBox(height: 12),
                    widget.trailing!,
                  ],
                ],
              );

    return filtros;
  }

  Widget _dropdownRegion() {
    final regiones = _catalogo?.regiones ?? const [];
    return _filtroDropdown(
      label: 'Región',
      value: _cutReg,
      hint: 'Todas las regiones',
      items: regiones.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.label))).toList(),
      onChanged: (v) {
        setState(() {
          _cutReg = v;
          if (_cutCom != null && v != null) {
            final reg = _catalogo?.comunaARegion[_cutCom];
            if (reg != v) _cutCom = null;
          }
        });
        _notificar();
      },
    );
  }

  Widget _dropdownComuna() {
    final comunas = _comunasOpciones;
    return _filtroDropdown(
      label: 'Comuna',
      value: _cutCom,
      hint: _cutReg == null ? 'Todas las comunas' : 'Todas en la región',
      items: comunas.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.label))).toList(),
      onChanged: (v) {
        setState(() => _cutCom = v);
        _notificar();
      },
    );
  }

  Widget _campoId() {
    return TextField(
      controller: widget.idController,
      onChanged: (_) => (widget.onIdChanged ?? widget.onChanged)(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'ID',
        hintText: widget.idHint,
        hintStyle: const TextStyle(color: AdminTheme.mutedText, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.infoBlue, width: 1.5),
        ),
      ),
    );
  }

  Widget _filtroDropdown({
    required String label,
    required int? value,
    required String hint,
    required List<DropdownMenuItem<int?>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminTheme.cardBorder),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 14, color: AdminTheme.mutedText)),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(hint, style: const TextStyle(color: AdminTheme.mutedText)),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
