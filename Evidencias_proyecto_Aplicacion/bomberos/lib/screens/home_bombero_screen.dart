import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login/login_screen.dart';
import '../models/bombero_perfil.dart';
import '../models/residencia_busqueda.dart';
import '../services/busqueda_residencia_service.dart';
import '../widgets/custom_widgets.dart';

/// Inicio: búsqueda de residencias con registro vigente (modo emergencia).
class HomeBomberoScreen extends StatefulWidget {
  const HomeBomberoScreen({super.key, required this.perfil});

  final BomberoPerfil perfil;

  @override
  State<HomeBomberoScreen> createState() => _HomeBomberoScreenState();
}

class _HomeBomberoScreenState extends State<HomeBomberoScreen> {
  static const _rojo = Color(0xFFC62828);
  static const _fondo = Color(0xFFF4F4F2);

  final _busquedaController = TextEditingController();
  late final BusquedaResidenciaService _busquedaSvc;

  List<ResidenciaBusquedaResultado> _resultados = [];
  bool _buscando = false;
  bool _busquedaRealizada = false;

  @override
  void initState() {
    super.initState();
    _busquedaSvc = BusquedaResidenciaService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _buscar() async {
    final termino = _busquedaController.text.trim();
    if (termino.isEmpty) {
      _snack('Ingresa una dirección para buscar.');
      return;
    }
    setState(() {
      _buscando = true;
      _busquedaRealizada = false;
    });
    try {
      final lista = await _busquedaSvc.buscarActivas(termino);
      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _busquedaRealizada = true;
      });
      if (lista.isEmpty) {
        _snack('No se encontraron residencias activas para esa dirección.');
      }
    } on BusquedaResidenciaException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('No se pudo completar la búsqueda: $e');
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _limpiar() {
    _busquedaController.clear();
    setState(() {
      _resultados = [];
      _busquedaRealizada = false;
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final paddingH = ancho >= 600 ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: _fondo,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Sistema de Emergencias',
            subtitle: 'Bienvenido, ${widget.perfil.nombreCompleto}',
            showBack: false,
            showLeadingIconWhenNoBack: true,
            leadingIcon: Icons.warning_amber_rounded,
            trailing: Container(
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                tooltip: 'Cerrar sesión',
                onPressed: _cerrarSesion,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ancho >= 800 ? 720 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _bannerEmergencia(),
                      const SizedBox(height: 16),
                      _tarjetaBusqueda(),
                      if (_busquedaRealizada) ...[
                        const SizedBox(height: 16),
                        _tarjetaResultados(),
                      ],
                      const SizedBox(height: 16),
                      _tarjetaGuia(),
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

  Widget _bannerEmergencia() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _rojo.withValues(alpha: 0.45)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: _rojo, size: 22),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 MODO EMERGENCIA ACTIVO',
                  style: TextStyle(
                    color: _rojo,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Este sistema proporciona información crítica para operaciones de rescate. '
                  'Verifica siempre la información y mantén comunicación con el centro de comando.',
                  style: TextStyle(
                    color: Color(0xFFB71C1C),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaBusqueda() {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.search, size: 22, color: Color(0xFF424242)),
              SizedBox(width: 8),
              Text(
                'Búsqueda de Domicilio',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa la dirección para obtener información crítica del domicilio',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _busquedaController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            decoration: const InputDecoration(
              hintText: 'Ej: Av. Libertador 1234, Las Condes',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _buscando ? null : _buscar,
                  child: _buscando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Buscar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _buscando ? null : _limpiar,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    foregroundColor: const Color(0xFF424242),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _botonSecundario(
            color: const Color(0xFF2E7D32),
            icon: Icons.location_on_outlined,
            label: 'Ver Mapa de Residencias',
            onPressed: () => _snack('Mapa de residencias — próximamente.'),
          ),
          const SizedBox(height: 10),
          _botonSecundario(
            color: const Color(0xFF1565C0),
            icon: Icons.water_drop_outlined,
            label: 'Consultar Grifos de Agua',
            onPressed: () => _snack('Consulta de grifos — próximamente.'),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaResultados() {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultados de Búsqueda (${_resultados.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_resultados.isEmpty)
            Text(
              'No hay registros activos que coincidan con la búsqueda.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            )
          else
            ..._resultados.map(_filaResultado),
        ],
      ),
    );
  }

  Widget _filaResultado(ResidenciaBusquedaResultado r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.direccionCompleta,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            '${r.cantidadPersonas} persona(s) • ${r.cantidadMascotas} mascota(s)',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            'Última actualización: ${r.fechaUltimaFormateada}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _snack('Detalle del domicilio #${r.idRegistro} — próximamente.'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text('Ver Detalles'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaGuia() {
    return _tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guía Rápida de Uso',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _seccionGuia(
            titulo: '🚨 En Emergencia Activa:',
            color: _rojo,
            items: const [
              'Busca la dirección exacta del incidente.',
              'Revisa información de personas con condiciones especiales.',
              'Identifica número total de ocupantes esperados.',
              'Verifica información de mascotas para rescate.',
              'Contacta números de emergencia si es necesario.',
            ],
          ),
          const SizedBox(height: 16),
          _seccionGuia(
            titulo: '📋 Protocolos de Búsqueda:',
            color: const Color(0xFF1565C0),
            items: const [
              'Si no hay registro: seguir protocolo estándar.',
              'Verificar con vecinos información de ocupantes.',
              'Documentar hallazgos para futuros registros.',
              'Mantener comunicación con centro de comando.',
              'Priorizar personas con condiciones especiales.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccionGuia({
    required String titulo,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.grey.shade800, height: 1.35)),
                Expanded(
                  child: Text(t, style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.35)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _botonSecundario({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
