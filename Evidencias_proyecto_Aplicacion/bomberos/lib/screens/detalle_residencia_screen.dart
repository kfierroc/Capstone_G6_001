import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bombero_perfil.dart';
import '../models/residencia_detalle.dart';
import '../services/detalle_residencia_service.dart';
import '../widgets/custom_widgets.dart';
import 'mapa_residencias_screen.dart';

class DetalleResidenciaScreen extends StatefulWidget {
  const DetalleResidenciaScreen({super.key, required this.idRegistro, this.perfil});

  final int idRegistro;
  final BomberoPerfil? perfil;

  @override
  State<DetalleResidenciaScreen> createState() => _DetalleResidenciaScreenState();
}

class _DetalleResidenciaScreenState extends State<DetalleResidenciaScreen> {
  static const _rojo = Color(0xFFC62828);
  static const _fondo = Color(0xFFF4F4F2);

  late final DetalleResidenciaService _svc;
  ResidenciaDetalle? _detalle;
  bool _cargando = true;
  String? _error;
  int _tabOcupantes = 0;

  @override
  void initState() {
    super.initState();
    _svc = DetalleResidenciaService(Supabase.instance.client);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final d = await _svc.obtenerPorRegistro(widget.idRegistro);
      if (!mounted) return;
      setState(() {
        _detalle = d;
        _cargando = false;
        _error = d == null ? 'No se encontró el registro del domicilio.' : null;
      });
    } on DetalleResidenciaException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _cargando = false;
      });
    }
  }

  String get _subtituloAppBar {
    final p = widget.perfil;
    if (p != null) return 'Bienvenido, ${p.nombreCompleto}';
    return 'Información crítica del domicilio';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Sistema de Emergencias',
            subtitle: _subtituloAppBar,
            showBack: true,
            leadingIcon: Icons.warning_amber_rounded,
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _rojo))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    : _buildContenido(_detalle!),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido(ResidenciaDetalle d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _resumenCritico(d),
          const SizedBox(height: 14),
          _tarjetaDomicilio(d),
          const SizedBox(height: 14),
          _tarjetaContacto(d),
          const SizedBox(height: 14),
          _tarjetaOcupantes(d),
        ],
      ),
    );
  }

  Widget _resumenCritico(ResidenciaDetalle d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rojo.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.home_outlined, color: _rojo, size: 20),
              SizedBox(width: 8),
              Text('Resumen Crítico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _rojo)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _tileResumen(Icons.people_outline, '${d.cantidadPersonas}', 'Personas', const Color(0xFF1565C0))),
              const SizedBox(width: 8),
              Expanded(child: _tileResumen(Icons.favorite_border, '${d.cantidadMascotas}', 'Mascotas', const Color(0xFF7B1FA2))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _tileResumen(
                  Icons.warning_amber_rounded,
                  '${d.cantidadConCondiciones}',
                  'Con condiciones',
                  const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _tileResumen(
                  Icons.local_fire_department_outlined,
                  '${d.cantidadMaterialesPeligrosos}',
                  'Materiales peligrosos',
                  _rojo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tileResumen(IconData icon, String valor, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _tarjetaDomicilio(ResidenciaDetalle d) {
    return _tarjeta(
      titulo: 'Información del Domicilio',
      icono: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filaLabel('Dirección', d.direccionCompleta, bold: true),
          const SizedBox(height: 14),
          const Text('Detalles de la Vivienda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          _filaLabel('Tipo de vivienda', d.tipoVivienda),
          _filaLabel('Estado de la vivienda', d.estadoVivienda),
          _filaLabel('Material del departamento', d.materialDepartamento),
          if (d.materialesPeligrosos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
                const SizedBox(width: 6),
                Text(
                  'Materiales Peligrosos (${d.materialesPeligrosos.length})',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.orange.shade900),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...d.materialesPeligrosos.map(_tarjetaMaterial),
          ],
          const SizedBox(height: 14),
          const Text('Instrucciones Especiales', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            (d.instruccionesEspeciales == null || d.instruccionesEspeciales!.trim().isEmpty)
                ? 'Sin instrucciones registradas.'
                : d.instruccionesEspeciales!,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Última actualización: ${d.fechaUltimaFormateada}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MapaResidenciasScreen(perfil: widget.perfil),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Ver en Mapa', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaMaterial(MaterialPeligrosoDetalle m) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Expanded(
                child: Text(m.tipo, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.orange.shade900)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Cantidad: ${m.cantidad}', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
          if (m.notas != null && m.notas!.isNotEmpty)
            Text('Notas: ${m.notas}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _tarjetaContacto(ResidenciaDetalle d) {
    return _tarjeta(
      titulo: 'Información de Contacto',
      icono: Icons.phone_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contacto Principal', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(d.telefonoTitular, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _tarjetaOcupantes(ResidenciaDetalle d) {
    return _tarjeta(
      titulo: 'Ocupantes del Domicilio',
      icono: Icons.groups_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información detallada de personas y mascotas en la residencia',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(child: _tabBtn('Personas (${d.personas.length})', 0)),
                Expanded(child: _tabBtn('Mascotas (${d.mascotas.length})', 1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tabOcupantes == 0)
            ...d.personas.map(_tarjetaPersona)
          else
            ...d.mascotas.map(_tarjetaMascota),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final activo = _tabOcupantes == index;
    return GestureDetector(
      onTap: () => setState(() => _tabOcupantes = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: activo ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              index == 0 ? Icons.person_outline : Icons.pets_outlined,
              size: 16,
              color: activo ? _rojo : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                color: activo ? _rojo : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaPersona(PersonaDetalle p) {
    final fondo = p.esTitular ? const Color(0xFFE3F2FD) : Colors.white;
    final borde = p.esTitular ? const Color(0xFF64B5F6) : Colors.grey.shade300;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.etiqueta,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: p.esTitular ? const Color(0xFF1565C0) : Colors.black87,
                  ),
                ),
              ),
              Text('${p.edad} años', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ],
          ),
          if (p.rutMostrar != null) ...[
            const SizedBox(height: 4),
            Text('RUT: ${p.rutMostrar}', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
          ],
          if (p.condiciones.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Text('🚨', style: TextStyle(fontSize: 14)),
                SizedBox(width: 4),
                Text(
                  'Condiciones Médicas/Especiales:',
                  style: TextStyle(color: _rojo, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...p.condiciones.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(c, style: const TextStyle(color: _rojo, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tarjetaMascota(MascotaDetalle m) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('${m.especie} • Tamaño: ${m.tamano}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _tarjeta({required String titulo, required IconData icono, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: Colors.grey.shade800),
              const SizedBox(width: 8),
              Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _filaLabel(String label, String valor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
