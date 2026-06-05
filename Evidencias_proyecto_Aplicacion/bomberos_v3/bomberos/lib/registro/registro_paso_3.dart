import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/catalogos_bombero_service.dart';
import '../widgets/bomberos_registro_widgets.dart';
import 'registro_models.dart';

/// Paso 3 — región, comuna y compañía (desplegables dependientes).
class RegistroPaso3 extends StatefulWidget {
  const RegistroPaso3({
    super.key,
    required this.draft,
    required this.onComplete,
    required this.onBack,
    required this.enviando,
    required this.onIrALogin,
  });

  final RegistroBomberoBorrador draft;
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final bool enviando;
  final VoidCallback onIrALogin;

  @override
  State<RegistroPaso3> createState() => _RegistroPaso3State();
}

class _RegistroPaso3State extends State<RegistroPaso3> {
  List<({int cutReg, String nombre})> _regiones = [];
  List<({int cutCom, String nombre})> _comunas = [];
  List<({int id, String nombre})> _companias = [];

  int? _cutReg;
  int? _cutCom;
  int? _idCompania;

  bool _loadingCat = true;
  String? _errorCat;

  @override
  void initState() {
    super.initState();
    _cargarRegiones();
  }

  Future<void> _cargarRegiones() async {
    setState(() {
      _loadingCat = true;
      _errorCat = null;
    });
    try {
      final list = await CatalogosBomberoService(Supabase.instance.client).regiones();
      if (!mounted) return;
      setState(() {
        _regiones = list;
        _loadingCat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorCat = e.toString();
        _loadingCat = false;
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
    if (v == null) return;
    setState(() => _loadingCat = true);
    try {
      final list = await CatalogosBomberoService(Supabase.instance.client).comunasPorRegion(v);
      if (!mounted) return;
      setState(() {
        _comunas = list;
        _loadingCat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCat = false);
      _showSnack('No se pudieron cargar las comunas.');
    }
  }

  Future<void> _onComunaChanged(int? v) async {
    setState(() {
      _cutCom = v;
      _idCompania = null;
      _companias = [];
    });
    if (v == null) return;
    setState(() => _loadingCat = true);
    try {
      final list = await CatalogosBomberoService(Supabase.instance.client).companiasPorComuna(v);
      if (!mounted) return;
      setState(() {
        _companias = list;
        _loadingCat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCat = false);
      _showSnack('No se pudieron cargar las compañías.');
    }
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _crearCuenta() {
    if (_cutReg == null) {
      _showSnack('Selecciona una región.');
      return;
    }
    if (_cutCom == null) {
      _showSnack('Selecciona una comuna.');
      return;
    }
    if (_idCompania == null) {
      _showSnack('Selecciona una compañía de bomberos.');
      return;
    }
    widget.draft.idCompania = _idCompania;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Crear Cuenta Nueva',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Paso 3 de 3 - Ubicación y Compañía',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        if (_loadingCat && _regiones.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorCat != null && _regiones.isEmpty) ...[
          Text(_errorCat!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _cargarRegiones,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ] else ...[
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
            onChanged: widget.enviando ? null : _onRegionChanged,
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
            onChanged: (widget.enviando || _cutReg == null) ? null : _onComunaChanged,
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
            onChanged: (widget.enviando || _cutCom == null)
                ? null
                : (v) => setState(() => _idCompania = v),
          ),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.enviando ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anterior', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: widget.enviando ? null : _crearCuenta,
                style: FilledButton.styleFrom(
                  backgroundColor: kBomberosRojo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: widget.enviando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: widget.enviando ? null : widget.onIrALogin,
            child: const Text(
              '¿Ya tienes cuenta? Inicia sesión',
              style: TextStyle(color: kBomberosRojo, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
