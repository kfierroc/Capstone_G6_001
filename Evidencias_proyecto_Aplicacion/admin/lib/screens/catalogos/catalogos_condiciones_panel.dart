import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/condiciones_catalogo_admin.dart';
import '../../services/admin_catalog_crud_service.dart';
import '../../services/condiciones_catalogo_admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_action_bar.dart';

class CatalogosCondicionesPanel extends StatefulWidget {
  const CatalogosCondicionesPanel({super.key});

  @override
  State<CatalogosCondicionesPanel> createState() => _CatalogosCondicionesPanelState();
}

class _CatalogosCondicionesPanelState extends State<CatalogosCondicionesPanel> {
  final _busquedaController = TextEditingController();
  List<CategoriaCondicionAdmin> _categorias = [];
  bool _loading = true;

  CondicionesCatalogoAdminService get _svc =>
      CondicionesCatalogoAdminService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    final data = await _svc.listarAgrupado();
    if (mounted) {
      setState(() {
        _categorias = data;
        _loading = false;
      });
    }
  }

  List<CategoriaCondicionAdmin> get _filtradas {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) return _categorias;

    return _categorias
        .map((cat) {
          final catMatch = cat.categoriaC.toLowerCase().contains(q) || '${cat.idCategC}'.contains(q);
          final conds = cat.condiciones.where((c) {
            return c.tipoCondicion.toLowerCase().contains(q) || '${c.idCondicion}'.contains(q);
          }).toList();
          if (catMatch) return cat;
          if (conds.isEmpty) return null;
          return CategoriaCondicionAdmin(
            idCategC: cat.idCategC,
            categoriaC: cat.categoriaC,
            condiciones: conds,
          );
        })
        .whereType<CategoriaCondicionAdmin>()
        .toList();
  }

  Future<bool> _confirmar(String titulo, String mensaje) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.alertRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _mostrarError(Object e) {
    final msg = e is AdminCatalogCrudException ? e.message : 'Error al guardar.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _dialogoTexto({
    required String titulo,
    required String label,
    required int maxLength,
    String? inicial,
    required Future<void> Function(String) onGuardar,
  }) async {
    final ctrl = TextEditingController(text: inicial ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              helperText: 'Máx. $maxLength caracteres',
            ),
            maxLength: maxLength,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              try {
                await onGuardar(ctrl.text);
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (!ctx.mounted) return;
                final msg = e is AdminCatalogCrudException ? e.message : 'Error al guardar.';
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok == true) _cargar();
  }

  Future<void> _agregarCategoria() => _dialogoTexto(
        titulo: 'Agregar categoría',
        label: 'Nombre de la categoría',
        maxLength: 30,
        onGuardar: _svc.crearCategoria,
      );

  Future<void> _editarCategoria(CategoriaCondicionAdmin cat) => _dialogoTexto(
        titulo: 'Editar categoría',
        label: 'Nombre de la categoría',
        maxLength: 30,
        inicial: cat.categoriaC,
        onGuardar: (t) => _svc.actualizarCategoria(cat.idCategC, t),
      );

  Future<void> _eliminarCategoria(CategoriaCondicionAdmin cat) async {
    if (cat.condiciones.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Elimina primero las condiciones de esta categoría.'),
        ),
      );
      return;
    }
    if (!await _confirmar('Eliminar categoría', '¿Eliminar "${cat.categoriaC}"?')) return;
    try {
      await _svc.eliminarCategoria(cat.idCategC);
      _cargar();
    } catch (e) {
      _mostrarError(e);
    }
  }

  Future<void> _agregarCondicion(CategoriaCondicionAdmin cat) => _dialogoTexto(
        titulo: 'Agregar condición en "${cat.categoriaC}"',
        label: 'Nombre de la condición',
        maxLength: 40,
        onGuardar: (t) => _svc.crearCondicion(idCategC: cat.idCategC, nombre: t),
      );

  Future<void> _editarCondicion(CategoriaCondicionAdmin cat, CondicionAdminItem cond) =>
      _dialogoTexto(
        titulo: 'Editar condición',
        label: 'Nombre de la condición',
        maxLength: 40,
        inicial: cond.tipoCondicion,
        onGuardar: (t) => _svc.actualizarCondicion(
          idCondicion: cond.idCondicion,
          idCategC: cat.idCategC,
          nombre: t,
        ),
      );

  Future<void> _eliminarCondicion(CondicionAdminItem cond) async {
    if (!await _confirmar('Eliminar condición', '¿Eliminar "${cond.tipoCondicion}"?')) return;
    try {
      await _svc.eliminarCondicion(cond.idCondicion);
      _cargar();
    } catch (e) {
      _mostrarError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Condiciones de salud',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Administra categorías y sus condiciones médicas en una sola vista.',
                style: TextStyle(fontSize: 13, color: AdminTheme.mutedText),
              ),
              const SizedBox(height: 16),
              esAncho
                  ? Row(
                      children: [
                        Expanded(
                          child: AdminSearchBar(
                            controller: _busquedaController,
                            hint: 'Buscar categoría o condición...',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        AdminPrimaryButton(
                          label: 'Agregar categoría',
                          icon: Icons.create_new_folder_outlined,
                          onPressed: _agregarCategoria,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminSearchBar(
                          controller: _busquedaController,
                          hint: 'Buscar categoría o condición...',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        AdminPrimaryButton(
                          label: 'Agregar categoría',
                          icon: Icons.create_new_folder_outlined,
                          onPressed: _agregarCategoria,
                        ),
                      ],
                    ),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtradas.isEmpty
                  ? Center(
                      child: Text(
                        _categorias.isEmpty
                            ? 'No hay categorías registradas. Agrega una para comenzar.'
                            : 'Sin resultados para la búsqueda.',
                        style: const TextStyle(color: AdminTheme.mutedText),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtradas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _tarjetaCategoria(filtradas[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _tarjetaCategoria(CategoriaCondicionAdmin cat) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'ID ${cat.idCategC}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminTheme.infoBlue),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    cat.categoriaC,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _agregarCondicion(cat),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Condición'),
                ),
                IconButton(
                  tooltip: 'Editar categoría',
                  onPressed: () => _editarCategoria(cat),
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
                ),
                IconButton(
                  tooltip: 'Eliminar categoría',
                  onPressed: () => _eliminarCategoria(cat),
                  icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
                ),
              ],
            ),
          ),
          if (cat.condiciones.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Sin condiciones en esta categoría.',
                style: TextStyle(fontSize: 13, color: AdminTheme.mutedText),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminTheme.cardBorder),
              ),
              child: Column(
                children: [
                  for (var j = 0; j < cat.condiciones.length; j++) ...[
                    if (j > 0) const Divider(height: 1, color: AdminTheme.cardBorder),
                    _filaCondicion(cat, cat.condiciones[j]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _filaCondicion(CategoriaCondicionAdmin cat, CondicionAdminItem cond) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('${cond.idCondicion}', style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText)),
          ),
          Expanded(
            child: Text(
              cond.tipoCondicion,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: 'Editar',
            onPressed: () => _editarCondicion(cat, cond),
            icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
          ),
          IconButton(
            tooltip: 'Eliminar',
            onPressed: () => _eliminarCondicion(cond),
            icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
          ),
        ],
      ),
    );
  }
}
