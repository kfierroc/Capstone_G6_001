import 'package:flutter/material.dart';

import '../models/grupo_familiar_detalle.dart';
import '../theme/admin_theme.dart';
import 'admin_info_card.dart';

/// Tarjetas de cuenta + domicilio (reutilizable en grupo familiar y residencias).
class GrupoFamiliarInfoResumen extends StatelessWidget {
  const GrupoFamiliarInfoResumen({
    super.key,
    required this.cuenta,
    required this.domicilio,
    this.onEditarCuenta,
    this.onVerEditarResidencia,
    this.onEditarRegistro,
    this.onDesvincularResidencia,
  });

  final CuentaGrupoInfo cuenta;
  final DomicilioGrupoInfo domicilio;
  final VoidCallback? onEditarCuenta;
  final VoidCallback? onVerEditarResidencia;
  final VoidCallback? onEditarRegistro;
  final VoidCallback? onDesvincularResidencia;

  @override
  Widget build(BuildContext context) {
    return DomicilioDosColumnasLayout(
      domicilio: domicilio,
      onVerEditarResidencia: onVerEditarResidencia,
      onEditarRegistro: onEditarRegistro,
      onDesvincular: onDesvincularResidencia,
      columnaIzquierda: [
        AdminInfoCard(
          titulo: 'Información de la cuenta',
          icono: Icons.account_circle_outlined,
          onEditar: onEditarCuenta,
          filas: _filasCuenta(cuenta),
        ),
      ],
    );
  }

  static List<AdminInfoFila> _filasCuenta(CuentaGrupoInfo cuenta) => [
        AdminInfoFila('RUT', cuenta.rutFormateado),
        AdminInfoFila('Email', _textoEmail(cuenta)),
        AdminInfoFila('Edad titular', cuenta.edadTitular != null ? '${cuenta.edadTitular} años' : '—'),
        AdminInfoFila('Teléfono', cuenta.telefono),
        AdminInfoFila('Fecha registro', cuenta.fechaCreacion),
        AdminInfoFila(
          'Estado cuenta',
          cuenta.cuentaVinculada ? 'Vinculada a Supabase Auth' : 'Sin cuenta vinculada',
        ),
      ];

  static String _textoEmail(CuentaGrupoInfo c) {
    if (c.email != null && c.email!.isNotEmpty) return c.email!;
    if (c.cuentaVinculada) return 'Cuenta vinculada (email no expuesto)';
    return '—';
  }
}

/// Izquierda: cuenta + residencia. Derecha: registro de vivienda.
class DomicilioDosColumnasLayout extends StatelessWidget {
  const DomicilioDosColumnasLayout({
    super.key,
    required this.domicilio,
    this.columnaIzquierda = const [],
    this.onVerEditarResidencia,
    this.onEditarRegistro,
    this.onDesvincular,
  });

  final DomicilioGrupoInfo domicilio;
  final List<Widget> columnaIzquierda;
  final VoidCallback? onVerEditarResidencia;
  final VoidCallback? onEditarRegistro;
  final VoidCallback? onDesvincular;

  bool get _tieneDatosResidencia => ResidenciaInfoCard.tieneDatos(domicilio);

  bool get _puedeDesvincular =>
      domicilio.vigente && domicilio.idRegistro != null && onDesvincular != null;

  @override
  Widget build(BuildContext context) {
    final esAncho = MediaQuery.sizeOf(context).width >= 900;

    final izquierda = _ColumnaTarjetas(
      children: [
        ...columnaIzquierda,
        if (_tieneDatosResidencia) ...[
          if (columnaIzquierda.isNotEmpty) const SizedBox(height: 12),
          ResidenciaInfoCard(domicilio: domicilio, onVerEditar: onVerEditarResidencia),
        ],
      ],
    );

    final derecha = RegistroViviendaInfoCard(
      domicilio: domicilio,
      onEditar: onEditarRegistro,
      onDesvincular: _puedeDesvincular ? onDesvincular : null,
    );

    if (esAncho) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: izquierda),
            const SizedBox(width: 16),
            Expanded(child: derecha),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        izquierda,
        const SizedBox(height: 12),
        derecha,
      ],
    );
  }
}

class _ColumnaTarjetas extends StatelessWidget {
  const _ColumnaTarjetas({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Datos físicos de la tabla `residencia`.
class ResidenciaInfoCard extends StatelessWidget {
  const ResidenciaInfoCard({
    super.key,
    required this.domicilio,
    this.onVerEditar,
  });

  final DomicilioGrupoInfo domicilio;
  final VoidCallback? onVerEditar;

  static bool tieneDatos(DomicilioGrupoInfo domicilio) =>
      domicilio.idResidencia != null ||
      (domicilio.calle != null && domicilio.nroDireccion != null) ||
      domicilio.comuna != '—';

  @override
  Widget build(BuildContext context) {
    final card = AdminInfoCard(
      titulo: 'Residencia',
      icono: Icons.location_on_outlined,
      filas: filasResidencia(domicilio),
    );

    if (onVerEditar == null || domicilio.idResidencia == null) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onVerEditar,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Ver y editar residencia'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminTheme.infoBlue,
            side: const BorderSide(color: AdminTheme.infoBlue),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  static List<AdminInfoFila> filasResidencia(DomicilioGrupoInfo domicilio) {
    final filas = <AdminInfoFila>[];
    if (domicilio.idResidencia != null) {
      filas.add(AdminInfoFila('ID residencia', '${domicilio.idResidencia}'));
    }
    filas.add(AdminInfoFila('Dirección', _textoDireccion(domicilio)));
    filas.add(AdminInfoFila('Comuna', domicilio.comuna));
    if (domicilio.lat != null) {
      filas.add(AdminInfoFila('Lat', domicilio.lat!.toStringAsFixed(5)));
    }
    if (domicilio.lon != null) {
      filas.add(AdminInfoFila('Long', domicilio.lon!.toStringAsFixed(5)));
    }
    return filas;
  }

  static String _textoDireccion(DomicilioGrupoInfo domicilio) {
    final calle = domicilio.calle?.trim();
    final nro = domicilio.nroDireccion;
    if (calle != null && calle.isNotEmpty && nro != null) {
      return '$calle $nro';
    }
    return domicilio.direccionCompleta == '—' ? '—' : domicilio.direccionCompleta.split(',').first.trim();
  }
}

/// Datos del registro vigente en la tabla `registro_v`.
class RegistroViviendaInfoCard extends StatelessWidget {
  const RegistroViviendaInfoCard({
    super.key,
    required this.domicilio,
    this.onEditar,
    this.onDesvincular,
  });

  final DomicilioGrupoInfo domicilio;
  final VoidCallback? onEditar;
  final VoidCallback? onDesvincular;

  static List<AdminInfoFila> filasRegistroVivienda(DomicilioGrupoInfo domicilio) {
    if (!domicilio.tieneRegistro) {
      return const [AdminInfoFila('Estado', 'Sin registro de vivienda')];
    }

    return [
      if (domicilio.idRegistro != null) AdminInfoFila('ID registro', '${domicilio.idRegistro}'),
      AdminInfoFila('Tipo vivienda', domicilio.tipoVivienda),
      AdminInfoFila('Estado vivienda', domicilio.estadoVivienda),
      if (domicilio.unidad != null && domicilio.unidad!.isNotEmpty)
        AdminInfoFila('Casa interior', domicilio.unidad!),
      if (domicilio.descDeptoCond != null)
        AdminInfoFila('Desc. depto / cond.', domicilio.descDeptoCond!),
      AdminInfoFila('Registro vigente', domicilio.vigente ? 'Sí' : 'No'),
      AdminInfoFila('Inicio registro', domicilio.fechaInicio),
      AdminInfoFila('Última confirmación', domicilio.fechaUltConfirm),
      AdminInfoFila('Expira', domicilio.fechaExpiracion),
      if (domicilio.notas != null && domicilio.notas!.isNotEmpty) AdminInfoFila('Notas', domicilio.notas!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = domicilio.tieneRegistro && domicilio.idRegistro != null && onEditar != null;
    final card = AdminInfoCard(
      titulo: 'Registro de vivienda',
      icono: Icons.home_outlined,
      onEditar: puedeEditar ? onEditar : null,
      filas: filasRegistroVivienda(domicilio),
    );

    if (onDesvincular == null) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onDesvincular,
          icon: const Icon(Icons.link_off, size: 18),
          label: const Text('Desvincular residencia'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminTheme.warningOrange,
            side: const BorderSide(color: AdminTheme.warningOrange),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

/// Atajo para vista de residencia sin grupo familiar.
class DomicilioInfoCard extends StatelessWidget {
  const DomicilioInfoCard({
    super.key,
    required this.domicilio,
    this.onVerEditarResidencia,
    this.onEditarRegistro,
    this.onDesvincular,
    this.encabezadoIzquierdo,
  });

  final DomicilioGrupoInfo domicilio;
  final VoidCallback? onVerEditarResidencia;
  final VoidCallback? onEditarRegistro;
  final VoidCallback? onDesvincular;
  final Widget? encabezadoIzquierdo;

  @override
  Widget build(BuildContext context) {
    return DomicilioDosColumnasLayout(
      domicilio: domicilio,
      onVerEditarResidencia: onVerEditarResidencia,
      onEditarRegistro: onEditarRegistro,
      onDesvincular: onDesvincular,
      columnaIzquierda: encabezadoIzquierdo != null ? [encabezadoIzquierdo!] : const [],
    );
  }
}
