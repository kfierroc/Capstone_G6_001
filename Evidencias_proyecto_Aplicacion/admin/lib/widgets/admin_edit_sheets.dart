import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bombero_list_item.dart';
import '../models/grupo_familiar_detalle.dart';
import '../services/admin_catalog_service.dart';
import '../services/admin_edit_service.dart';
import '../theme/admin_theme.dart';

/// Diálogos de edición reutilizables para el panel admin.
class AdminEditSheets {
  AdminEditSheets._();

  static AdminEditService _edit() => AdminEditService(Supabase.instance.client);
  static AdminCatalogService _catalog() => AdminCatalogService(Supabase.instance.client);

  static Future<bool> confirmarDesvincularResidencia(
    BuildContext context, {
    required String direccion,
    bool cuentaVinculada = false,
  }) async {
    final extraCuenta = cuentaVinculada
        ? '\n\nLa cuenta del titular seguirá existiendo, pero ya no tendrá un domicilio vigente registrado.'
        : '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular residencia'),
        content: Text(
          'Se marcará como no vigente el registro de vivienda en:\n\n$direccion\n\n'
          'El grupo familiar quedará sin domicilio activo asociado.$extraCuenta',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminTheme.warningOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  static Future<bool> confirmarEliminar(BuildContext context, {required String titulo, required String mensaje}) async {
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

  static void showError(BuildContext context, Object e) {
    final msg = e is AdminEditException ? e.message : 'Error al guardar.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  static Future<bool?> editarTelefonoGrupo(
    BuildContext context, {
    required int idGrupof,
    required String telefonoActual,
  }) {
    final ctrl = TextEditingController(text: telefonoActual == '—' ? '' : telefonoActual);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _FormDialog(
        titulo: 'Editar teléfono',
        onGuardar: () async {
          await _edit().actualizarTelefonoGrupo(idGrupof: idGrupof, telefono: ctrl.text);
        },
        child: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Teléfono titular',
            hintText: '+56912345678',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
      ),
    );
  }

  static Future<bool?> editarCuentaGrupo(BuildContext context, {required CuentaGrupoInfo cuenta}) {
    final telCtrl = TextEditingController(text: cuenta.telefono == '—' ? '' : cuenta.telefono);
    final anioCtrl = TextEditingController(text: cuenta.anioNacTitular?.toString() ?? '');

    return showDialog<bool>(
      context: context,
      builder: (ctx) => _FormDialog(
        titulo: 'Editar cuenta',
        onGuardar: () async {
          await _edit().actualizarTelefonoGrupo(idGrupof: cuenta.idGrupof, telefono: telCtrl.text);
          if (cuenta.idIntegranteTitular != null) {
            final anio = int.tryParse(anioCtrl.text.trim());
            if (anio == null) throw AdminEditException('Año de nacimiento inválido.');
            await _edit().actualizarAnioNacTitular(idIntegrante: cuenta.idIntegranteTitular!, anioNac: anio);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: telCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            if (cuenta.idIntegranteTitular != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: anioCtrl,
                decoration: const InputDecoration(labelText: 'Año nacimiento titular', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<bool?> editarRegistroVivienda(BuildContext context, {required DomicilioGrupoInfo domicilio}) {
    if (domicilio.idRegistro == null || !domicilio.tieneRegistro) return Future.value(null);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => _EditarRegistroViviendaDialog(domicilio: domicilio),
    );
  }

  static Future<bool?> agregarIntegrante(BuildContext context, {required int idGrupof}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _IntegranteDialog(idGrupof: idGrupof),
    );
  }

  static Future<bool?> editarIntegrante(BuildContext context, {required IntegranteGrupo integrante}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _IntegranteDialog(integrante: integrante),
    );
  }

  static Future<bool?> agregarMascota(BuildContext context, {required int idGrupof}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _MascotaDialog(idGrupof: idGrupof),
    );
  }

  static Future<bool?> editarMascota(BuildContext context, {required MascotaGrupo mascota}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _MascotaDialog(mascota: mascota),
    );
  }

  static Future<bool?> agregarMaterial(BuildContext context, {required int idRegistro}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _MaterialDialog(idRegistro: idRegistro),
    );
  }

  static Future<bool?> editarMaterial(
    BuildContext context, {
    required int idRegistro,
    required MaterialPeligrosoGrupo material,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _MaterialDialog(idRegistro: idRegistro, material: material),
    );
  }

  static Future<bool?> editarBombero(BuildContext context, {required BomberoListItem bombero}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => _BomberoDialog(bombero: bombero),
    );
  }
}

class _FormDialog extends StatefulWidget {
  const _FormDialog({
    required this.titulo,
    required this.onGuardar,
    required this.child,
  });

  final String titulo;
  final Future<void> Function() onGuardar;
  final Widget child;

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  bool _guardando = false;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await widget.onGuardar();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(width: 420, child: widget.child),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EditarRegistroViviendaDialog extends StatefulWidget {
  const _EditarRegistroViviendaDialog({required this.domicilio});

  final DomicilioGrupoInfo domicilio;

  @override
  State<_EditarRegistroViviendaDialog> createState() => _EditarRegistroViviendaDialogState();
}

class _EditarRegistroViviendaDialogState extends State<_EditarRegistroViviendaDialog> {
  late final TextEditingController _unidadCtrl;
  late final TextEditingController _descDeptoCtrl;
  late final TextEditingController _notasCtrl;
  late final TextEditingController _fechaIniCtrl;
  late final TextEditingController _fechaUltCtrl;

  List<CatalogItem> _tipos = [];
  List<CatalogItem> _estados = [];
  List<CatalogItem> _matsPiso = [];
  int? _idTipo;
  int? _idEstado;
  int? _idMatPiso;
  bool _loading = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final d = widget.domicilio;
    _unidadCtrl = TextEditingController(text: d.unidad ?? '');
    _descDeptoCtrl = TextEditingController(text: d.descDeptoCond ?? '');
    _notasCtrl = TextEditingController(text: d.notas ?? '');
    _fechaIniCtrl = TextEditingController(text: d.fechaInicio == '—' ? '' : d.fechaInicio);
    _fechaUltCtrl = TextEditingController(text: d.fechaUltConfirm == '—' ? '' : d.fechaUltConfirm);
    _idTipo = d.idTipoV;
    _idEstado = d.idEstadoV;
    _idMatPiso = d.idMatPiso;
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    final cat = AdminEditSheets._catalog();
    final results = await Future.wait([
      cat.tiposVivienda(),
      cat.estadosVivienda(),
      cat.materialesPiso(),
    ]);
    if (mounted) {
      setState(() {
        _tipos = results[0];
        _estados = results[1];
        _matsPiso = results[2];
        _loading = false;
      });
    }
  }

  bool get _esDeptoOCondo {
    if (_idTipo == null) return widget.domicilio.esDeptoOCondominio;
    final t = _tipos.where((e) => e.id == _idTipo).map((e) => e.label.toLowerCase()).firstOrNull;
    return t == 'departamento' || t == 'condominio';
  }

  Future<void> _guardar() async {
    final idReg = widget.domicilio.idRegistro!;
    if (_idTipo == null || _idEstado == null) throw AdminEditException('Selecciona tipo y estado de vivienda.');

    setState(() => _guardando = true);
    try {
      await AdminEditSheets._edit().actualizarRegistroVivienda(
        idRegistro: idReg,
        idTipoV: _idTipo!,
        idEstadoV: _idEstado!,
        unidad: _unidadCtrl.text,
        descDeptoCond: _esDeptoOCondo ? _descDeptoCtrl.text : null,
        notasV: _notasCtrl.text,
        fechaIniR: _fechaIniCtrl.text.trim().isEmpty ? null : _fechaIniCtrl.text.trim(),
        fechaUltConfirm: _fechaUltCtrl.text.trim().isEmpty ? null : _fechaUltCtrl.text.trim(),
      );
      if (_idMatPiso != null) {
        await AdminEditSheets._edit().reemplazarMaterialPrimerPiso(idRegistro: idReg, idMatPiso: _idMatPiso!);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _unidadCtrl.dispose();
    _descDeptoCtrl.dispose();
    _notasCtrl.dispose();
    _fechaIniCtrl.dispose();
    _fechaUltCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.domicilio;
    return AlertDialog(
      title: const Text('Editar registro de vivienda'),
      content: SizedBox(
        width: 480,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (d.idRegistro != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'ID registro: ${d.idRegistro}',
                          style: const TextStyle(fontSize: 12, color: AdminTheme.mutedText),
                        ),
                      ),
                    _dropdown('Tipo vivienda', _idTipo, _tipos, (v) => setState(() => _idTipo = v)),
                    const SizedBox(height: 12),
                    _dropdown('Estado vivienda', _idEstado, _estados, (v) => setState(() => _idEstado = v)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _unidadCtrl,
                      decoration: const InputDecoration(labelText: 'Unidad / depto', border: OutlineInputBorder()),
                    ),
                    if (_esDeptoOCondo) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descDeptoCtrl,
                        decoration: const InputDecoration(labelText: 'Desc. depto / cond.', border: OutlineInputBorder()),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _dropdown('Material residencia (piso 1)', _idMatPiso, _matsPiso, (v) => setState(() => _idMatPiso = v)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fechaIniCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Inicio registro (AAAA-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fechaUltCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Última confirmación (AAAA-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notasCtrl,
                      decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No editable: registro vigente (${d.vigente ? 'Sí' : 'No'}), expira (${d.fechaExpiracion}).',
                      style: const TextStyle(fontSize: 11, color: AdminTheme.mutedText),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading || _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _IntegranteDialog extends StatefulWidget {
  const _IntegranteDialog({this.idGrupof, this.integrante})
      : assert(idGrupof != null || integrante != null);

  final int? idGrupof;
  final IntegranteGrupo? integrante;

  @override
  State<_IntegranteDialog> createState() => _IntegranteDialogState();
}

class _IntegranteDialogState extends State<_IntegranteDialog> {
  late final TextEditingController _anioCtrl;
  Set<int> _condiciones = {};
  List<CatalogItem> _catalogo = [];
  bool _loading = true;
  bool _guardando = false;

  bool get _editando => widget.integrante != null;

  @override
  void initState() {
    super.initState();
    final i = widget.integrante;
    _anioCtrl = TextEditingController(text: i?.anioNac.toString() ?? '');
    _condiciones = i?.idsCondiciones.toSet() ?? {};
    _cargar();
  }

  Future<void> _cargar() async {
    final cat = await AdminEditSheets._catalog().condiciones();
    if (mounted) {
      setState(() {
        _catalogo = cat;
        _loading = false;
      });
    }
  }

  Future<void> _guardar() async {
    final anio = int.tryParse(_anioCtrl.text.trim());
    if (anio == null) throw AdminEditException('Año de nacimiento inválido.');

    setState(() => _guardando = true);
    try {
      if (_editando) {
        await AdminEditSheets._edit().actualizarIntegrante(
          idIntegrante: widget.integrante!.idIntegrante,
          esTitular: widget.integrante!.esTitular,
          anioNac: anio,
          idsCondiciones: _condiciones,
        );
      } else {
        await AdminEditSheets._edit().agregarIntegrante(
          idGrupof: widget.idGrupof!,
          anioNac: anio,
          idsCondiciones: _condiciones,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _anioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar integrante' : 'Agregar integrante'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _anioCtrl,
                      decoration: const InputDecoration(labelText: 'Año de nacimiento', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text('Condiciones', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _catalogo.map((c) {
                        final sel = _condiciones.contains(c.id);
                        return FilterChip(
                          label: Text(c.label, style: const TextStyle(fontSize: 12)),
                          selected: sel,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _condiciones.add(c.id);
                            } else {
                              _condiciones.remove(c.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading || _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _MascotaDialog extends StatefulWidget {
  const _MascotaDialog({this.idGrupof, this.mascota}) : assert(idGrupof != null || mascota != null);

  final int? idGrupof;
  final MascotaGrupo? mascota;

  @override
  State<_MascotaDialog> createState() => _MascotaDialogState();
}

class _MascotaDialogState extends State<_MascotaDialog> {
  late final TextEditingController _nombreCtrl;
  int? _idEspecie;
  int? _idTamanio;
  List<CatalogItem> _especies = [];
  List<CatalogItem> _tamanios = [];
  bool _loading = true;
  bool _guardando = false;

  bool get _editando => widget.mascota != null;

  @override
  void initState() {
    super.initState();
    final m = widget.mascota;
    _nombreCtrl = TextEditingController(text: m?.nombre ?? '');
    _idEspecie = m?.idEspecie;
    _idTamanio = m?.idTamanio;
    _cargar();
  }

  Future<void> _cargar() async {
    final cat = AdminEditSheets._catalog();
    final results = await Future.wait([cat.especiesMascota(), cat.tamaniosMascota()]);
    if (mounted) {
      setState(() {
        _especies = results[0];
        _tamanios = results[1];
        _idEspecie ??= _especies.firstOrNull?.id;
        _idTamanio ??= _tamanios.firstOrNull?.id;
        _loading = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (_idEspecie == null || _idTamanio == null) throw AdminEditException('Selecciona especie y tamaño.');

    setState(() => _guardando = true);
    try {
      if (_editando) {
        await AdminEditSheets._edit().actualizarMascota(
          idMascota: widget.mascota!.idMascota,
          nombre: _nombreCtrl.text,
          idEspecie: _idEspecie!,
          idTamanio: _idTamanio!,
        );
      } else {
        await AdminEditSheets._edit().agregarMascota(
          idGrupof: widget.idGrupof!,
          nombre: _nombreCtrl.text,
          idEspecie: _idEspecie!,
          idTamanio: _idTamanio!,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar mascota' : 'Agregar mascota'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  _dropdown('Especie', _idEspecie, _especies, (v) => setState(() => _idEspecie = v)),
                  const SizedBox(height: 12),
                  _dropdown('Tamaño', _idTamanio, _tamanios, (v) => setState(() => _idTamanio = v)),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading || _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _MaterialDialog extends StatefulWidget {
  const _MaterialDialog({required this.idRegistro, this.material});

  final int idRegistro;
  final MaterialPeligrosoGrupo? material;

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  late final TextEditingController _cantCtrl;
  int? _idMat;
  List<CatalogItem> _tipos = [];
  bool _loading = true;
  bool _guardando = false;

  bool get _editando => widget.material != null;

  @override
  void initState() {
    super.initState();
    _cantCtrl = TextEditingController(text: widget.material?.cantidad.toString() ?? '1');
    _idMat = widget.material?.idMatPelig;
    _cargar();
  }

  Future<void> _cargar() async {
    final tipos = await AdminEditSheets._catalog().materialesPeligrosos();
    if (mounted) {
      setState(() {
        _tipos = tipos;
        _idMat ??= tipos.firstOrNull?.id;
        _loading = false;
      });
    }
  }

  Future<void> _guardar() async {
    final cant = int.tryParse(_cantCtrl.text.trim());
    if (_idMat == null || cant == null) throw AdminEditException('Completa tipo y cantidad.');

    setState(() => _guardando = true);
    try {
      await AdminEditSheets._edit().upsertMaterialPeligroso(
        idRegistro: widget.idRegistro,
        idMatPelig: _idMat!,
        cantidad: cant,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _cantCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editando ? 'Editar material peligroso' : 'Agregar material peligroso'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dropdown(
                    'Tipo de material',
                    _idMat,
                    _tipos,
                    _editando ? null : (v) => setState(() => _idMat = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cantCtrl,
                    decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading || _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _BomberoDialog extends StatefulWidget {
  const _BomberoDialog({required this.bombero});

  final BomberoListItem bombero;

  @override
  State<_BomberoDialog> createState() => _BomberoDialogState();
}

class _BomberoDialogState extends State<_BomberoDialog> {
  late final TextEditingController _nombCtrl;
  late final TextEditingController _apeCtrl;
  bool _isAdmin = false;
  int? _idCompania;
  List<CatalogItem> _companias = [];
  bool _loading = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombCtrl = TextEditingController(text: widget.bombero.nombBombero);
    _apeCtrl = TextEditingController(text: widget.bombero.apePBombero);
    _isAdmin = widget.bombero.esAdmin;
    _idCompania = widget.bombero.idCompania;
    _cargar();
  }

  Future<void> _cargar() async {
    final companias = await AdminEditSheets._catalog().companias();
    if (mounted) {
      setState(() {
        _companias = companias;
        _idCompania ??= companias.firstOrNull?.id;
        _loading = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (_idCompania == null) throw AdminEditException('Selecciona una compañía.');

    setState(() => _guardando = true);
    try {
      await AdminEditSheets._edit().actualizarBombero(
        rutNum: widget.bombero.rutNum,
        nombBombero: _nombCtrl.text,
        apePBombero: _apeCtrl.text,
        isAdmin: _isAdmin,
        idCompania: _idCompania!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AdminEditSheets.showError(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _nombCtrl.dispose();
    _apeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar bombero · ${widget.bombero.rutFormateado}'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nombCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apeCtrl,
                    decoration: const InputDecoration(labelText: 'Apellido paterno', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  _dropdown('Compañía', _idCompania, _companias, (v) => setState(() => _idCompania = v)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Administrador'),
                    value: _isAdmin,
                    onChanged: (v) => setState(() => _isAdmin = v),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: _guardando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading || _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

Widget _dropdown(
  String label,
  int? value,
  List<CatalogItem> items,
  ValueChanged<int?>? onChanged,
) {
  final selected = items.any((i) => i.id == value) ? value : null;
  return InputDecorator(
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        isExpanded: true,
        value: selected,
        hint: Text(label, style: const TextStyle(color: AdminTheme.mutedText, fontSize: 14)),
        items: items.map((i) => DropdownMenuItem(value: i.id, child: Text(i.label))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
