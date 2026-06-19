import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_bombero_perfil.dart';
import '../../models/grifo_list_item.dart';
import '../../services/admin_catalog_service.dart';
import '../../services/admin_edit_service.dart';
import '../../services/comuna_coordenadas_service.dart';
import '../../services/grifos_admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_detail_shell.dart';
import '../../widgets/admin_edit_sheets.dart';

/// Vista de detalle / creación de un grifo con mapa y registro de estado.
class GrifoEditScreen extends StatefulWidget {
  const GrifoEditScreen({
    super.key,
    this.idGrifo,
    required this.perfil,
    required this.alertCount,
    required this.volverLabel,
    required this.onVolver,
    this.onGuardado,
  });

  final int? idGrifo;
  final AdminBomberoPerfil perfil;
  final int alertCount;
  final String volverLabel;
  final VoidCallback onVolver;
  final ValueChanged<int>? onGuardado;

  bool get esCreacion => idGrifo == null;

  @override
  State<GrifoEditScreen> createState() => _GrifoEditScreenState();
}

class _GrifoEditScreenState extends State<GrifoEditScreen> {
  final _mapController = MapController();

  bool _loading = true;
  bool _editandoUbicacion = false;
  bool _guardando = false;
  bool _calculandoComuna = false;
  String? _errorCarga;

  String _comunaNombre = '—';
  double? _lat;
  double? _lon;
  String _estadoActual = '—';
  String _fechaUltimo = '—';
  String? _notaActual;
  List<InfoGrifoRegistro> _historial = [];

  int? _idEstadoNuevo;
  List<CatalogItem> _estados = [];
  final _notaCtrl = TextEditingController();

  static const _centroChile = LatLng(-33.4489, -70.6693);

  @override
  void initState() {
    super.initState();
    if (widget.esCreacion) {
      _editandoUbicacion = true;
      _lat = _centroChile.latitude;
      _lon = _centroChile.longitude;
      _cargarCatalogos();
    } else {
      _cargar();
    }
  }

  Future<void> _cargarCatalogos() async {
    final estados = await AdminCatalogService(Supabase.instance.client).estadosGrifo();
    if (!mounted) return;
    setState(() {
      _estados = estados;
      _idEstadoNuevo ??= estados.firstOrNull?.id;
      _loading = false;
    });
    if (_lat != null && _lon != null) {
      _actualizarComunaDesdeCoordenadas(_lat!, _lon!);
      _centrarMapa();
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _errorCarga = null;
      _editandoUbicacion = false;
    });
    final det = await GrifosAdminService(Supabase.instance.client).obtenerDetalle(widget.idGrifo!);
    final estados = await AdminCatalogService(Supabase.instance.client).estadosGrifo();
    if (!mounted) return;

    if (det == null) {
      setState(() {
        _loading = false;
        _errorCarga = 'No se pudo cargar el grifo.';
      });
      return;
    }

    _lat = det.lat;
    _lon = det.lon;
    _comunaNombre = det.comuna;
    _estadoActual = det.estadoActual;
    _fechaUltimo = det.fechaUltimoRegistro;
    _notaActual = det.notaActual;
    _historial = det.historial;
    _estados = estados;
    _idEstadoNuevo = det.idEstadoGr;
    _notaCtrl.clear();

    setState(() => _loading = false);
    _centrarMapa();
  }

  void _centrarMapa() {
    if (_lat == null || _lon == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(LatLng(_lat!, _lon!), 16);
    });
  }

  LatLng get _punto => LatLng(_lat ?? _centroChile.latitude, _lon ?? _centroChile.longitude);

  Future<void> _actualizarComunaDesdeCoordenadas(double lat, double lon) async {
    setState(() => _calculandoComuna = true);
    try {
      final res = await ComunaCoordenadasService(Supabase.instance.client).resolverComuna(lat, lon);
      if (!mounted) return;
      setState(() => _comunaNombre = res.nombre);
    } catch (e) {
      if (!mounted) return;
      setState(() => _comunaNombre = '—');
      AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _calculandoComuna = false);
    }
  }

  Future<void> _guardarUbicacion() async {
    if (_lat == null || _lon == null) {
      AdminEditSheets.showError(context, AdminEditException('Selecciona una ubicación en el mapa.'));
      return;
    }

    setState(() => _guardando = true);
    try {
      final res = await ComunaCoordenadasService(Supabase.instance.client).resolverComuna(_lat!, _lon!);
      final edit = AdminEditService(Supabase.instance.client);

      if (widget.esCreacion) {
        if (_idEstadoNuevo == null) {
          throw AdminEditException('Selecciona el estado inicial del grifo.');
        }
        final id = await edit.crearGrifo(
          lat: _lat!,
          lon: _lon!,
          cutCom: res.cutCom,
          idEstadoGr: _idEstadoNuevo!,
          rutNumBombero: widget.perfil.rutNum,
          notaG: _notaCtrl.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grifo registrado correctamente.')),
        );
        widget.onGuardado?.call(id);
        return;
      }

      await edit.actualizarGrifoUbicacion(
        idGrifo: widget.idGrifo!,
        lat: _lat!,
        lon: _lon!,
        cutCom: res.cutCom,
      );
      if (!mounted) return;
      setState(() {
        _comunaNombre = res.nombre;
        _editandoUbicacion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación del grifo actualizada.')),
      );
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _registrarRevision() async {
    if (widget.esCreacion || widget.idGrifo == null) return;
    if (_idEstadoNuevo == null) {
      AdminEditSheets.showError(context, AdminEditException('Selecciona un estado.'));
      return;
    }

    setState(() => _guardando = true);
    try {
      await AdminEditService(Supabase.instance.client).registrarInfoGrifo(
        idGrifo: widget.idGrifo!,
        idEstadoGr: _idEstadoNuevo!,
        rutNumBombero: widget.perfil.rutNum,
        notaG: _notaCtrl.text,
      );
      if (!mounted) return;
      _notaCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisión registrada correctamente.')),
      );
      await _cargar();
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _onTapMapa(TapPosition _, LatLng point) {
    if (!_editandoUbicacion && !widget.esCreacion) return;
    setState(() {
      _lat = point.latitude;
      _lon = point.longitude;
    });
    _actualizarComunaDesdeCoordenadas(point.latitude, point.longitude);
  }

  @override
  void dispose() {
    _notaCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;
    final titulo = widget.esCreacion ? 'Nuevo grifo' : 'Grifo ${widget.idGrifo}';
    final puedeEditarMapa = widget.esCreacion || _editandoUbicacion;

    return AdminDetailShell(
      headerTitle: 'Grifos',
      alertCount: widget.alertCount,
      volverLabel: widget.volverLabel,
      onVolver: widget.onVolver,
      loading: _loading,
      subtitulo: titulo,
      descripcion: widget.esCreacion ? 'Ubicación y estado inicial' : '$_comunaNombre · $_estadoActual',
      errorMessage: _errorCarga,
      child: _loading || _errorCarga != null
          ? null
          : esAncho
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SingleChildScrollView(child: _panelInfo())),
                    const SizedBox(width: 16),
                    Expanded(child: _panelMapa(puedeEditarMapa)),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _panelInfo(),
                      const SizedBox(height: 16),
                      SizedBox(height: 320, child: _panelMapa(puedeEditarMapa)),
                    ],
                  ),
                ),
    );
  }

  Widget _panelMapa(bool editable) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AdminTheme.cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _punto,
                initialZoom: _lat != null ? 16 : 12,
                onTap: _onTapMapa,
                interactionOptions: InteractionOptions(
                  flags: editable ? InteractiveFlag.all : InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.admin.panel',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _punto,
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.water_drop,
                        size: 44,
                        color: editable ? AdminTheme.alertRed : AdminTheme.infoBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (editable)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Toca el mapa para ubicar el grifo',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _panelInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            titulo: widget.esCreacion ? 'Ubicación y estado inicial' : 'Información del grifo',
            icono: Icons.water_drop_outlined,
            acciones: widget.esCreacion
                ? null
                : _editandoUbicacion
                    ? [
                        OutlinedButton(onPressed: _guardando ? null : _cargar, child: const Text('Cancelar')),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _guardando ? null : _guardarUbicacion,
                          child: _guardando
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Guardar'),
                        ),
                      ]
                    : [
                        FilledButton.icon(
                          onPressed: () => setState(() => _editandoUbicacion = true),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar ubicación'),
                        ),
                      ],
            children: [
              if (!widget.esCreacion) _fila('ID grifo', '${widget.idGrifo}'),
              _fila('Comuna', _calculandoComuna ? 'Calculando…' : _comunaNombre),
              _fila('Lat', _lat?.toStringAsFixed(5) ?? '—'),
              _fila('Long', _lon?.toStringAsFixed(5) ?? '—'),
              if (!widget.esCreacion) ...[
                _fila('Estado actual', _estadoActual),
                _fila('Última revisión', _fechaUltimo),
                if (_notaActual != null) _fila('Nota actual', _notaActual!),
              ],
              if (widget.esCreacion || _editandoUbicacion)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'La comuna se calcula automáticamente según las coordenadas del mapa.',
                    style: TextStyle(fontSize: 12, color: AdminTheme.mutedText.withValues(alpha: 0.9)),
                  ),
                ),
              if (widget.esCreacion) ...[
                const SizedBox(height: 16),
                _dropdownEstado('Estado inicial', _idEstadoNuevo, (v) => setState(() => _idEstadoNuevo = v)),
                const SizedBox(height: 12),
                TextField(
                  controller: _notaCtrl,
                  decoration: const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder()),
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _guardando ? null : _guardarUbicacion,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.infoBlue),
                  child: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Registrar grifo'),
                ),
              ],
            ],
          ),
          if (!widget.esCreacion) ...[
            const SizedBox(height: 16),
            _card(
              titulo: 'Registrar revisión',
              icono: Icons.fact_check_outlined,
              children: [
                _dropdownEstado('Nuevo estado', _idEstadoNuevo, (v) => setState(() => _idEstadoNuevo = v)),
                const SizedBox(height: 12),
                TextField(
                  controller: _notaCtrl,
                  decoration: const InputDecoration(labelText: 'Nota (opcional)', border: OutlineInputBorder()),
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _guardando ? null : _registrarRevision,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.infoBlue),
                  child: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar revisión'),
                ),
              ],
            ),
            if (_historial.isNotEmpty) ...[
              const SizedBox(height: 16),
              _card(
                titulo: 'Historial de revisiones',
                icono: Icons.history,
                children: [
                  for (var i = 0; i < _historial.length; i++) ...[
                    if (i > 0) const Divider(height: 16, color: AdminTheme.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${_historial[i].estado} · ${_historial[i].fechaRegistro}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${_historial[i].registradoPor}${_historial[i].nota != null ? '\n${_historial[i].nota}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _card({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
    List<Widget>? acciones,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: AdminTheme.infoBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
                ),
              ),
              if (acciones != null) ...acciones,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(etiqueta, style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText)),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AdminTheme.titleText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownEstado(String label, int? value, ValueChanged<int?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _estados.any((e) => e.id == value) ? value : null,
          hint: const Text('Selecciona'),
          items: _estados.map((e) => DropdownMenuItem(value: e.id, child: Text(e.label))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
