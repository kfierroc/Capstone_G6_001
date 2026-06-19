import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login/login_screen.dart';
import '../models/bombero_perfil.dart';
import '../models/compania_bombero_info.dart';
import '../services/compania_bombero_service.dart';
import '../services/perfil_bombero_service.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/selector_region_comuna_compania.dart';

/// Perfil del bombero, actualización de compañía y cierre de sesión.
class ConfiguracionBomberoScreen extends StatefulWidget {
  const ConfiguracionBomberoScreen({super.key, required this.perfil});

  final BomberoPerfil perfil;

  @override
  State<ConfiguracionBomberoScreen> createState() => _ConfiguracionBomberoScreenState();
}

class _ConfiguracionBomberoScreenState extends State<ConfiguracionBomberoScreen> {
  static const _rojo = Color(0xFFC62828);
  static const _fondo = Color(0xFFF4F4F2);

  CompaniaBomberoInfo? _companiaInfo;
  bool _cargandoCompania = true;
  String? _errorCompania;

  int? _idCompaniaSeleccionada;
  bool _editandoCompania = false;
  bool _guardando = false;

  String get _correo => Supabase.instance.client.auth.currentUser?.email ?? '—';

  bool get _hayCambioCompania =>
      _idCompaniaSeleccionada != null && _idCompaniaSeleccionada != widget.perfil.idCompania;

  @override
  void initState() {
    super.initState();
    _idCompaniaSeleccionada = widget.perfil.idCompania;
    _cargarCompaniaYComuna();
  }

  Future<void> _cargarCompaniaYComuna() async {
    setState(() => _cargandoCompania = true);
    try {
      final id = _idCompaniaSeleccionada ?? widget.perfil.idCompania;
      final info = await CompaniaBomberoService(Supabase.instance.client).obtenerPorIdCompania(id);
      if (!mounted) return;
      setState(() {
        _companiaInfo = info;
        _cargandoCompania = false;
        _errorCompania = info == null ? 'No se encontró la compañía asignada.' : null;
      });
    } on CompaniaBomberoException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCompania = e.message;
        _cargandoCompania = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCompania = '$e';
        _cargandoCompania = false;
      });
    }
  }

  Future<void> _guardarCompania() async {
    final idNuevo = _idCompaniaSeleccionada;
    if (idNuevo == null) {
      _snack('Selecciona región, comuna y compañía.');
      return;
    }
    if (idNuevo == widget.perfil.idCompania) {
      _snack('No hay cambios en la compañía.');
      return;
    }

    setState(() => _guardando = true);
    try {
      await PerfilBomberoService(Supabase.instance.client).actualizarCompania(
        rutNum: widget.perfil.rutNum,
        idCompania: idNuevo,
      );
      if (!mounted) return;

      final perfilActualizado = widget.perfil.copyWith(idCompania: idNuevo);
      await _cargarCompaniaYComuna();

      if (!mounted) return;
      setState(() => _editandoCompania = false);
      _snack('Compañía actualizada correctamente.');
      Navigator.pop(context, perfilActualizado);
    } on PerfilBomberoException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _iniciarEdicionCompania() {
    setState(() {
      _editandoCompania = true;
      _idCompaniaSeleccionada = widget.perfil.idCompania;
    });
  }

  void _cancelarEdicionCompania() {
    setState(() {
      _editandoCompania = false;
      _idCompaniaSeleccionada = widget.perfil.idCompania;
    });
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _rojo),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.perfil;

    return Scaffold(
      backgroundColor: _fondo,
      body: Column(
        children: [
          const CustomAppBar(
            title: 'Configuración',
            subtitle: 'Tu cuenta de bombero',
            leadingIcon: Icons.settings_outlined,
          ),
          Expanded(
            child: AppWidthContainer(
              includeVerticalPadding: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  _tarjetaPerfil(p),
                  const SizedBox(height: 16),
                  _tarjetaDatos(p),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _guardando ? null : _cerrarSesion,
                    icon: const Icon(Icons.logout, color: _rojo),
                    label: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: _rojo, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _rojo),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaPerfil(BomberoPerfil p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _rojo.withValues(alpha: 0.12),
            child: const Icon(Icons.person, color: _rojo, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nombreCompleto,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                if (_cargandoCompania)
                  Text('Cargando compañía…', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
                else if (_companiaInfo != null) ...[
                  Text(
                    _companiaInfo!.nombre,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Comuna: ${_companiaInfo!.nombreComuna}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ] else if (_errorCompania != null)
                  Text(_errorCompania!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                const SizedBox(height: 6),
                if (p.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _rojo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _rojo.withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'Administrador',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _rojo),
                    ),
                  )
                else
                  Text(
                    'Bombero operativo',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDatos(BomberoPerfil p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de la cuenta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Solo puedes editar la compañía asignada.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          _filaInfo(Icons.badge_outlined, 'RUT', p.rutMostrar),
          _filaInfo(Icons.email_outlined, 'Correo', _correo),
          if (_errorCompania != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorCompania!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ),
          _filaInfo(
            Icons.local_fire_department_outlined,
            'Compañía',
            _cargandoCompania
                ? 'Cargando…'
                : (_companiaInfo?.nombre ?? 'Compañía #${p.idCompania}'),
          ),
          _filaInfo(
            Icons.location_city_outlined,
            'Comuna de la compañía',
            _cargandoCompania ? 'Cargando…' : (_companiaInfo?.nombreComuna ?? '—'),
          ),
          _filaInfo(Icons.shield_outlined, 'Rol', p.isAdmin ? 'Administrador' : 'Bombero'),
          if (!_editandoCompania) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _cargandoCompania ? null : _iniciarEdicionCompania,
                icon: const Icon(Icons.edit_outlined, size: 18, color: _rojo),
                label: const Text('Editar compañía', style: TextStyle(color: _rojo, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _rojo),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Selecciona región, comuna y compañía',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),
            SelectorRegionComunaCompania(
              key: ValueKey('selector_compania_${widget.perfil.idCompania}'),
              idCompaniaInicial: widget.perfil.idCompania,
              deshabilitado: _guardando,
              onSeleccionCambiada: (id) => setState(() => _idCompaniaSeleccionada = id),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _guardando ? null : _cancelarEdicionCompania,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: (_guardando || !_hayCambioCompania) ? null : _guardarCompania,
                    style: FilledButton.styleFrom(
                      backgroundColor: _rojo,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _guardando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _filaInfo(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
