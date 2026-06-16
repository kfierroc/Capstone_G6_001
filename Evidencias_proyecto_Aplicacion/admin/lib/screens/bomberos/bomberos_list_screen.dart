import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bombero_list_item.dart';
import '../../services/bomberos_admin_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_header.dart';

class BomberosListScreen extends StatefulWidget {
  const BomberosListScreen({super.key, required this.alertCount});

  final int alertCount;

  @override
  State<BomberosListScreen> createState() => _BomberosListScreenState();
}

class _BomberosListScreenState extends State<BomberosListScreen> {
  final _busquedaController = TextEditingController();
  List<BomberoListItem> _bomberos = [];
  bool _loading = true;

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
    final lista = await BomberosAdminService(Supabase.instance.client).listarBomberos();
    if (mounted) {
      setState(() {
        _bomberos = lista;
        _loading = false;
      });
    }
  }

  void _proximamente(String accion) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$accion — próximamente.')));
  }

  List<BomberoListItem> get _filtrados {
    final q = _busquedaController.text.trim();
    return _bomberos.where((b) => b.coincideConBusqueda(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Bomberos', alertCount: widget.alertCount),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminTheme.cardBorder),
            ),
            child: esAncho
                ? Row(
                    children: [
                      Expanded(
                        child: AdminSearchBar(
                          controller: _busquedaController,
                          hint: 'Buscar por nombre, RUT o compañía...',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AdminPrimaryButton(
                        label: 'Agregar Bombero',
                        icon: Icons.add,
                        onPressed: () => _proximamente('Agregar bombero'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AdminSearchBar(
                        controller: _busquedaController,
                        hint: 'Buscar por nombre, RUT o compañía...',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      AdminPrimaryButton(
                        label: 'Agregar Bombero',
                        icon: Icons.add,
                        onPressed: () => _proximamente('Agregar bombero'),
                      ),
                    ],
                  ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminTheme.cardBorder),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtrados.isEmpty
                      ? Center(
                          child: Text(
                            _bomberos.isEmpty
                                ? 'No hay bomberos registrados.'
                                : 'Sin resultados para la búsqueda.',
                            style: const TextStyle(color: AdminTheme.mutedText),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargar,
                          child: esAncho
                              ? _TablaDesktop(
                                  bomberos: filtrados,
                                  onVerDetalle: () => _proximamente('Ver detalle'),
                                  onEditar: () => _proximamente('Editar'),
                                  onEliminar: () => _proximamente('Eliminar'),
                                )
                              : _ListaMobile(
                                  bomberos: filtrados,
                                  onVerDetalle: () => _proximamente('Ver detalle'),
                                  onEditar: () => _proximamente('Editar'),
                                  onEliminar: () => _proximamente('Eliminar'),
                                ),
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TablaDesktop extends StatelessWidget {
  const _TablaDesktop({
    required this.bomberos,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<BomberoListItem> bomberos;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminTheme.mutedText,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('RUT', style: _headerStyle)),
              Expanded(flex: 3, child: Text('NOMBRE', style: _headerStyle)),
              Expanded(flex: 3, child: Text('COMPAÑÍA', style: _headerStyle)),
              Expanded(flex: 2, child: Text('COMUNA', style: _headerStyle)),
              Expanded(flex: 2, child: Text('ROL', style: _headerStyle)),
              Expanded(flex: 2, child: Text('CUENTA', style: _headerStyle)),
              SizedBox(width: 260, child: Text('ACCIONES', style: _headerStyle)),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
        ...bomberos.map(
          (b) => _FilaDesktop(
            bombero: b,
            onVerDetalle: onVerDetalle,
            onEditar: onEditar,
            onEliminar: onEliminar,
          ),
        ),
      ],
    );
  }
}

class _FilaDesktop extends StatelessWidget {
  const _FilaDesktop({
    required this.bombero,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
  });

  final BomberoListItem bombero;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  static const _cellStyle = TextStyle(fontSize: 14, color: AdminTheme.titleText);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 2, child: Text(bombero.rutFormateado, style: _cellStyle)),
              Expanded(flex: 3, child: Text(bombero.nombreCompleto, style: _cellStyle)),
              Expanded(flex: 3, child: Text(bombero.compania, style: _cellStyle)),
              Expanded(flex: 2, child: Text(bombero.comuna, style: _cellStyle)),
              Expanded(flex: 2, child: _RolBadge(esAdmin: bombero.esAdmin)),
              Expanded(flex: 2, child: _CuentaBadge(vinculada: bombero.tieneCuenta)),
              SizedBox(
                width: 260,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminOutlineButton(label: 'Ver Detalle', onPressed: onVerDetalle),
                    AdminOutlineButton(label: 'Editar', onPressed: onEditar),
                    AdminDangerButton(label: 'Eliminar', onPressed: onEliminar),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AdminTheme.cardBorder),
      ],
    );
  }
}

class _RolBadge extends StatelessWidget {
  const _RolBadge({required this.esAdmin});

  final bool esAdmin;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: esAdmin ? const Color(0xFFEFF6FF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          esAdmin ? 'Administrador' : 'Bombero',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: esAdmin ? AdminTheme.infoBlue : AdminTheme.mutedText,
          ),
        ),
      ),
    );
  }
}

class _CuentaBadge extends StatelessWidget {
  const _CuentaBadge({required this.vinculada});

  final bool vinculada;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            vinculada ? Icons.check_circle_outline : Icons.link_off,
            size: 16,
            color: vinculada ? AdminTheme.successGreen : AdminTheme.mutedText,
          ),
          const SizedBox(width: 4),
          Text(
            vinculada ? 'Vinculada' : 'Sin cuenta',
            style: TextStyle(
              fontSize: 12,
              color: vinculada ? AdminTheme.successGreen : AdminTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaMobile extends StatelessWidget {
  const _ListaMobile({
    required this.bomberos,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<BomberoListItem> bomberos;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bomberos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = bomberos[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AdminTheme.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b.nombreCompleto,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  _RolBadge(esAdmin: b.esAdmin),
                ],
              ),
              const SizedBox(height: 4),
              Text(b.rutFormateado, style: const TextStyle(color: AdminTheme.mutedText, fontSize: 13)),
              const SizedBox(height: 8),
              Text('${b.compania} · ${b.comuna}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              _CuentaBadge(vinculada: b.tieneCuenta),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminOutlineButton(label: 'Ver Detalle', onPressed: onVerDetalle),
                  AdminOutlineButton(label: 'Editar', onPressed: onEditar),
                  AdminDangerButton(label: 'Eliminar', onPressed: onEliminar),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
