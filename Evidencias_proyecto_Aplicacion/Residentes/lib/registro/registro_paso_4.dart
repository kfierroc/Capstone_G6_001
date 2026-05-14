// DropdownButtonFormField sigue usando `value` para estado controlado hasta migrar a DropdownMenu.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/catalogos_residente_service.dart';
import '../widgets/custom_widgets.dart';
import 'registro_models.dart';

class RegistroPaso4 extends StatefulWidget {
  final RegistroResidenteBorrador draft;
  final Future<void> Function() onComplete;
  final VoidCallback onBack;
  final bool enviando;

  const RegistroPaso4({
    super.key,
    required this.draft,
    required this.onComplete,
    required this.onBack,
    this.enviando = false,
  });

  @override
  State<RegistroPaso4> createState() => _RegistroPaso4State();
}

class _RegistroPaso4State extends State<RegistroPaso4> {
  static const List<int> _mesesPermitidos = [1, 2, 3, 4, 5, 6];

  /// Debe coincidir con `tipo_vivienda.tipo_v` en la base de datos.
  static const String _tipoDepartamento = 'Departamento';
  static const String _tipoCondominio = 'Condominio';

  /// Pisos seleccionables para departamento (`piso_v.numerop`).
  static final List<int> _numerosPisoDepartamento = List<int>.generate(60, (i) => i + 1);

  String? _selectedTipo;
  String? _selectedEstado;
  String? _selectedMaterial;
  int? _numeropDepartamento;
  /// Meses de permanencia (1–6); definido solo en el front.
  int? _mesesTiempo;
  final List<Map<String, String>> _floors = [];
  final _notasController = TextEditingController();
  final _descDeptoCondController = TextEditingController();

  bool _catalogLoading = true;
  String? _catalogError;
  List<String> _tiposVivienda = [];
  List<String> _estadosVivienda = [];
  List<String> _materialesPiso = [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _notasController.dispose();
    _descDeptoCondController.dispose();
    super.dispose();
  }

  bool _esDepartamento(String? t) => t != null && t.trim() == _tipoDepartamento;

  bool _esCondominio(String? t) => t != null && t.trim() == _tipoCondominio;

  bool _esDeptoOCondominio(String? t) => _esDepartamento(t) || _esCondominio(t);

  void _onTipoViviendaChanged(String? val) {
    setState(() {
      _selectedTipo = val;
      _floors.clear();
      _numeropDepartamento = null;
      _selectedMaterial = null;
      if (!_esDeptoOCondominio(val)) {
        _descDeptoCondController.clear();
      }
    });
  }

  Future<void> _cargarCatalogos() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final svc = CatalogosResidenteService(Supabase.instance.client);
      final out = await Future.wait([
        svc.tiposVivienda(),
        svc.estadosVivienda(),
        svc.materialesPiso(),
      ]);
      if (!mounted) return;
      setState(() {
        _tiposVivienda = out[0];
        _estadosVivienda = out[1];
        _materialesPiso = out[2];
        _catalogLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = e.toString();
        _catalogLoading = false;
      });
    }
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _addFloor() {
    if (_selectedMaterial != null) {
      setState(() {
        _floors.add({
          "number": "${_floors.length + 1}",
          "material": _selectedMaterial!,
        });
        _selectedMaterial = null;
      });
    }
  }

  void _removeFloor(int index) {
    setState(() {
      _floors.removeAt(index);
      for (int i = 0; i < _floors.length; i++) {
        _floors[i]["number"] = "${i + 1}";
      }
    });
  }

  Future<void> _completar() async {
    if (_mesesTiempo == null) {
      _showSnack('Selecciona el tiempo en la residencia (1 a 6 meses).');
      return;
    }
    if (_selectedTipo == null) {
      _showSnack('Selecciona el tipo de vivienda.');
      return;
    }
    final esDept = _esDepartamento(_selectedTipo);
    if (esDept) {
      if (_numeropDepartamento == null) {
        _showSnack('Selecciona el número de piso de tu departamento.');
        return;
      }
      if (_selectedMaterial == null) {
        _showSnack('Selecciona el material del piso.');
        return;
      }
    } else if (_floors.isEmpty) {
      _showSnack('Agrega al menos un piso con su material.');
      return;
    }
    if (_selectedEstado == null) {
      _showSnack('Selecciona el estado de la vivienda.');
      return;
    }
    if (_esDeptoOCondominio(_selectedTipo) && _descDeptoCondController.text.trim().isEmpty) {
      _showSnack('Ingresa la descripción de departamento o condominio.');
      return;
    }

    final d = widget.draft;
    d.mesesTiempoResidencia = _mesesTiempo;
    d.tipoViviendaEtiqueta = _selectedTipo;
    d.estadoViviendaEtiqueta = _selectedEstado;
    d.notasVivienda = _notasController.text.trim().isEmpty ? null : _notasController.text.trim();
    final descTrim = _descDeptoCondController.text.trim();
    d.descDeptoCond = _esDeptoOCondominio(_selectedTipo) ? descTrim : null;

    d.pisos.clear();
    if (esDept) {
      d.pisos.add(
        PisoBorrador(
          numerop: _numeropDepartamento!,
          materialEtiqueta: _selectedMaterial!,
        ),
      );
    } else {
      d.pisos.addAll(
        _floors.map((f) {
          final n = int.parse(f['number']!);
          return PisoBorrador(numerop: n, materialEtiqueta: f['material']!);
        }),
      );
    }

    await widget.onComplete();
  }

  List<DropdownMenuItem<String>> _itemsDesde(List<String> opciones) {
    return opciones.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))).toList();
  }

  /// Habilita “Completar”: departamento con piso+material; otros tipos con al menos un piso agregado.
  bool get _formularioPisosListo {
    final t = _selectedTipo;
    if (t == null) return false;
    if (_esDepartamento(t)) {
      return _numeropDepartamento != null && _selectedMaterial != null;
    }
    return _floors.isNotEmpty;
  }

  String _resumenPisosTexto() {
    final t = _selectedTipo;
    if (t == null) return 'No especificado';
    if (_esDepartamento(t)) {
      final n = _numeropDepartamento;
      return n == null ? 'No especificado' : 'Piso $n (1 registro)';
    }
    if (_floors.isEmpty) return 'No especificado';
    return '${_floors.length}';
  }

  @override
  Widget build(BuildContext context) {
    final calle = widget.draft.calle ?? '';
    final nroDir = widget.draft.nroDireccion;

    if (_catalogLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_catalogError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No se pudieron cargar los catálogos desde la base de datos.\n$_catalogError',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _cargarCatalogos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.home_outlined, size: 24),
            SizedBox(width: 8),
            Text(
              "Detalles de la Vivienda",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Proporciona información adicional sobre tu vivienda que ayudará a los bomberos en caso de emergencia",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 20),
        const InputLabel(label: "Tiempo en la residencia (meses)", required: true),
        DropdownButtonFormField<int>(
          value: _mesesTiempo,
          decoration: const InputDecoration(hintText: "1 a 6 meses"),
          items: _mesesPermitidos
              .map(
                (n) => DropdownMenuItem<int>(
                  value: n,
                  child: Text(n == 1 ? '1 mes' : '$n meses'),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _mesesTiempo = val),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0E3FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF2C5BA9)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Cuando el tiempo en la residencia se agota, automáticamente se desvincula el grupo familiar de la residencia.",
                  style: TextStyle(color: Color(0xFF2C5BA9), fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const InputLabel(label: "Tipo de vivienda", required: true),
        _tiposVivienda.isEmpty
            ? const Text(
                'No hay opciones en tipo_vivienda.',
                style: TextStyle(color: Colors.orange),
              )
            : DropdownButtonFormField<String>(
                value: _selectedTipo,
                decoration: const InputDecoration(hintText: "Selecciona el tipo de vivienda"),
                items: _itemsDesde(_tiposVivienda),
                onChanged: _onTipoViviendaChanged,
              ),
        if (_esDeptoOCondominio(_selectedTipo)) ...[
          const SizedBox(height: 16),
          const InputLabel(label: "Descripción departamento / condominio", required: true),
          TextField(
            controller: _descDeptoCondController,
            maxLength: 50,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: "Ej.: torre norte, unidad 502, bloque B",
            ),
          ),
        ],
        if (_selectedTipo != null) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: _esDepartamento(_selectedTipo)
                ? _buildBloqueDepartamento()
                : _buildBloquePisosMultiple(),
          ),
        ],
        const SizedBox(height: 20),
        const InputLabel(label: "Estado general de la vivienda", required: true),
        _estadosVivienda.isEmpty
            ? const Text(
                'No hay opciones en estado_vivienda.',
                style: TextStyle(color: Colors.orange),
              )
            : DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: const InputDecoration(hintText: "Selecciona el estado"),
                items: _itemsDesde(_estadosVivienda),
                onChanged: (val) => setState(() => _selectedEstado = val),
              ),
        const InputLabel(label: "Instrucciones especiales"),
        TextField(
          controller: _notasController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Información adicional relevante para bomberos (accesos especiales, llaves, etc.)",
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Resumen de tu información",
                    style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  Widget group1 = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryItem("Calle:", calle),
                      _buildSummaryItem("Número:", nroDir == null ? '' : '$nroDir'),
                      _buildSummaryItem(
                        "Tiempo en la residencia:",
                        _mesesTiempo == null
                            ? "No especificado"
                            : (_mesesTiempo == 1 ? '1 mes' : '$_mesesTiempo meses'),
                      ),
                    ],
                  );

                  Widget group2 = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryItem("Tipo:", _selectedTipo ?? "No especificado"),
                      if (_esDeptoOCondominio(_selectedTipo))
                        _buildSummaryItem(
                          "Desc. depto/cond.:",
                          _descDeptoCondController.text.trim().isEmpty
                              ? "—"
                              : _descDeptoCondController.text.trim(),
                        ),
                      _buildSummaryItem("Pisos:", _resumenPisosTexto()),
                      _buildSummaryItem("Estado:", _selectedEstado ?? "No especificado"),
                    ],
                  );

                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [group1, group2],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: group1),
                        const SizedBox(width: 12),
                        Expanded(child: group2),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.enviando ? null : widget.onBack,
                child: const Text("Anterior"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: widget.enviando ||
                        _tiposVivienda.isEmpty ||
                        _estadosVivienda.isEmpty ||
                        _materialesPiso.isEmpty ||
                        !_formularioPisosListo
                    ? null
                    : _completar,
                child: widget.enviando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Completar configuración"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBloqueDepartamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Departamento (un solo piso)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        const Text(
          'Selecciona el número de piso donde está tu unidad y el material del piso registrado en catálogo.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 350;
            final numeropDd = DropdownButtonFormField<int>(
              value: _numeropDepartamento,
              decoration: const InputDecoration(
                labelText: 'Número de piso',
                hintText: 'Selecciona',
              ),
              items: _numerosPisoDepartamento
                  .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => _numeropDepartamento = v),
            );
            final materialCol = _buildMaterialDropdown();
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  numeropDd,
                  const SizedBox(height: 12),
                  materialCol,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: numeropDd),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: materialCol),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBloquePisosMultiple() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Agregar pisos de la vivienda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 350;
            return isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNextFloorIndicator(),
                      const SizedBox(height: 12),
                      _buildMaterialDropdown(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(flex: 2, child: _buildNextFloorIndicator()),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: _buildMaterialDropdown()),
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: (_materialesPiso.isNotEmpty && _selectedMaterial != null) ? _addFloor : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8BA9FF),
            minimumSize: const Size(double.infinity, 45),
          ),
          child: Text("+ Agregar Piso ${_floors.length + 1}"),
        ),
        if (_floors.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text("Pisos agregados (${_floors.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ..._floors.asMap().entries.map((entry) {
            final idx = entry.key;
            final floor = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Piso ${floor['number']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Material: ${floor['material']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _removeFloor(idx),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 11, height: 1.4),
          children: [
            TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildNextFloorIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0E3FF)),
      ),
      child: Text(
        "Se agregará: Piso ${_floors.length + 1}",
        style: const TextStyle(color: Color(0xFF2C5BA9), fontSize: 13),
      ),
    );
  }

  Widget _buildMaterialDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Material del piso *", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _materialesPiso.isEmpty
            ? const Text(
                'No hay materiales en tipo_mat_piso.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              )
            : DropdownButtonFormField<String>(
                value: _selectedMaterial,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: "Selecciona el material",
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _materialesPiso
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedMaterial = val),
              ),
      ],
    );
  }
}
