import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/catalogos_bombero_service.dart';
import '../services/compania_bombero_service.dart';
import 'bomberos_registro_widgets.dart';

/// Región → comuna → compañía (mismo flujo que registro paso 3).
class SelectorRegionComunaCompania extends StatefulWidget {
  const SelectorRegionComunaCompania({
    super.key,
    this.idCompaniaInicial,
    required this.onSeleccionCambiada,
    this.deshabilitado = false,
  });

  final int? idCompaniaInicial;
  final ValueChanged<int?> onSeleccionCambiada;
  final bool deshabilitado;

  @override
  State<SelectorRegionComunaCompania> createState() => _SelectorRegionComunaCompaniaState();
}

class _SelectorRegionComunaCompaniaState extends State<SelectorRegionComunaCompania> {
  final _catalogos = CatalogosBomberoService(Supabase.instance.client);
  final _companiaSvc = CompaniaBomberoService(Supabase.instance.client);

  List<({int cutReg, String nombre})> _regiones = [];
  List<({int cutCom, String nombre})> _comunas = [];
  List<({int id, String nombre})> _companias = [];

  int? _cutReg;
  int? _cutCom;
  int? _idCompania;

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      final regiones = await _catalogos.regiones();
      int? cutReg;
      int? cutCom;
      int? idCompania = widget.idCompaniaInicial;
      List<({int cutCom, String nombre})> comunas = [];
      List<({int id, String nombre})> companias = [];

      if (idCompania != null) {
        final ubicacion = await _companiaSvc.obtenerUbicacionPorIdCompania(idCompania);
        if (ubicacion != null) {
          cutReg = ubicacion.cutReg;
          cutCom = ubicacion.cutCom;
          comunas = await _catalogos.comunasPorRegion(cutReg);
          companias = await _catalogos.companiasPorComuna(cutCom);
        }
      }

      if (!mounted) return;
      setState(() {
        _regiones = regiones;
        _cutReg = cutReg;
        _cutCom = cutCom;
        _idCompania = idCompania;
        _comunas = comunas;
        _companias = companias;
        _cargando = false;
      });
      widget.onSeleccionCambiada(_idCompania);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  Future<void> _onRegionChanged(int? v) async {
    setState(() {
      _cutReg = v;
      _cutCom = null;
      _idCompania = null;
      _comunas = [];
      _companias = [];
    });
    widget.onSeleccionCambiada(null);
    if (v == null) return;

    setState(() => _cargando = true);
    try {
      final list = await _catalogos.comunasPorRegion(v);
      if (!mounted) return;
      setState(() {
        _comunas = list;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _onComunaChanged(int? v) async {
    setState(() {
      _cutCom = v;
      _idCompania = null;
      _companias = [];
    });
    widget.onSeleccionCambiada(null);
    if (v == null) return;

    setState(() => _cargando = true);
    try {
      final list = await _catalogos.companiasPorComuna(v);
      if (!mounted) return;
      setState(() {
        _companias = list;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _onCompaniaChanged(int? v) {
    setState(() => _idCompania = v);
    widget.onSeleccionCambiada(v);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _regiones.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _regiones.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.deshabilitado ? null : _inicializar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    final bloqueado = widget.deshabilitado || _cargando;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BomberosRegistroInputLabel(label: 'Región'),
        DropdownButtonFormField<int>(
          // ignore: deprecated_member_use
          value: _cutReg,
          isExpanded: true,
          hint: const Text('Selecciona una región'),
          decoration: bomberosRegistroFieldDecoration(hint: ''),
          items: _regiones
              .map((r) => DropdownMenuItem(value: r.cutReg, child: Text(r.nombre, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: bloqueado ? null : _onRegionChanged,
        ),
        const BomberosRegistroInputLabel(label: 'Comuna'),
        DropdownButtonFormField<int>(
          // ignore: deprecated_member_use
          value: _cutCom,
          isExpanded: true,
          hint: Text(_cutReg == null ? 'Primero selecciona una región' : 'Selecciona una comuna'),
          decoration: bomberosRegistroFieldDecoration(hint: ''),
          items: _comunas
              .map((c) => DropdownMenuItem(value: c.cutCom, child: Text(c.nombre, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (bloqueado || _cutReg == null) ? null : _onComunaChanged,
        ),
        const BomberosRegistroInputLabel(label: 'Compañía de Bomberos'),
        DropdownButtonFormField<int>(
          // ignore: deprecated_member_use
          value: _idCompania,
          isExpanded: true,
          hint: Text(_cutCom == null ? 'Primero selecciona una comuna' : 'Selecciona una compañía'),
          decoration: bomberosRegistroFieldDecoration(hint: ''),
          items: _companias
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (bloqueado || _cutCom == null) ? null : _onCompaniaChanged,
        ),
        if (_cargando && _regiones.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
