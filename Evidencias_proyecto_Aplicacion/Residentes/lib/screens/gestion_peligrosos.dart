import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/catalogos_residente_service.dart';
import '../services/gestion_residente_service.dart';
import '../services/registro_residente_service.dart';
import '../widgets/custom_widgets.dart';

/// Materiales peligrosos por `registro_v` vigente (`mat_peligroso`).
class GestionPeligrososScreen extends StatefulWidget {
  const GestionPeligrososScreen({super.key});

  @override
  State<GestionPeligrososScreen> createState() => _GestionPeligrososScreenState();
}

class _GestionPeligrososScreenState extends State<GestionPeligrososScreen> {
  static const _verdeApp = Color(0xFF00A84E);
  static const _fondoPagina = Color(0xFFF2F4F7);
  static const _textoPrincipal = Color(0xFF1A1A2E);
  static const _textoGris = Color(0xFF6B7280);

  static const _duraznoFondo = Color(0xFFFFF5F0);
  static const _duraznoBorde = Color(0xFFFFD8C2);
  static const _duraznoBoton = Color(0xFFEA8C55);
  static const _duraznoTituloLista = Color(0xFF9A3412);
  static const _duraznoItemBorde = Color(0xFFFDBA74);
  static const _navPeligrososBg = Color(0xFFFFEDD5);
  static const _navPeligrosos = Color(0xFFEA580C);

  int? _tipoSeleccionadoId;
  final _cantidadController = TextEditingController(text: '1');

  List<({int id, String etiqueta})> _tiposCatalogo = [];
  ContextoResidente? _contexto;
  List<MatPeligrosoVista> _registrados = [];
  bool _loading = true;
  String? _avisoMensaje;
  String? _loadError;

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _avisoMensaje = null;
      _loadError = null;
    });
    final client = Supabase.instance.client;
    try {
      final cat = CatalogosResidenteService(client);
      final ges = GestionResidenteService(client);
      final tipos = await cat.tiposMaterialPeligroso();
      final ctx = await ges.contextoResidente();
      List<MatPeligrosoVista> mats = [];
      final idReg = ctx?.idRegistro;
      if (idReg != null) {
        mats = await ges.listarMaterialesPeligrosos(idReg);
      }
      if (!mounted) return;
      setState(() {
        _tiposCatalogo = tipos;
        _contexto = ctx;
        _registrados = mats;
        if (ctx == null) {
          _avisoMensaje = 'No hay grupo familiar asociado a tu cuenta. Completa el registro inicial.';
        } else if (idReg == null) {
          _avisoMensaje = 'No hay un registro de vivienda vigente. Completa el registro del domicilio.';
        } else {
          _avisoMensaje = null;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _snack(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _agregar() async {
    final ctx = _contexto;
    final idReg = ctx?.idRegistro;
    if (ctx == null || idReg == null) {
      _snack(_avisoMensaje ?? 'No se puede guardar sin registro de vivienda vigente.');
      return;
    }
    if (_tipoSeleccionadoId == null) {
      _snack('Selecciona el tipo de material.');
      return;
    }
    final c = int.tryParse(_cantidadController.text.trim());
    if (c == null || c < 1) {
      _snack('Ingresa una cantidad válida.');
      return;
    }
    try {
      await GestionResidenteService(Supabase.instance.client).upsertMaterialPeligroso(
        idRegistro: idReg,
        idMatPelig: _tipoSeleccionadoId!,
        cantidad: c,
      );
      setState(() {
        _tipoSeleccionadoId = null;
        _cantidadController.text = '1';
      });
      final list = await GestionResidenteService(Supabase.instance.client).listarMaterialesPeligrosos(idReg);
      if (!mounted) return;
      setState(() => _registrados = list);
      _snack('Material guardado en tu registro.');
    } on RegistroResidenteException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('No se pudo guardar: $e');
    }
  }

  void _eliminar(MatPeligrosoVista item) {
    final ctx = _contexto;
    final idReg = ctx?.idRegistro;
    if (idReg == null) return;

    showDialog<void>(
      context: context,
      builder: (ctxDialog) => AlertDialog(
        title: const Text('Eliminar material', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('¿Quitar "${item.tipoMat}" del registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctxDialog), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await GestionResidenteService(Supabase.instance.client).eliminarMaterialPeligroso(
                  idRegistro: idReg,
                  idMatPelig: item.idMatPelig,
                );
                if (!ctxDialog.mounted) return;
                Navigator.pop(ctxDialog);
                final list =
                    await GestionResidenteService(Supabase.instance.client).listarMaterialesPeligrosos(idReg);
                if (!mounted) return;
                setState(() => _registrados = list);
                _snack('Material eliminado.');
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
        Navigator.pushReplacementNamed(context, '/gestion-mascotas');
      case 2:
        Navigator.pushReplacementNamed(context, '/gestion-domicilio');
      case 3:
        break;
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
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
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

    final puedeGuardar = _contexto?.idRegistro != null && _tiposCatalogo.isNotEmpty;

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
                  Icon(Icons.warning_amber_rounded, size: 24, color: _textoPrincipal),
                  SizedBox(width: 8),
                  Text(
                    'Materiales Peligrosos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textoPrincipal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Gestiona los materiales peligrosos presentes en tu domicilio',
                style: TextStyle(fontSize: 13, color: _textoGris),
              ),
              const SizedBox(height: 20),
              if (_avisoMensaje != null)
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
                      _avisoMensaje!,
                      style: const TextStyle(fontSize: 13, color: _textoPrincipal, height: 1.35),
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _duraznoFondo,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _duraznoBorde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agregar material peligroso',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tipo de material *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      // ignore: deprecated_member_use
                      value: _tipoSeleccionadoId,
                      decoration: InputDecoration(
                        hintText: 'Selecciona',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _tiposCatalogo
                          .map((e) => DropdownMenuItem<int>(value: e.id, child: Text(e.etiqueta)))
                          .toList(),
                      onChanged: puedeGuardar ? (v) => setState(() => _tipoSeleccionadoId = v) : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Cantidad *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textoPrincipal),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      enabled: puedeGuardar,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: puedeGuardar ? () => _agregar() : null,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Agregar Material', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _duraznoBoton,
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
                'Registrados (${_registrados.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _duraznoTituloLista,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _registrados.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final m = _registrados[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _duraznoItemBorde),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.tipoMat,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: _duraznoTituloLista,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cantidad: ${m.cantidad}',
                                style: const TextStyle(fontSize: 13, color: _textoGris),
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
                              border: Border.all(color: const Color(0xFFE0E0E0)),
                            ),
                            child: InkWell(
                              onTap: () => _eliminar(m),
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
                },
              ),
            ],
          ),
        ),
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
              final selected = i == 3;
              final highlightBg = selected ? _navPeligrososBg : Colors.transparent;
              final iconColor = selected ? _navPeligrosos : _textoGris;
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
