import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_catalog_definition.dart';
import '../../services/admin_catalog_crud_service.dart';
import '../../services/admin_catalog_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_header.dart';
import 'catalogos_condiciones_panel.dart';

class CatalogosScreen extends StatefulWidget {
  const CatalogosScreen({super.key, required this.alertCount});

  final int alertCount;

  @override
  State<CatalogosScreen> createState() => _CatalogosScreenState();
}

class _CatalogosScreenState extends State<CatalogosScreen> {
  final _busquedaController = TextEditingController();
  AdminCatalogDefinition _catalogo = AdminCatalogDefinitions.todos.first;
  List<CatalogItem> _items = [];
  bool _loading = true;

  AdminCatalogCrudService get _crud => AdminCatalogCrudService(Supabase.instance.client);

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
    if (_catalogo.esCondicionesUnificadas) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    final items = await _crud.listar(_catalogo);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  void _seleccionarCatalogo(AdminCatalogDefinition def) {
    if (def.key == _catalogo.key) return;
    setState(() {
      _catalogo = def;
      _busquedaController.clear();
    });
    _cargar();
  }

  List<CatalogItem> get _filtrados {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) {
      return i.label.toLowerCase().contains(q) || '${i.id}'.contains(q);
    }).toList();
  }

  Future<void> _agregar() async {
    final ok = await _dialogoItem(titulo: 'Agregar ${_catalogo.titulo.toLowerCase()}');
    if (ok == true) _cargar();
  }

  Future<void> _editar(CatalogItem item) async {
    final ok = await _dialogoItem(
      titulo: 'Editar ${_catalogo.titulo.toLowerCase()}',
      valorInicial: item.label,
      id: item.id,
    );
    if (ok == true) _cargar();
  }

  Future<void> _eliminar(CatalogItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ítem'),
        content: Text('¿Eliminar "${item.label}" del catálogo?'),
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
    if (ok != true || !mounted) return;
    try {
      await _crud.eliminar(_catalogo, item.id);
      if (mounted) _cargar();
    } catch (e) {
      if (!mounted) return;
      final msg = e is AdminCatalogCrudException ? e.message : 'Error al eliminar.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<bool?> _dialogoItem({
    required String titulo,
    String? valorInicial,
    int? id,
  }) {
    final ctrl = TextEditingController(text: valorInicial ?? '');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nombre',
              border: const OutlineInputBorder(),
              helperText: 'Máx. ${_catalogo.labelMaxLength} caracteres',
            ),
            maxLength: _catalogo.labelMaxLength,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              try {
                if (id == null) {
                  await _crud.crear(_catalogo, ctrl.text);
                } else {
                  await _crud.actualizar(_catalogo, id, ctrl.text);
                }
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
  }

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;
    final filtrados = _filtrados;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Catálogos', alertCount: widget.alertCount),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
            child: esAncho
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 280, child: _panelTipos()),
                      const SizedBox(width: 16),
                      Expanded(child: _panelItems(filtrados, esAncho: true)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _panelTipos(compacto: true),
                      const SizedBox(height: 12),
                      Expanded(child: _panelItems(filtrados, esAncho: false)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _panelTipos({bool compacto = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
            child: Text(
              'Tipos de catálogo',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
            ),
          ),
          if (compacto)
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _catalogo.key,
                items: AdminCatalogDefinitions.todos
                    .map((d) => DropdownMenuItem(value: d.key, child: Text(d.titulo)))
                    .toList(),
                onChanged: (k) {
                  final def = AdminCatalogDefinitions.porKey(k ?? '');
                  if (def != null) _seleccionarCatalogo(def);
                },
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: AdminCatalogDefinitions.todos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final def = AdminCatalogDefinitions.todos[i];
                  final sel = def.key == _catalogo.key;
                  return Material(
                    color: sel ? const Color(0xFFEFF6FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => _seleccionarCatalogo(def),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              def.titulo,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                                color: sel ? AdminTheme.infoBlue : AdminTheme.titleText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              def.descripcion,
                              style: const TextStyle(fontSize: 11, color: AdminTheme.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _panelItems(List<CatalogItem> filtrados, {required bool esAncho}) {
    if (_catalogo.esCondicionesUnificadas) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminTheme.cardBorder),
        ),
        child: const CatalogosCondicionesPanel(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _catalogo.titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminTheme.titleText),
                ),
                const SizedBox(height: 4),
                Text(
                  _catalogo.descripcion,
                  style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                ),
                const SizedBox(height: 16),
                esAncho
                    ? Row(
                        children: [
                          Expanded(
                            child: AdminSearchBar(
                              controller: _busquedaController,
                              hint: 'Buscar por nombre o ID...',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 16),
                          AdminPrimaryButton(label: 'Agregar ítem', icon: Icons.add, onPressed: _agregar),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AdminSearchBar(
                            controller: _busquedaController,
                            hint: 'Buscar por nombre o ID...',
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          AdminPrimaryButton(label: 'Agregar ítem', icon: Icons.add, onPressed: _agregar),
                        ],
                      ),
              ],
            ),
          ),
          const Divider(height: 1, color: AdminTheme.cardBorder),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? Center(
                        child: Text(
                          _items.isEmpty ? 'No hay ítems en este catálogo.' : 'Sin resultados para la búsqueda.',
                          style: const TextStyle(color: AdminTheme.mutedText),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtrados.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: AdminTheme.cardBorder),
                          itemBuilder: (_, i) {
                            final item = filtrados[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 56,
                                    child: Text(
                                      '${item.id}',
                                      style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => _editar(item),
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () => _eliminar(item),
                                    icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
