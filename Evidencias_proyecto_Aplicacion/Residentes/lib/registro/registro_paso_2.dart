// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/condiciones_catalogo.dart';
import '../services/catalogos_residente_service.dart';
import '../widgets/chile_rut_formatter.dart';
import '../widgets/custom_widgets.dart';
import 'registro_models.dart';

class RegistroPaso2 extends StatefulWidget {
  final RegistroResidenteBorrador draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RegistroPaso2({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<RegistroPaso2> createState() => _RegistroPaso2State();
}

class _RegistroPaso2State extends State<RegistroPaso2> {
  final _rutController = TextEditingController();
  final _telefonoSufijoController = TextEditingController();

  int? _anioNacimiento;
  int? _edadPorAnio;

  final Set<int> _selectedCondicionIds = {};

  bool _catalogLoading = true;
  String? _catalogError;
  List<CategoriaCondicion> _categorias = [];
  final Map<int, bool> _categoriaExpandida = {};

  @override
  void initState() {
    super.initState();
    _cargarCatalogoCondiciones();
  }

  @override
  void dispose() {
    _rutController.dispose();
    _telefonoSufijoController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogoCondiciones() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final svc = CatalogosResidenteService(Supabase.instance.client);
      final list = await svc.condicionesPorCategoria();
      if (!mounted) return;
      setState(() {
        _categorias = list;
        for (final c in list) {
          _categoriaExpandida.putIfAbsent(c.idCategC, () => false);
        }
        _selectedCondicionIds.addAll(widget.draft.idsCondiciones);
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

  Map<int, String> get _etiquetaPorId {
    final m = <int, String>{};
    for (final cat in _categorias) {
      for (final co in cat.condiciones) {
        m[co.idCondicion] = co.tipoCondicion;
      }
    }
    return m;
  }

  void _showSnack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _actualizarEdadDesdeAnio(int? anio) {
    if (anio == null) {
      setState(() => _edadPorAnio = null);
      return;
    }
    final y = DateTime.now().year;
    setState(() => _edadPorAnio = y - anio);
  }

  List<int> get _aniosDisponibles {
    final actual = DateTime.now().year;
    final minAnio = actual - 120;
    final maxAnio = actual - 16;
    return [for (var a = maxAnio; a >= minAnio; a--) a];
  }

  void _toggleCondicion(int idCondicion) {
    setState(() {
      if (_selectedCondicionIds.contains(idCondicion)) {
        _selectedCondicionIds.remove(idCondicion);
      } else {
        _selectedCondicionIds.add(idCondicion);
      }
    });
  }

  void _continuar() {
    final rut = parsearRutChileno(_rutController.text);
    if (rut == null) {
      _showSnack('Ingresa un RUT válido (ej: 12345678-9).');
      return;
    }
    final tel = normalizarTelefonoSufijoChile(_telefonoSufijoController.text);
    if (tel == null) {
      _showSnack('Teléfono inválido: ingresa 9 dígitos empezando por 9 (ej: 912345678).');
      return;
    }
    if (_anioNacimiento == null) {
      _showSnack('Selecciona tu año de nacimiento.');
      return;
    }
    final edad = _edadPorAnio ?? 0;
    if (edad < 16 || edad > 120) {
      _showSnack('Como titular debes tener entre 16 y 120 años según el registro.');
      return;
    }

    final d = widget.draft;
    d.rutNum = rut.num;
    d.rutDv = rut.dv;
    d.telefonoNormalizado = tel;
    d.fechaNacimiento = DateTime(_anioNacimiento!, 1, 1);
    d.idsCondiciones
      ..clear()
      ..addAll(_selectedCondicionIds);

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final etiquetas = _etiquetaPorId;

    Widget bloqueCondiciones;
    if (_catalogLoading) {
      bloqueCondiciones = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_catalogError != null) {
      bloqueCondiciones = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'No se pudieron cargar las condiciones desde la base de datos.\n$_catalogError',
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cargarCatalogoCondiciones,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    } else {
      bloqueCondiciones = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._categorias.asMap().entries.map((entry) {
            final i = entry.key;
            final cat = entry.value;
            final exp = _categoriaExpandida[cat.idCategC] ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCategoriaPanel(
                categoria: cat,
                colorIndex: i,
                isExpanded: exp,
                onToggle: () => setState(
                  () => _categoriaExpandida[cat.idCategC] = !exp,
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0E3FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Condiciones seleccionadas:",
                  style: TextStyle(color: Color(0xFF2C5BA9), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_selectedCondicionIds.isEmpty)
                  const Text("Ninguna seleccionada", style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCondicionIds.map((id) {
                      final label = etiquetas[id] ?? '#$id';
                      return _buildChip(label, () {
                        setState(() => _selectedCondicionIds.remove(id));
                      });
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person_outline, size: 24),
            SizedBox(width: 8),
            Text(
              "Datos del Titular",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Completa tu información como titular del domicilio",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const InputLabel(label: "RUT (Titular)", required: true),
        TextField(
          controller: _rutController,
          keyboardType: TextInputType.text,
          inputFormatters: [ChileRutInputFormatter()],
          decoration: const InputDecoration(
            hintText: "Escribe solo números y el dígito verificador",
          ),
        ),
        const InputLabel(label: "Teléfono", required: true),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: Text(
                '+56 ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _telefonoSufijoController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  hintText: '912345678',
                ),
              ),
            ),
          ],
        ),
        const InputLabel(label: "Año de nacimiento", required: true),
        DropdownButtonFormField<int>(
          value: _anioNacimiento,
          decoration: const InputDecoration(hintText: "Selecciona el año"),
          items: _aniosDisponibles
              .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
              .toList(),
          onChanged: (a) {
            setState(() => _anioNacimiento = a);
            _actualizarEdadDesdeAnio(a);
          },
        ),
        if (_edadPorAnio != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              "Edad aproximada: $_edadPorAnio años (por año de nacimiento)",
              style: const TextStyle(color: Color(0xFF00A84E), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          "Condiciones médicas o especiales",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          "Opciones del catálogo municipal (puedes elegir varias). Si no aplica, deja sin marcar.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        bloqueCondiciones,
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text("Anterior"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _continuar,
                child: const Text("Continuar"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoriaPanel({
    required CategoriaCondicion categoria,
    required int colorIndex,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final esPar = colorIndex % 2 == 0;
    final color = esPar ? Colors.red.shade900 : Colors.orange.shade900;
    final bgColor = esPar ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0);

    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    categoria.categoriaC,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.3),
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Column(
              children: categoria.condiciones.map((cond) {
                return CheckboxListTile(
                  title: Text(cond.tipoCondicion, style: const TextStyle(fontSize: 14)),
                  value: _selectedCondicionIds.contains(cond.idCondicion),
                  activeColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (_) => _toggleCondicion(cond.idCondicion),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Color(0xFF1976D2)),
          ),
        ],
      ),
    );
  }
}
