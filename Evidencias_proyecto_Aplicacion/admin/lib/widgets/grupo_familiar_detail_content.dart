import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grupo_familiar_detalle.dart';
import '../services/admin_edit_service.dart';
import '../theme/admin_theme.dart';
import '../widgets/admin_action_bar.dart';
import 'admin_edit_sheets.dart';
import 'domicilio_info_cards.dart';
enum GrupoFamiliarDetalleTab { integrantes, mascotas, materiales, pisos }

/// Cuerpo del detalle de grupo familiar (cuenta, domicilio, pestañas).
class GrupoFamiliarDetailContent extends StatefulWidget {
  const GrupoFamiliarDetailContent({
    super.key,
    required this.detalle,
    required this.onReload,
    this.onVerEditarResidencia,
  });

  final GrupoFamiliarDetalle detalle;
  final Future<void> Function() onReload;
  final ValueChanged<int>? onVerEditarResidencia;

  @override
  State<GrupoFamiliarDetailContent> createState() => _GrupoFamiliarDetailContentState();
}

class _GrupoFamiliarDetailContentState extends State<GrupoFamiliarDetailContent> {
  GrupoFamiliarDetalleTab _tab = GrupoFamiliarDetalleTab.integrantes;
  final _busquedaController = TextEditingController();

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _reloadSi(bool? ok) async {
    if (ok == true) await widget.onReload();
  }

  Future<void> _editarCuenta() async {
    if (!mounted) return;
    final ok = await AdminEditSheets.editarCuentaGrupo(context, cuenta: widget.detalle.cuenta);
    await _reloadSi(ok);
  }

  void _verEditarResidencia() {
    final idRes = widget.detalle.domicilio.idResidencia;
    if (idRes == null) return;
    widget.onVerEditarResidencia?.call(idRes);
  }

  Future<void> _editarRegistroVivienda() async {
    if (!mounted) return;
    final ok = await AdminEditSheets.editarRegistroVivienda(context, domicilio: widget.detalle.domicilio);
    await _reloadSi(ok);
  }

  Future<void> _desvincularResidencia() async {
    final dom = widget.detalle.domicilio;
    final idReg = dom.idRegistro;
    if (!dom.vigente || idReg == null || !mounted) return;

    final ok = await AdminEditSheets.confirmarDesvincularResidencia(
      context,
      direccion: dom.direccionCompleta,
      cuentaVinculada: widget.detalle.cuenta.cuentaVinculada,
    );
    if (!ok || !mounted) return;

    try {
      await AdminEditService(Supabase.instance.client).desvincularRegistroResidencia(idReg);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Residencia desvinculada correctamente.')),
      );
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      AdminEditSheets.showError(context, e);
    }
  }

  Future<void> _agregarTab() async {
    if (!mounted) return;
    final d = widget.detalle;
    final bool? ok;
    switch (_tab) {
      case GrupoFamiliarDetalleTab.integrantes:
        ok = await AdminEditSheets.agregarIntegrante(context, idGrupof: d.idGrupof);
      case GrupoFamiliarDetalleTab.mascotas:
        ok = await AdminEditSheets.agregarMascota(context, idGrupof: d.idGrupof);
      case GrupoFamiliarDetalleTab.materiales:
        if (d.idRegistro == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay registro de vivienda para agregar materiales.')),
            );
          }
          return;
        }
        ok = await AdminEditSheets.agregarMaterial(context, idRegistro: d.idRegistro!);
      case GrupoFamiliarDetalleTab.pisos:
        if (d.idRegistro == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay registro de vivienda para gestionar pisos.')),
            );
          }
          return;
        }
        if (d.domicilio.esDepartamento && d.pisos.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El departamento solo permite un piso. Edítalo desde la lista.')),
            );
          }
          return;
        }
        ok = await AdminEditSheets.agregarPiso(
          context,
          idRegistro: d.idRegistro!,
          esDepartamento: d.domicilio.esDepartamento,
          pisosActuales: d.pisos,
        );
    }
    await _reloadSi(ok);
  }

  Future<void> _editarIntegrante(IntegranteGrupo i) async {
    if (!mounted) return;
    final ok = await AdminEditSheets.editarIntegrante(context, integrante: i);
    await _reloadSi(ok);
  }

  Future<void> _eliminarIntegrante(IntegranteGrupo i) async {
    if (i.esTitular || !mounted) return;
    final ok = await AdminEditSheets.confirmarEliminar(
      context,
      titulo: 'Eliminar integrante',
      mensaje: '¿Eliminar a ${i.etiqueta}?',
    );
    if (!ok || !mounted) return;
    try {
      await AdminEditService(Supabase.instance.client).eliminarIntegrante(i.idIntegrante);
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      AdminEditSheets.showError(context, e);
    }
  }

  Future<void> _editarMascota(MascotaGrupo m) async {
    if (!mounted) return;
    final ok = await AdminEditSheets.editarMascota(context, mascota: m);
    await _reloadSi(ok);
  }

  Future<void> _eliminarMascota(MascotaGrupo m) async {
    if (!mounted) return;
    final ok = await AdminEditSheets.confirmarEliminar(
      context,
      titulo: 'Eliminar mascota',
      mensaje: '¿Eliminar a ${m.nombre}?',
    );
    if (!ok || !mounted) return;
    try {
      await AdminEditService(Supabase.instance.client).eliminarMascota(m.idMascota);
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      AdminEditSheets.showError(context, e);
    }
  }

  Future<void> _editarMaterial(MaterialPeligrosoGrupo m) async {
    final idReg = widget.detalle.idRegistro;
    if (idReg == null || !mounted) return;
    final ok = await AdminEditSheets.editarMaterial(context, idRegistro: idReg, material: m);
    await _reloadSi(ok);
  }

  Future<void> _eliminarMaterial(MaterialPeligrosoGrupo m) async {
    final idReg = widget.detalle.idRegistro;
    if (idReg == null || !mounted) return;
    final ok = await AdminEditSheets.confirmarEliminar(
      context,
      titulo: 'Eliminar material',
      mensaje: '¿Eliminar ${m.tipo}?',
    );
    if (!ok || !mounted) return;
    try {
      await AdminEditService(Supabase.instance.client).eliminarMaterialPeligroso(
        idRegistro: idReg,
        idMatPelig: m.idMatPelig,
      );
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      AdminEditSheets.showError(context, e);
    }
  }

  Future<void> _editarPiso(PisoViviendaGrupo p) async {
    final d = widget.detalle;
    final idReg = d.idRegistro;
    if (idReg == null || !mounted) return;
    final ok = await AdminEditSheets.editarPiso(
      context,
      idRegistro: idReg,
      piso: p,
      esDepartamento: d.domicilio.esDepartamento,
      pisosActuales: d.pisos,
    );
    await _reloadSi(ok);
  }

  Future<void> _eliminarPiso(PisoViviendaGrupo p) async {
    final d = widget.detalle;
    final idReg = d.idRegistro;
    if (idReg == null || !mounted) return;

    final ok = await AdminEditSheets.confirmarEliminar(
      context,
      titulo: 'Eliminar piso',
      mensaje: d.domicilio.esDepartamento
          ? '¿Eliminar el piso ${p.numerop} y su material?'
          : '¿Eliminar el piso ${p.numerop}? Los pisos superiores se renumerarán.',
    );
    if (!ok || !mounted) return;

    try {
      final restantes = d.pisos.where((x) => x.numerop != p.numerop).toList();
      final pisos = d.domicilio.esDepartamento
          ? <({int numerop, int idMatPiso})>[]
          : [
              for (var i = 0; i < restantes.length; i++)
                (numerop: i + 1, idMatPiso: restantes[i].idMatPiso),
            ];
      await AdminEditService(Supabase.instance.client).reemplazarPisos(
        idRegistro: idReg,
        pisos: pisos,
      );
      await widget.onReload();
    } catch (e) {
      if (!mounted) return;
      AdminEditSheets.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;
    final d = widget.detalle;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrupoFamiliarInfoResumen(
            cuenta: d.cuenta,
            domicilio: d.domicilio,
            onEditarCuenta: _editarCuenta,
            onVerEditarResidencia: d.domicilio.idResidencia != null ? _verEditarResidencia : null,
            onEditarRegistro: d.domicilio.tieneRegistro && d.idRegistro != null ? _editarRegistroVivienda : null,
            onDesvincularResidencia:
                d.domicilio.vigente && d.idRegistro != null ? _desvincularResidencia : null,
          ),
          const SizedBox(height: 16),
          _TabBar(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
          const SizedBox(height: 16),
          _BarraAccionTab(
            tab: _tab,
            detalle: d,
            esAncho: esAncho,
            controller: _busquedaController,
            onChanged: (_) => setState(() {}),
            onAgregar: _agregarTab,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 320),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.cardBorder),
            ),
            child: _ContenidoTab(
              tab: _tab,
              detalle: d,
              busqueda: _busquedaController.text.trim(),
              onEditarIntegrante: _editarIntegrante,
              onEliminarIntegrante: _eliminarIntegrante,
              onEditarMascota: _editarMascota,
              onEliminarMascota: _eliminarMascota,
              onEditarMaterial: _editarMaterial,
              onEliminarMaterial: _eliminarMaterial,
              onEditarPiso: _editarPiso,
              onEliminarPiso: _eliminarPiso,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onChanged});

  final GrupoFamiliarDetalleTab tab;
  final ValueChanged<GrupoFamiliarDetalleTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TabChip(
            label: 'Integrantes',
            icon: Icons.person_outline,
            selected: tab == GrupoFamiliarDetalleTab.integrantes,
            onTap: () => onChanged(GrupoFamiliarDetalleTab.integrantes),
          ),
          _TabChip(
            label: 'Mascotas',
            icon: Icons.pets_outlined,
            selected: tab == GrupoFamiliarDetalleTab.mascotas,
            onTap: () => onChanged(GrupoFamiliarDetalleTab.mascotas),
          ),
          _TabChip(
            label: 'Materiales Peligrosos',
            icon: Icons.warning_amber_outlined,
            selected: tab == GrupoFamiliarDetalleTab.materiales,
            onTap: () => onChanged(GrupoFamiliarDetalleTab.materiales),
          ),
          _TabChip(
            label: 'Pisos',
            icon: Icons.layers_outlined,
            selected: tab == GrupoFamiliarDetalleTab.pisos,
            onTap: () => onChanged(GrupoFamiliarDetalleTab.pisos),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? AdminTheme.titleText : AdminTheme.mutedText),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AdminTheme.titleText : AdminTheme.mutedText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraAccionTab extends StatelessWidget {
  const _BarraAccionTab({
    required this.tab,
    required this.detalle,
    required this.esAncho,
    required this.controller,
    required this.onChanged,
    required this.onAgregar,
  });

  final GrupoFamiliarDetalleTab tab;
  final GrupoFamiliarDetalle detalle;
  final bool esAncho;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAgregar;

  String get _hint => switch (tab) {
        GrupoFamiliarDetalleTab.integrantes => '',
        GrupoFamiliarDetalleTab.mascotas => 'Buscar mascota...',
        GrupoFamiliarDetalleTab.materiales => 'Buscar material...',
        GrupoFamiliarDetalleTab.pisos => 'Buscar piso o material...',
      };

  bool get _mostrarBusqueda =>
      tab != GrupoFamiliarDetalleTab.integrantes && tab != GrupoFamiliarDetalleTab.pisos;

  String get _boton => switch (tab) {
        GrupoFamiliarDetalleTab.integrantes => 'Agregar Integrante',
        GrupoFamiliarDetalleTab.mascotas => 'Agregar Mascota',
        GrupoFamiliarDetalleTab.materiales => 'Agregar Material',
        GrupoFamiliarDetalleTab.pisos => 'Agregar Piso',
      };

  IconData get _icono => switch (tab) {
        GrupoFamiliarDetalleTab.integrantes => Icons.person_add_outlined,
        GrupoFamiliarDetalleTab.mascotas => Icons.add,
        GrupoFamiliarDetalleTab.materiales => Icons.add,
        GrupoFamiliarDetalleTab.pisos => Icons.add,
      };

  bool _mostrarAgregar(GrupoFamiliarDetalle detalle) {
    if (tab != GrupoFamiliarDetalleTab.pisos) return true;
    if (detalle.idRegistro == null) return false;
    if (detalle.domicilio.esDepartamento && detalle.pisos.isNotEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final barra = esAncho
        ? Row(
            children: [
              if (_mostrarBusqueda) ...[
                Expanded(child: AdminSearchBar(controller: controller, hint: _hint, onChanged: onChanged)),
                const SizedBox(width: 16),
              ] else
                const Spacer(),
              if (_mostrarAgregar(detalle))
                AdminPrimaryButton(label: _boton, icon: _icono, onPressed: onAgregar),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_mostrarBusqueda) ...[
                AdminSearchBar(controller: controller, hint: _hint, onChanged: onChanged),
                const SizedBox(height: 12),
              ],
              if (_mostrarAgregar(detalle))
                AdminPrimaryButton(label: _boton, icon: _icono, onPressed: onAgregar),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: barra,
    );
  }
}

class _ContenidoTab extends StatelessWidget {
  const _ContenidoTab({
    required this.tab,
    required this.detalle,
    required this.busqueda,
    required this.onEditarIntegrante,
    required this.onEliminarIntegrante,
    required this.onEditarMascota,
    required this.onEliminarMascota,
    required this.onEditarMaterial,
    required this.onEliminarMaterial,
    required this.onEditarPiso,
    required this.onEliminarPiso,
  });

  final GrupoFamiliarDetalleTab tab;
  final GrupoFamiliarDetalle detalle;
  final String busqueda;
  final ValueChanged<IntegranteGrupo> onEditarIntegrante;
  final ValueChanged<IntegranteGrupo> onEliminarIntegrante;
  final ValueChanged<MascotaGrupo> onEditarMascota;
  final ValueChanged<MascotaGrupo> onEliminarMascota;
  final ValueChanged<MaterialPeligrosoGrupo> onEditarMaterial;
  final ValueChanged<MaterialPeligrosoGrupo> onEliminarMaterial;
  final ValueChanged<PisoViviendaGrupo> onEditarPiso;
  final ValueChanged<PisoViviendaGrupo> onEliminarPiso;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      GrupoFamiliarDetalleTab.integrantes => _ListaIntegrantes(
          integrantes: detalle.integrantes,
          titular: detalle.titularEtiqueta,
          onEditar: onEditarIntegrante,
          onEliminar: onEliminarIntegrante,
        ),
      GrupoFamiliarDetalleTab.mascotas => _ListaMascotas(
          mascotas: detalle.mascotas,
          busqueda: busqueda,
          onEditar: onEditarMascota,
          onEliminar: onEliminarMascota,
        ),
      GrupoFamiliarDetalleTab.materiales => _ListaMateriales(
          materiales: detalle.materiales,
          busqueda: busqueda,
          onEditar: onEditarMaterial,
          onEliminar: onEliminarMaterial,
        ),
      GrupoFamiliarDetalleTab.pisos => _ListaPisos(
          pisos: detalle.pisos,
          esDepartamento: detalle.domicilio.esDepartamento,
          tieneRegistro: detalle.idRegistro != null,
          onEditar: onEditarPiso,
          onEliminar: onEliminarPiso,
        ),
    };
  }
}

class _ListaIntegrantes extends StatelessWidget {
  const _ListaIntegrantes({
    required this.integrantes,
    required this.titular,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<IntegranteGrupo> integrantes;
  final String titular;
  final ValueChanged<IntegranteGrupo> onEditar;
  final ValueChanged<IntegranteGrupo> onEliminar;

  @override
  Widget build(BuildContext context) {
    if (integrantes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Integrantes del grupo familiar de $titular.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.mutedText, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: integrantes.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final p = integrantes[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: p.esTitular ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
              child: Icon(
                p.esTitular ? Icons.star_outline : Icons.person_outline,
                size: 20,
                color: p.esTitular ? AdminTheme.infoBlue : AdminTheme.mutedText,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.etiqueta, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${p.edad} años${p.rutMostrar != null ? ' · RUT ${p.rutMostrar}' : ''}',
                    style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                  ),
                  if (p.condiciones.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: p.condiciones
                          .map(
                            (c) => Chip(
                              label: Text(c, style: const TextStyle(fontSize: 11)),
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: () => onEditar(p),
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
                ),
                if (!p.esTitular)
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: () => onEliminar(p),
                    icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ListaMascotas extends StatelessWidget {
  const _ListaMascotas({
    required this.mascotas,
    required this.busqueda,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<MascotaGrupo> mascotas;
  final String busqueda;
  final ValueChanged<MascotaGrupo> onEditar;
  final ValueChanged<MascotaGrupo> onEliminar;

  @override
  Widget build(BuildContext context) {
    final q = busqueda.toLowerCase();
    final lista = mascotas.where((m) {
      if (q.isEmpty) return true;
      return m.nombre.toLowerCase().contains(q) ||
          m.especie.toLowerCase().contains(q) ||
          m.tamanio.toLowerCase().contains(q);
    }).toList();

    if (lista.isEmpty) {
      return Center(
        child: Text(
          mascotas.isEmpty ? 'No hay mascotas registradas.' : 'Sin mascotas que coincidan con la búsqueda.',
          style: const TextStyle(color: AdminTheme.mutedText),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final m = lista[i];
        return Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.pets, color: AdminTheme.infoBlue, size: 20),
                ),
                title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${m.especie} · ${m.tamanio}'),
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => onEditar(m),
              icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () => onEliminar(m),
              icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
            ),
          ],
        );
      },
    );
  }
}

class _ListaMateriales extends StatelessWidget {
  const _ListaMateriales({
    required this.materiales,
    required this.busqueda,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<MaterialPeligrosoGrupo> materiales;
  final String busqueda;
  final ValueChanged<MaterialPeligrosoGrupo> onEditar;
  final ValueChanged<MaterialPeligrosoGrupo> onEliminar;

  @override
  Widget build(BuildContext context) {
    final q = busqueda.toLowerCase();
    final lista = materiales.where((m) {
      if (q.isEmpty) return true;
      return m.tipo.toLowerCase().contains(q);
    }).toList();

    if (lista.isEmpty) {
      return Center(
        child: Text(
          materiales.isEmpty
              ? 'No hay materiales peligrosos registrados.'
              : 'Sin materiales que coincidan con la búsqueda.',
          style: const TextStyle(color: AdminTheme.mutedText),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final m = lista[i];
        return Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF7ED),
                  child: Icon(Icons.warning_amber_outlined, color: AdminTheme.warningOrange, size: 20),
                ),
                title: Text(m.tipo, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text(
                  'x${m.cantidad}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AdminTheme.warningOrange),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => onEditar(m),
              icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () => onEliminar(m),
              icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
            ),
          ],
        );
      },
    );
  }
}

class _ListaPisos extends StatelessWidget {
  const _ListaPisos({
    required this.pisos,
    required this.esDepartamento,
    required this.tieneRegistro,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<PisoViviendaGrupo> pisos;
  final bool esDepartamento;
  final bool tieneRegistro;
  final ValueChanged<PisoViviendaGrupo> onEditar;
  final ValueChanged<PisoViviendaGrupo> onEliminar;

  @override
  Widget build(BuildContext context) {
    if (!tieneRegistro) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No hay registro de vivienda para gestionar pisos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminTheme.mutedText, fontSize: 14),
          ),
        ),
      );
    }

    if (pisos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            esDepartamento
                ? 'Registra el piso del departamento (número real, ej. Piso 22) y su material.'
                : 'Agrega los pisos de la vivienda con su material (Piso 1, Piso 2, …).',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.mutedText, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: pisos.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final p = pisos[i];
        return Row(
          children: [
            Expanded(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    '${p.numerop}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AdminTheme.infoBlue, fontSize: 13),
                  ),
                ),
                title: Text('Piso ${p.numerop}', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(p.material),
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: () => onEditar(p),
              icon: const Icon(Icons.edit_outlined, size: 20, color: AdminTheme.infoBlue),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () => onEliminar(p),
              icon: const Icon(Icons.delete_outline, size: 20, color: AdminTheme.alertRed),
            ),
          ],
        );
      },
    );
  }
}
