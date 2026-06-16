import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/grupo_familiar_detalle.dart';
import '../../services/grupo_familiar_service.dart';
import '../../theme/admin_theme.dart';
import '../../widgets/admin_action_bar.dart';
import '../../widgets/admin_header.dart';

enum _DetalleTab { integrantes, mascotas, materiales }

class GrupoFamiliarDetailScreen extends StatefulWidget {
  const GrupoFamiliarDetailScreen({
    super.key,
    required this.idGrupof,
    required this.alertCount,
    required this.onVolver,
  });

  final int idGrupof;
  final int alertCount;
  final VoidCallback onVolver;

  @override
  State<GrupoFamiliarDetailScreen> createState() => _GrupoFamiliarDetailScreenState();
}

class _GrupoFamiliarDetailScreenState extends State<GrupoFamiliarDetailScreen> {
  GrupoFamiliarDetalle? _detalle;
  bool _loading = true;
  _DetalleTab _tab = _DetalleTab.integrantes;
  final _busquedaController = TextEditingController();

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
    final detalle = await GrupoFamiliarService(Supabase.instance.client).obtenerDetalle(widget.idGrupof);
    if (mounted) {
      setState(() {
        _detalle = detalle;
        _loading = false;
      });
    }
  }

  void _proximamente(String accion) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$accion — próximamente.')));
  }

  String get _tituloTab {
    final d = _detalle;
    if (d == null) return 'Grupo familiar';
    return d.titularEtiqueta;
  }

  @override
  Widget build(BuildContext context) {
    final d = _detalle;
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminHeader(title: 'Grupo Familiar', alertCount: widget.alertCount),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onVolver,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Volver a Grupos Familiares'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.titleText,
                  side: const BorderSide(color: AdminTheme.cardBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 20),
              if (!_loading && d != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tituloTab,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AdminTheme.titleText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        d.direccion,
                        style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (d == null)
          const Expanded(
            child: Center(child: Text('No se pudo cargar el grupo familiar.', style: TextStyle(color: AdminTheme.mutedText))),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoResumen(cuenta: d.cuenta, domicilio: d.domicilio),
                  const SizedBox(height: 16),
                  _TabBar(
                    tab: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                  ),
                  const SizedBox(height: 16),
                  _BarraAccionTab(
                    tab: _tab,
                    esAncho: esAncho,
                    controller: _busquedaController,
                    onChanged: (_) => setState(() {}),
                    onAgregar: () {
                      final msg = switch (_tab) {
                        _DetalleTab.integrantes => 'Agregar integrante',
                        _DetalleTab.mascotas => 'Agregar mascota',
                        _DetalleTab.materiales => 'Agregar material peligroso',
                      };
                      _proximamente(msg);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.cardBorder),
                      ),
                      child: _ContenidoTab(
                        tab: _tab,
                        detalle: d,
                        busqueda: _busquedaController.text.trim(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoResumen extends StatelessWidget {
  const _InfoResumen({required this.cuenta, required this.domicilio});

  final CuentaGrupoInfo cuenta;
  final DomicilioGrupoInfo domicilio;

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    final tarjetas = [
      _InfoCard(
        titulo: 'Información de la cuenta',
        icono: Icons.account_circle_outlined,
        filas: [
          _InfoFila('RUT', cuenta.rutFormateado),
          _InfoFila('Email', _textoEmail(cuenta)),
          _InfoFila('Edad titular', cuenta.edadTitular != null ? '${cuenta.edadTitular} años' : '—'),
          _InfoFila('Teléfono', cuenta.telefono),
          _InfoFila('Fecha registro', cuenta.fechaCreacion),
          _InfoFila('Estado cuenta', cuenta.cuentaVinculada ? 'Vinculada a Supabase Auth' : 'Sin cuenta vinculada'),
        ],
      ),
      _InfoCard(
        titulo: 'Domicilio registrado',
        icono: Icons.home_outlined,
        filas: domicilio.tieneRegistro
            ? [
                _InfoFila('Dirección', domicilio.direccionCompleta),
                _InfoFila('Comuna', domicilio.comuna),
                _InfoFila('Tipo vivienda', domicilio.tipoVivienda),
                _InfoFila('Estado vivienda', domicilio.estadoVivienda),
                if (domicilio.unidad != null) _InfoFila('Unidad / depto', domicilio.unidad!),
                if (domicilio.descDeptoCond != null) _InfoFila('Desc. depto / cond.', domicilio.descDeptoCond!),
                if (domicilio.materialResidencia != null)
                  _InfoFila('Material residencia', domicilio.materialResidencia!),
                _InfoFila('Registro vigente', domicilio.vigente ? 'Sí' : 'No'),
                _InfoFila('Inicio registro', domicilio.fechaInicio),
                _InfoFila('Última confirmación', domicilio.fechaUltConfirm),
                _InfoFila('Expira', domicilio.fechaExpiracion),
                if (domicilio.notas != null && domicilio.notas!.isNotEmpty)
                  _InfoFila('Notas', domicilio.notas!),
                if (domicilio.lat != null && domicilio.lon != null)
                  _InfoFila('Coordenadas', '${domicilio.lat!.toStringAsFixed(5)}, ${domicilio.lon!.toStringAsFixed(5)}'),
              ]
            : const [
                _InfoFila('Estado', 'Sin domicilio registrado'),
              ],
      ),
    ];

    if (esAncho) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: tarjetas[0]),
            const SizedBox(width: 16),
            Expanded(child: tarjetas[1]),
          ],
        ),
      );
    }

    return Column(
      children: [
        tarjetas[0],
        const SizedBox(height: 12),
        tarjetas[1],
      ],
    );
  }

  String _textoEmail(CuentaGrupoInfo c) {
    if (c.email != null && c.email!.isNotEmpty) return c.email!;
    if (c.cuentaVinculada) return 'Cuenta vinculada (email no expuesto)';
    return '—';
  }
}

class _InfoFila {
  const _InfoFila(this.etiqueta, this.valor);

  final String etiqueta;
  final String valor;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.titulo,
    required this.icono,
    required this.filas,
  });

  final String titulo;
  final IconData icono;
  final List<_InfoFila> filas;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 20, color: AdminTheme.infoBlue),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminTheme.titleText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filas.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      f.etiqueta,
                      style: const TextStyle(fontSize: 13, color: AdminTheme.mutedText),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.valor,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AdminTheme.titleText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onChanged});

  final _DetalleTab tab;
  final ValueChanged<_DetalleTab> onChanged;

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
            selected: tab == _DetalleTab.integrantes,
            onTap: () => onChanged(_DetalleTab.integrantes),
          ),
          _TabChip(
            label: 'Mascotas',
            icon: Icons.pets_outlined,
            selected: tab == _DetalleTab.mascotas,
            onTap: () => onChanged(_DetalleTab.mascotas),
          ),
          _TabChip(
            label: 'Materiales Peligrosos',
            icon: Icons.warning_amber_outlined,
            selected: tab == _DetalleTab.materiales,
            onTap: () => onChanged(_DetalleTab.materiales),
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
    required this.esAncho,
    required this.controller,
    required this.onChanged,
    required this.onAgregar,
  });

  final _DetalleTab tab;
  final bool esAncho;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onAgregar;

  String get _hint => switch (tab) {
        _DetalleTab.integrantes => 'Buscar integrante...',
        _DetalleTab.mascotas => 'Buscar mascota...',
        _DetalleTab.materiales => 'Buscar material...',
      };

  String get _boton => switch (tab) {
        _DetalleTab.integrantes => 'Agregar Integrante',
        _DetalleTab.mascotas => 'Agregar Mascota',
        _DetalleTab.materiales => 'Agregar Material',
      };

  IconData get _icono => switch (tab) {
        _DetalleTab.integrantes => Icons.person_add_outlined,
        _DetalleTab.mascotas => Icons.add,
        _DetalleTab.materiales => Icons.add,
      };

  @override
  Widget build(BuildContext context) {
    final barra = esAncho
        ? Row(
            children: [
              Expanded(child: AdminSearchBar(controller: controller, hint: _hint, onChanged: onChanged)),
              const SizedBox(width: 16),
              AdminPrimaryButton(label: _boton, icon: _icono, onPressed: onAgregar),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSearchBar(controller: controller, hint: _hint, onChanged: onChanged),
              const SizedBox(height: 12),
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
  });

  final _DetalleTab tab;
  final GrupoFamiliarDetalle detalle;
  final String busqueda;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _DetalleTab.integrantes => _ListaIntegrantes(
          integrantes: detalle.integrantes,
          busqueda: busqueda,
          titular: detalle.titularEtiqueta,
        ),
      _DetalleTab.mascotas => _ListaMascotas(mascotas: detalle.mascotas, busqueda: busqueda),
      _DetalleTab.materiales => _ListaMateriales(materiales: detalle.materiales, busqueda: busqueda),
    };
  }
}

class _ListaIntegrantes extends StatelessWidget {
  const _ListaIntegrantes({
    required this.integrantes,
    required this.busqueda,
    required this.titular,
  });

  final List<IntegranteGrupo> integrantes;
  final String busqueda;
  final String titular;

  @override
  Widget build(BuildContext context) {
    final q = busqueda.toLowerCase();
    final lista = integrantes.where((i) {
      if (q.isEmpty) return true;
      return i.etiqueta.toLowerCase().contains(q) ||
          (i.rutMostrar?.toLowerCase().contains(q) ?? false) ||
          i.condiciones.any((c) => c.toLowerCase().contains(q));
    }).toList();

    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            integrantes.isEmpty
                ? 'Integrantes del grupo familiar de $titular.'
                : 'Sin integrantes que coincidan con la búsqueda.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminTheme.mutedText, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final p = lista[i];
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
          ],
        );
      },
    );
  }
}

class _ListaMascotas extends StatelessWidget {
  const _ListaMascotas({required this.mascotas, required this.busqueda});

  final List<MascotaGrupo> mascotas;
  final String busqueda;

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
      padding: const EdgeInsets.all(20),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final m = lista[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFEFF6FF),
            child: Icon(Icons.pets, color: AdminTheme.infoBlue, size: 20),
          ),
          title: Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${m.especie} · ${m.tamanio}'),
        );
      },
    );
  }
}

class _ListaMateriales extends StatelessWidget {
  const _ListaMateriales({required this.materiales, required this.busqueda});

  final List<MaterialPeligrosoGrupo> materiales;
  final String busqueda;

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
          materiales.isEmpty ? 'No hay materiales peligrosos registrados.' : 'Sin materiales que coincidan con la búsqueda.',
          style: const TextStyle(color: AdminTheme.mutedText),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(height: 24, color: AdminTheme.cardBorder),
      itemBuilder: (_, i) {
        final m = lista[i];
        return ListTile(
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
        );
      },
    );
  }
}
