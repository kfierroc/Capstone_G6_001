import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_perfil.dart';
import '../../models/grifo_mapa.dart';
import '../../services/grifo_edicion_service.dart';
import '../../services/mapa_grifo_service.dart';
import '../../utils/grifo_estado_utils.dart';
import '../../widgets/custom_widgets.dart';

/// Actualiza estado y notas de un grifo (nueva fila en `info_grifo`).
class GrifoEdicionScreen extends StatefulWidget {
  const GrifoEdicionScreen({
    super.key,
    required this.grifo,
    this.perfil,
  });

  final GrifoMapaResultado grifo;
  final BomberoPerfil? perfil;

  @override
  State<GrifoEdicionScreen> createState() => _GrifoEdicionScreenState();
}

class _GrifoEdicionScreenState extends State<GrifoEdicionScreen> {
  static const _azul = Color(0xFF1565C0);

  late final MapaGrifoService _mapaSvc;
  late final GrifoEdicionService _edicionSvc;
  final _notasCtrl = TextEditingController();

  List<EstadoGrifoOpcion> _estados = [];
  int? _idEstadoSeleccionado;
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _mapaSvc = MapaGrifoService(client);
    _edicionSvc = GrifoEdicionService(client);
    _notasCtrl.text = widget.grifo.notas ?? '';
    _idEstadoSeleccionado = widget.grifo.idEstadoGr;
    _cargarEstados();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarEstados() async {
    try {
      final estados = await _mapaSvc.listarEstados();
      if (!mounted) return;
      setState(() {
        _estados = estados;
        if (_idEstadoSeleccionado == null && estados.isNotEmpty) {
          _idEstadoSeleccionado = estados.first.id;
        }
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    final perfil = widget.perfil;
    if (perfil == null) {
      _snack('Debes iniciar sesión para editar un grifo.');
      return;
    }
    final idEstado = _idEstadoSeleccionado;
    if (idEstado == null) {
      _snack('Selecciona un estado.');
      return;
    }

    setState(() => _guardando = true);
    try {
      final actualizado = await _edicionSvc.actualizarInspeccion(
        idGrifo: widget.grifo.idGrifo,
        idEstadoGr: idEstado,
        rutNumBombero: perfil.rutNum,
        notas: _notasCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context, actualizado);
    } on GrifoEdicionException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.grifo;
    final color = GrifoEstadoUtils.colorPorEstado(g.estado);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Editar grifo',
            subtitle: 'Actualiza estado y notas de inspección',
            showBack: true,
            leadingIcon: Icons.edit_outlined,
            backgroundColor: _azul,
          ),
          Expanded(
            child: AppWidthContainer(
              includeVerticalPadding: true,
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: _azul))
                  : SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${g.idGrifo}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: color.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    g.estado,
                                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _info('Comuna', g.comunaNombre.isNotEmpty ? g.comunaNombre : '—'),
                            _info('Coordenadas', '${g.lat.toStringAsFixed(5)}, ${g.lon.toStringAsFixed(5)}'),
                            _info('Última inspección registrada', g.fechaFormateada),
                            const Divider(height: 28),
                            const InputLabel(label: 'Estado actual', required: true),
                            DropdownButtonFormField<int>(
                              key: ValueKey(_idEstadoSeleccionado),
                              initialValue: _idEstadoSeleccionado,
                              isExpanded: true,
                              decoration: _inputDeco(),
                              items: _estados
                                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                                  .toList(),
                              onChanged: _guardando ? null : (v) => setState(() => _idEstadoSeleccionado = v),
                            ),
                            const InputLabel(label: 'Reportado por'),
                            TextFormField(
                              readOnly: true,
                              initialValue: widget.perfil?.nombreCompleto ?? '—',
                              decoration: _inputDeco(fill: const Color(0xFFF1F4F8)),
                            ),
                            const InputLabel(label: 'Notas adicionales'),
                            TextFormField(
                              controller: _notasCtrl,
                              maxLines: 4,
                              decoration: _inputDeco().copyWith(
                                hintText: 'Acceso, condiciones, observaciones…',
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _guardando ? null : _guardar,
                              style: FilledButton.styleFrom(
                                backgroundColor: _azul,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _guardando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.35),
          children: [
            TextSpan(text: '$etiqueta: ', style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({Color? fill}) {
    return InputDecoration(
      filled: true,
      fillColor: fill ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
