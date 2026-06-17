import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/admin_catalog_service.dart';
import '../../services/admin_edit_service.dart';
import '../../services/residencias_admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_detail_shell.dart';
import '../../widgets/admin_edit_sheets.dart';

/// Vista integrada al panel para ver y editar la ubicación de una residencia.
class ResidenciaEditScreen extends StatefulWidget {
  const ResidenciaEditScreen({
    super.key,
    required this.idResidencia,
    required this.alertCount,
    required this.volverLabel,
    required this.onVolver,
    this.onGuardado,
    this.onVerGrupoFamiliar,
  });

  final int idResidencia;
  final int alertCount;
  final String volverLabel;
  final VoidCallback onVolver;
  final VoidCallback? onGuardado;
  final ValueChanged<int>? onVerGrupoFamiliar;

  @override
  State<ResidenciaEditScreen> createState() => _ResidenciaEditScreenState();
}

class _ResidenciaEditScreenState extends State<ResidenciaEditScreen> {
  final _mapController = MapController();

  late final TextEditingController _calleCtrl;
  late final TextEditingController _nroCtrl;

  bool _loading = true;
  bool _editando = false;
  bool _guardando = false;
  String? _errorCarga;

  String _comunaNombre = '—';
  String _direccionCorta = '';
  List<CatalogItem> _comunas = [];
  int? _cutCom;
  double? _lat;
  double? _lon;
  int? _idGrupof;
  String? _titularGrupo;

  static const _centroChile = LatLng(-33.4489, -70.6693);

  @override
  void initState() {
    super.initState();
    _calleCtrl = TextEditingController();
    _nroCtrl = TextEditingController();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _errorCarga = null;
    });
    final client = Supabase.instance.client;
    final det = await ResidenciasAdminService(client).obtenerDetalle(widget.idResidencia);
    final comunas = await AdminCatalogService(client).comunas();
    if (!mounted) return;

    if (det == null) {
      setState(() {
        _loading = false;
        _errorCarga = 'No se pudo cargar la residencia.';
      });
      return;
    }

    _calleCtrl.text = det.calle;
    _nroCtrl.text = '${det.nroDireccion}';
    _cutCom = det.cutCom;
    _lat = det.lat;
    _lon = det.lon;
    _comunas = comunas;
    _comunaNombre = det.comuna;
    _direccionCorta = det.direccionCorta;
    _idGrupof = det.grupoDetalle?.idGrupof;
    _titularGrupo = det.grupoDetalle?.titularEtiqueta;

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

  void _iniciarEdicion() => setState(() => _editando = true);

  void _cancelarEdicion() {
    _cargar();
    setState(() => _editando = false);
  }

  Future<void> _guardar() async {
    final nro = int.tryParse(_nroCtrl.text.trim());
    if (nro == null) {
      AdminEditSheets.showError(context, AdminEditException('Número de dirección inválido.'));
      return;
    }
    if (_lat == null || _lon == null) {
      AdminEditSheets.showError(context, AdminEditException('Selecciona una ubicación en el mapa.'));
      return;
    }
    if (_cutCom == null) {
      AdminEditSheets.showError(context, AdminEditException('Selecciona una comuna.'));
      return;
    }

    setState(() => _guardando = true);
    try {
      await AdminEditService(Supabase.instance.client).actualizarResidencia(
        idResidencia: widget.idResidencia,
        calle: _calleCtrl.text,
        nroDireccion: nro,
        lat: _lat!,
        lon: _lon!,
        cutCom: _cutCom!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Residencia actualizada correctamente.')),
      );
      widget.onGuardado?.call();
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _onTapMapa(TapPosition _, LatLng point) {
    if (!_editando) return;
    setState(() {
      _lat = point.latitude;
      _lon = point.longitude;
    });
  }

  @override
  void dispose() {
    _calleCtrl.dispose();
    _nroCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return AdminDetailShell(
      headerTitle: 'Residencias',
      alertCount: widget.alertCount,
      volverLabel: widget.volverLabel,
      onVolver: widget.onVolver,
      loading: _loading,
      subtitulo: _direccionCorta.isEmpty ? 'Residencia ${widget.idResidencia}' : _direccionCorta,
      descripcion: 'ID ${widget.idResidencia} · $_comunaNombre',
      errorMessage: _errorCarga,
      child: _loading || _errorCarga != null
          ? null
          : esAncho
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _panelInformacion()),
                    const SizedBox(width: 16),
                    Expanded(child: _panelMapa()),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _panelInformacion(),
                      const SizedBox(height: 16),
                      SizedBox(height: 320, child: _panelMapa()),
                    ],
                  ),
                ),
    );
  }

  Widget _panelInformacion() {
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
              const Icon(Icons.location_on_outlined, size: 20, color: AdminTheme.infoBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _editando ? 'Editar ubicación' : 'Información de la residencia',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminTheme.titleText,
                  ),
                ),
              ),
              if (!_editando)
                FilledButton.icon(
                  onPressed: _iniciarEdicion,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminTheme.infoBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                )
              else ...[
                OutlinedButton(
                  onPressed: _guardando ? null : _cancelarEdicion,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _guardando ? null : _guardar,
                  style: FilledButton.styleFrom(backgroundColor: AdminTheme.infoBlue),
                  child: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  if (_editando) ...[
                    TextField(
                      controller: _calleCtrl,
                      decoration: const InputDecoration(labelText: 'Calle', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nroCtrl,
                      decoration: const InputDecoration(labelText: 'Número', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Comuna', border: OutlineInputBorder()),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _comunas.any((c) => c.id == _cutCom) ? _cutCom : null,
                          hint: const Text('Selecciona comuna'),
                          items: _comunas
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.label)))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _cutCom = v;
                            _comunaNombre = _comunas.firstWhere((c) => c.id == v).label;
                          }),
                        ),
                      ),
                    ),
                  ] else ...[
                    _filaInfo('Calle', _calleCtrl.text.isEmpty ? '—' : _calleCtrl.text),
                    _filaInfo('Número', _nroCtrl.text.isEmpty ? '—' : _nroCtrl.text),
                    _filaInfo('Comuna', _comunaNombre),
                    _filaInfo('ID residencia', '${widget.idResidencia}'),
                  ],
                  const SizedBox(height: 4),
                  _filaInfo(
                    'Coordenadas',
                    _lat != null && _lon != null
                        ? '${_lat!.toStringAsFixed(5)}, ${_lon!.toStringAsFixed(5)}'
                        : 'Sin coordenadas registradas',
                  ),
                  if (_editando)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Toca el mapa a la derecha para mover el marcador.',
                        style: TextStyle(fontSize: 12, color: AdminTheme.mutedText.withValues(alpha: 0.9)),
                      ),
                    ),
                  if (_idGrupof != null && widget.onVerGrupoFamiliar != null && !_editando) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => widget.onVerGrupoFamiliar!(_idGrupof!),
                      icon: const Icon(Icons.groups_outlined, size: 18),
                      label: Text(
                        _titularGrupo != null && _titularGrupo!.isNotEmpty
                            ? 'Ver grupo familiar · $_titularGrupo'
                            : 'Ver grupo familiar',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.infoBlue,
                        side: const BorderSide(color: AdminTheme.infoBlue),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ] else if (_idGrupof == null && !_editando)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Sin grupo familiar vinculado al registro vigente.',
                        style: TextStyle(fontSize: 12, color: AdminTheme.mutedText.withValues(alpha: 0.9)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelMapa() {
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
                  flags: _editando ? InteractiveFlag.all : InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                        Icons.location_on,
                        size: 44,
                        color: _editando ? AdminTheme.alertRed : AdminTheme.infoBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_editando)
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
                    'Toca el mapa para mover el marcador',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filaInfo(String etiqueta, String valor) {
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
}
