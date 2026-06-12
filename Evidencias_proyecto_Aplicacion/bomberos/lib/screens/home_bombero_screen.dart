import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bombero_perfil.dart';
import '../models/residencia_busqueda.dart';
import '../services/busqueda_residencia_service.dart';
import '../services/catalogos_bombero_service.dart';
import '../services/compania_bombero_service.dart';
import '../widgets/custom_widgets.dart';
import 'configuracion_bombero_screen.dart';
import 'detalle_residencia_screen.dart';
import 'grifos/grifos_screen.dart';
import 'mapa_residencias_screen.dart';

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

  late BomberoPerfil _perfil;
  final _busquedaController = TextEditingController();
  late final BusquedaResidenciaService _busquedaSvc;

  List<ResidenciaBusquedaResultado> _resultados = [];
  List<({int cutReg, String nombre})> _regiones = [];
  List<({int cutCom, String nombre})> _comunas = [];
  int? _cutRegSeleccionada;
  int? _cutComSeleccionada;
  bool _cargandoFiltros = true;
  bool _cargandoComunas = false;
  bool _busquedaLibre = false;
  bool _buscando = false;
  bool _busquedaRealizada = false;

  @override
  void initState() {
    super.initState();
    _perfil = widget.perfil;
    _busquedaSvc = BusquedaResidenciaService(Supabase.instance.client);
    _cargarFiltrosUbicacion();
  }

  Future<void> _cargarFiltrosUbicacion() async {
    final client = Supabase.instance.client;
    final catalogos = CatalogosBomberoService(client);
    setState(() => _cargandoFiltros = true);
    try {
      final regiones = await catalogos.regiones();
      final ubicacion = await CompaniaBomberoService(client).obtenerUbicacionPorIdCompania(_perfil.idCompania);

      List<({int cutCom, String nombre})> comunas = [];
      int? cutReg;
      int? cutCom;

      if (ubicacion != null) {
        cutReg = ubicacion.cutReg;
        cutCom = ubicacion.cutCom;
        comunas = await catalogos.comunasPorRegion(cutReg);
      }

      if (!mounted) return;
      setState(() {
        _regiones = regiones;
        _cutRegSeleccionada = cutReg;
        _comunas = comunas;
        _cutComSeleccionada = cutCom;
        _cargandoFiltros = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargandoFiltros = false);
    }
  }

  Future<void> _onRegionChanged(int? cutReg) async {
    setState(() {
      _cutRegSeleccionada = cutReg;
      _cutComSeleccionada = null;
      _comunas = [];
    });
    if (cutReg == null) return;

    setState(() => _cargandoComunas = true);
    try {
      final list = await CatalogosBomberoService(Supabase.instance.client).comunasPorRegion(cutReg);
      if (!mounted) return;
      setState(() {
        _comunas = list;
        _cargandoComunas = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _cargandoComunas = false);
        _snack('No se pudieron cargar las comunas.');
      }
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _abrirConfiguracion() async {
    final actualizado = await Navigator.push<BomberoPerfil>(
      context,
      MaterialPageRoute(
        builder: (_) => ConfiguracionBomberoScreen(perfil: _perfil),
      ),
    );
    if (actualizado != null && mounted) {
      setState(() => _perfil = actualizado);
      await _cargarFiltrosUbicacion();
    }
  }

  bool get _filtroUbicacionCompleto => _cutRegSeleccionada != null && _cutComSeleccionada != null;

  bool get _puedeBuscar => _busquedaLibre || _filtroUbicacionCompleto;

  void _alternarBusquedaLibre() {
    setState(() => _busquedaLibre = !_busquedaLibre);
  }

  Future<void> _buscar() async {
    final termino = _busquedaController.text.trim();
    if (!_busquedaLibre) {
      if (_cutRegSeleccionada == null) {
        _snack('Selecciona una región.');
        return;
      }
      if (_cutComSeleccionada == null) {
        _snack('Selecciona una comuna.');
        return;
      }
    }
    if (termino.isEmpty) {
      _snack('Ingresa una dirección para buscar.');
      return;
    }
    setState(() {
      _buscando = true;
      _busquedaRealizada = false;
    });
    try {
      final lista = await _busquedaSvc.buscarActivas(
        termino: termino,
        cutCom: _busquedaLibre ? null : _cutComSeleccionada,
      );
      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _busquedaRealizada = true;
      });
      if (lista.isEmpty) {
        if (_busquedaLibre) {
          _snack('No se encontraron residencias activas para esa dirección (búsqueda libre).');
        } else {
          final cutCom = _cutComSeleccionada!;
          final nombreComuna = _comunas.where((c) => c.cutCom == cutCom).map((c) => c.nombre).firstOrNull;
          _snack(
            'No se encontraron residencias activas en ${nombreComuna ?? 'la comuna seleccionada'} para esa dirección.',
          );
        }
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
    final paddingH = AppLayout.horizontalPadding(ancho);

    return Scaffold(
      backgroundColor: _fondo,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Sistema de Emergencias',
            subtitle: 'Bienvenido, ${_perfil.nombreCompleto}',
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
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                tooltip: 'Configuración',
                onPressed: _abrirConfiguracion,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(paddingH, 16, paddingH, 24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: AppLayout.contentMaxWidth(ancho)),
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
            child: Text(
              'Este sistema proporciona información crítica para operaciones de rescate. '
              'Verifica siempre la información y mantén comunicación con el centro de comando.',
              style: TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 13,
                height: 1.35,
              ),
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
            'Ingresa la dirección para obtener información crítica del domicilio. '
            'Por defecto filtra por región y comuna; activa búsqueda libre para buscar sin ese filtro.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _buscando ? null : _alternarBusquedaLibre,
              icon: Icon(
                _busquedaLibre ? Icons.travel_explore : Icons.travel_explore_outlined,
                size: 20,
                color: _busquedaLibre ? _rojo : Colors.grey.shade700,
              ),
              label: Text(
                _busquedaLibre ? 'Búsqueda libre activa' : 'Activar búsqueda libre',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _busquedaLibre ? _rojo : Colors.grey.shade800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: _busquedaLibre ? _rojo : Colors.grey.shade400),
                backgroundColor: _busquedaLibre ? const Color(0xFFFFEBEE) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (!_busquedaLibre) ...[
            const SizedBox(height: 14),
            _labelObligatorio('Región'),
            const SizedBox(height: 6),
            _cargandoFiltros && _regiones.isEmpty
                ? const LinearProgressIndicator(minHeight: 2)
                : DropdownButtonFormField<int>(
                    key: ValueKey('reg-$_cutRegSeleccionada'),
                    initialValue: _cutRegSeleccionada,
                    isExpanded: true,
                    decoration: _decorationDropdown(),
                    hint: const Text('Selecciona una región'),
                    items: _regiones
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.cutReg,
                            child: Text(r.nombre, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: _buscando ? null : _onRegionChanged,
                  ),
            const SizedBox(height: 12),
            _labelObligatorio('Comuna'),
            const SizedBox(height: 6),
            if (_cargandoComunas)
              const LinearProgressIndicator(minHeight: 2)
            else
              DropdownButtonFormField<int>(
                key: ValueKey('com-$_cutComSeleccionada'),
                initialValue: _cutComSeleccionada,
                isExpanded: true,
                decoration: _decorationDropdown(),
                hint: Text(
                  _cutRegSeleccionada == null ? 'Primero selecciona una región' : 'Selecciona una comuna',
                ),
                items: _comunas
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.cutCom,
                        child: Text(c.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (_buscando || _cutRegSeleccionada == null)
                    ? null
                    : (v) => setState(() => _cutComSeleccionada = v),
              ),
          ],
          const SizedBox(height: 14),
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
                  onPressed: (_buscando || !_puedeBuscar) ? null : _buscar,
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
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MapaResidenciasScreen(perfil: _perfil),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _botonSecundario(
            color: const Color(0xFF1565C0),
            icon: Icons.water_drop_outlined,
            label: 'Consultar Grifos de Agua',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => GrifosScreen(perfil: _perfil),
                ),
              );
            },
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
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DetalleResidenciaScreen(
                      idRegistro: r.idRegistro,
                      perfil: _perfil,
                    ),
                  ),
                );
              },
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

  Widget _labelObligatorio(String texto) {
    return Row(
      children: [
        Text(
          texto,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
        const Text(' *', style: TextStyle(color: _rojo, fontWeight: FontWeight.w700)),
      ],
    );
  }

  InputDecoration _decorationDropdown() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
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
