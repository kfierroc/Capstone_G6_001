import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/catalogos_residente_service.dart';
import '../services/gestion_residente_service.dart';
import '../services/registro_residente_service.dart';
import '../widgets/custom_widgets.dart';

/// Gestión de mascotas con catálogos y tabla `mascota` en Supabase.
class GestionMascotasScreen extends StatefulWidget {
  const GestionMascotasScreen({super.key});

  @override
  State<GestionMascotasScreen> createState() => _GestionMascotasScreenState();
}

class _GestionMascotasScreenState extends State<GestionMascotasScreen> {
  static const _verdeApp = Color(0xFF00A84E);
  static const _azul = Color(0xFF3D7BF5);
  static const _bordeGris = Color(0xFFE0E0E0);
  static const _fondoPagina = Color(0xFFF2F4F7);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);
  static const _inputFill = Color(0xFFF9FAFB);
  static const _navMascotas = Color(0xFF7C3AED);
  static const _navMascotasBg = Color(0xFFF3E8FF);

  final _nombreController = TextEditingController();

  List<({int id, String etiqueta})> _especies = [];
  List<({int id, String etiqueta})> _tamanios = [];
  int? _idEspecie;
  int? _idTamanio;

  ContextoResidente? _contexto;
  List<MascotaVista> _mascotas = [];
  bool _loading = true;
  String? _sinGrupoMensaje;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _sinGrupoMensaje = null;
      _catalogError = null;
    });
    final client = Supabase.instance.client;
    try {
      final cat = CatalogosResidenteService(client);
      final ges = GestionResidenteService(client);
      final especies = await cat.tipoEspecies();
      final tamanios = await cat.tipoTamaniosMascota();
      final ctx = await ges.contextoResidente();
      List<MascotaVista> mas = [];
      if (ctx != null) {
        mas = await ges.listarMascotas(ctx.idGrupof);
      }
      if (!mounted) return;
      setState(() {
        _especies = especies;
        _tamanios = tamanios;
        _contexto = ctx;
        _mascotas = mas;
        _sinGrupoMensaje =
            ctx == null ? 'No hay grupo familiar asociado a tu cuenta. Completa el registro inicial.' : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _textoGris, fontSize: 14),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _azul, width: 1.5),
      ),
    );
  }

  Future<void> _agregarMascota() async {
    final ctx = _contexto;
    if (ctx == null) {
      _snack(_sinGrupoMensaje ?? 'No hay grupo familiar.');
      return;
    }
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      _snack('Ingresa el nombre de la mascota.');
      return;
    }
    if (_idEspecie == null || _idTamanio == null) {
      _snack('Selecciona especie y tamaño.');
      return;
    }
    try {
      await GestionResidenteService(Supabase.instance.client).agregarMascota(
        idGrupof: ctx.idGrupof,
        nombre: nombre,
        idEspecie: _idEspecie!,
        idTamanio: _idTamanio!,
      );
      _nombreController.clear();
      setState(() {
        _idEspecie = null;
        _idTamanio = null;
      });
      final list = await GestionResidenteService(Supabase.instance.client).listarMascotas(ctx.idGrupof);
      if (!mounted) return;
      setState(() => _mascotas = list);
      _snack('Mascota registrada correctamente.');
    } on RegistroResidenteException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('No se pudo registrar la mascota: $e');
    }
  }

  void _eliminarMascota(MascotaVista m) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar mascota',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textoPrincipal),
        ),
        content: Text(
          '¿Quitar a ${m.nombre} de la lista?',
          style: const TextStyle(color: _textoGris),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: _textoGris)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await GestionResidenteService(Supabase.instance.client).eliminarMascota(m.idMascota);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                final ctx = _contexto;
                if (ctx != null) {
                  final list = await GestionResidenteService(Supabase.instance.client).listarMascotas(ctx.idGrupof);
                  if (!mounted) return;
                  setState(() => _mascotas = list);
                }
                _snack('Mascota eliminada.');
              } catch (e) {
                _snack('No se pudo eliminar: $e');
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _onNavTap(int i) {
    switch (i) {
      case 0:
        Navigator.pushReplacementNamed(context, '/gestion-familia');
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/gestion-domicilio');
      case 3:
        Navigator.pushReplacementNamed(context, '/gestion-peligrosos');
      case 4:
        Navigator.pushReplacementNamed(context, '/gestion-configuracion');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondoPagina,
      body: Column(
        children: [
          CustomAppBar(
            title: 'Mi Información Familiar',
            subtitle: 'Gestiona la información de tu domicilio',
            showBack: true,
            onBack: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            trailing: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _snack('Acción de ejemplo (sin integración).'),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.notifications_none_rounded, color: _verdeApp, size: 22),
                ),
              ),
            ),
          ),
          Expanded(child: _buildMascotasBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMascotasBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_catalogError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_catalogError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _bootstrap,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: _fondoPagina,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.favorite_border, size: 24, color: _textoPrincipal),
                  SizedBox(width: 8),
                  Text(
                    'Gestión de Mascotas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textoPrincipal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Agrega y gestiona tus mascotas',
                style: TextStyle(fontSize: 13, color: _textoGris),
              ),
              const SizedBox(height: 20),
              if (_sinGrupoMensaje != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDBA74)),
                    ),
                    child: Text(
                      _sinGrupoMensaje!,
                      style: const TextStyle(fontSize: 13, color: _textoPrincipal, height: 1.35),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _bordeGris),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar nueva mascota',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Nombre de la mascota',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nombreController,
                      style: const TextStyle(fontSize: 14, color: _textoPrincipal),
                      decoration: _fieldDecoration(hint: 'Ej: Firulais'),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Especie',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _idEspecie,
                      decoration: _fieldDecoration(hint: 'Selecciona la especie').copyWith(
                        hintStyle: const TextStyle(color: _textoGris, fontSize: 14),
                      ),
                      hint: const Text('Selecciona la especie', style: TextStyle(color: _textoGris, fontSize: 14)),
                      items: _especies
                          .map((e) => DropdownMenuItem<int>(value: e.id, child: Text(e.etiqueta)))
                          .toList(),
                      onChanged: (v) => setState(() => _idEspecie = v),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tamaño',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _idTamanio,
                      decoration: _fieldDecoration(hint: 'Selecciona el tamaño').copyWith(
                        hintStyle: const TextStyle(color: _textoGris, fontSize: 14),
                      ),
                      hint: const Text('Selecciona el tamaño', style: TextStyle(color: _textoGris, fontSize: 14)),
                      items: _tamanios
                          .map((e) => DropdownMenuItem<int>(value: e.id, child: Text(e.etiqueta)))
                          .toList(),
                      onChanged: (v) => setState(() => _idTamanio = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (_contexto == null || _especies.isEmpty || _tamanios.isEmpty)
                            ? null
                            : () => _agregarMascota(),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text(
                          'Agregar Mascota',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _azul,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Mascotas registradas (${_mascotas.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textoPrincipal,
                ),
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mascotas.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _buildMascotaCard(_mascotas[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMascotaCard(MascotaVista m) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bordeGris),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: _textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.especie} • ${m.tamano}',
                  style: const TextStyle(fontSize: 13, color: _textoGris, height: 1.3),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _bordeGris),
              ),
              child: InkWell(
                onTap: () => _eliminarMascota(m),
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = <({IconData icon, IconData iconActive, String label})>[
      (icon: Icons.people_outline, iconActive: Icons.people, label: 'Familia'),
      (icon: Icons.favorite_border, iconActive: Icons.favorite, label: 'Mascotas'),
      (icon: Icons.home_outlined, iconActive: Icons.home, label: 'Domicilio'),
      (icon: Icons.warning_amber_outlined, iconActive: Icons.warning_amber, label: 'Peligrosos'),
      (icon: Icons.settings_outlined, iconActive: Icons.settings, label: 'Configuración'),
    ];

    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final selected = i == 1;
              final Color highlightBg = selected ? _navMascotasBg : Colors.transparent;
              final Color iconColor = selected ? _navMascotas : _textoGris;
              return Expanded(
                child: InkWell(
                  onTap: () => _onNavTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: highlightBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            selected ? it.iconActive : it.icon,
                            size: 24,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          it.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: iconColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
