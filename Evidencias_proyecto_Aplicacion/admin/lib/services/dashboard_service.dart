import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_desglose.dart';
import '../models/dashboard_stats.dart';

/// Filtro territorial para métricas del dashboard.
class DashboardFiltroUbicacion {
  const DashboardFiltroUbicacion({this.cutCom, this.cutComsRegion, this.etiqueta = 'Todo Chile'});

  final int? cutCom;
  final List<int>? cutComsRegion;
  final String etiqueta;

  bool get activo => cutCom != null || (cutComsRegion != null && cutComsRegion!.isNotEmpty);

  bool get regionSinComunas => cutComsRegion != null && cutComsRegion!.isEmpty;
}

/// Consultas agregadas para el dashboard admin.
class DashboardService {
  DashboardService(this._client);

  final SupabaseClient _client;

  Future<DashboardStats> cargarEstadisticas({DashboardFiltroUbicacion? filtro}) async {
    final f = filtro ?? const DashboardFiltroUbicacion();
    if (f.regionSinComunas) {
      return DashboardStats.empty.copyWith(etiquetaUbicacion: f.etiqueta);
    }

    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 0);
    final desde = _formatoFecha(inicioMes);
    final hasta = _formatoFecha(finMes);

    final conteos = await Future.wait<int>([
      _contarIntegrantesActivos(f),
      _contarIntegrantesEsteMes(f, desde, hasta),
      _contarHogaresVigentes(f),
      _contarGruposEsteMes(f, desde, hasta),
      _contarBomberos(f),
      _contarCompanias(f),
      _contarGrifos(f),
      _contarGrifosAtencion(f),
      _contarMascotas(f),
      _sumarMaterialesPeligrosos(f),
      _contarCondicionesMedicas(f),
      _contarRegistrosPorExpirar(f),
      _contarGruposFamiliares(f),
      _contarGruposConCuenta(f),
      _contarHogaresEstadoDeficiente(f),
      _contarBomberosAdministradores(f),
    ]);

    final analitica = await Future.wait([
      _perfilEtario(f),
      _desgloseTiposVivienda(f),
      _desgloseEstadosVivienda(f),
      _desgloseCategoriasCondicion(f),
      _desgloseEspeciesMascota(f),
      _desgloseMaterialesPeligrosos(f),
      _desgloseMaterialesPiso(f),
      _desgloseEstadosGrifo(f),
    ]);

    final grifosAtencion = conteos[7];
    final registrosPorExpirar = conteos[11];

    return DashboardStats(
      totalResidentes: conteos[0],
      residentesEsteMes: conteos[1],
      totalHogares: conteos[2],
      hogaresEsteMes: conteos[3],
      totalBomberos: conteos[4],
      totalCompanias: conteos[5],
      totalGrifos: conteos[6],
      grifosRequierenAtencion: grifosAtencion,
      totalMascotas: conteos[8],
      totalMaterialesPeligrosos: conteos[9],
      totalCondicionesMedicas: conteos[10],
      registrosPorExpirar: registrosPorExpirar,
      totalAlertas: grifosAtencion + registrosPorExpirar,
      etiquetaUbicacion: f.etiqueta,
      totalGruposFamiliares: conteos[12],
      gruposConCuenta: conteos[13],
      hogaresEstadoDeficiente: conteos[14],
      bomberosAdministradores: conteos[15],
      perfilEtario: analitica[0] as DashboardPerfilEtario,
      tiposVivienda: analitica[1] as List<DashboardDesglose>,
      estadosVivienda: analitica[2] as List<DashboardDesglose>,
      categoriasCondicion: analitica[3] as List<DashboardDesglose>,
      especiesMascota: analitica[4] as List<DashboardDesglose>,
      materialesPeligrososPorTipo: analitica[5] as List<DashboardDesglose>,
      materialesPiso: analitica[6] as List<DashboardDesglose>,
      estadosGrifo: analitica[7] as List<DashboardDesglose>,
    );
  }

  // ── Conteos principales ─────────────────────────────────────────────

  Future<int> _contarGruposFamiliares(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contar('grupofamiliar');
    try {
      var query = _client
          .from('grupofamiliar')
          .select('id_grupof, registro_v!inner(vigente, residencia!inner(cut_com))')
          .eq('registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarGruposConCuenta(DashboardFiltroUbicacion f) async {
    try {
      if (!f.activo) {
        final res = await _client.from('grupofamiliar').select('id_grupof').not('user_id', 'is', null).count(CountOption.exact);
        return res.count;
      }
      var query = _client
          .from('grupofamiliar')
          .select('id_grupof, registro_v!inner(vigente, residencia!inner(cut_com))')
          .eq('registro_v.vigente', true)
          .not('user_id', 'is', null);
      query = _aplicarFiltroResidencia(query, 'registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarHogaresEstadoDeficiente(DashboardFiltroUbicacion f) async {
    try {
      if (!f.activo) {
        final res = await _client
            .from('registro_v')
            .select('id_registro')
            .eq('vigente', true)
            .inFilter('id_estado_v', [4, 5])
            .count(CountOption.exact);
        return res.count;
      }
      var query = _client
          .from('registro_v')
          .select('id_registro, residencia!inner(cut_com)')
          .eq('vigente', true)
          .inFilter('id_estado_v', [4, 5]);
      query = _aplicarFiltroResidencia(query, 'residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarBomberosAdministradores(DashboardFiltroUbicacion f) async {
    try {
      if (!f.activo) {
        final res = await _client.from('bombero').select('rut_num').eq('is_admin', true).count(CountOption.exact);
        return res.count;
      }
      var query = _client
          .from('bombero')
          .select('rut_num, companias_bomberos!inner(cut_com)')
          .eq('is_admin', true);
      query = _aplicarFiltroResidencia(query, 'companias_bomberos.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  // ── Analítica / desgloses ───────────────────────────────────────────

  Future<DashboardPerfilEtario> _perfilEtario(DashboardFiltroUbicacion f) async {
    try {
      List<dynamic> raw;
      if (!f.activo) {
        raw = await _client
            .from('integrante')
            .select('anio_nac')
            .isFilter('fecha_fin_i', null);
      } else {
        var query = _client
            .from('integrante')
            .select(
              'anio_nac, grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com)))',
            )
            .isFilter('fecha_fin_i', null)
            .eq('grupofamiliar.registro_v.vigente', true);
        query = _aplicarFiltroResidencia(query, 'grupofamiliar.registro_v.residencia.cut_com', f);
        raw = await query;
      }

      final anioActual = DateTime.now().year;
      var menores = 0;
      var adultos = 0;
      var mayores = 0;

      for (final row in raw) {
        final anio = _asInt(row['anio_nac']);
        if (anio == null) continue;
        final edad = anioActual - anio;
        if (edad < 18) {
          menores++;
        } else if (edad >= 65) {
          mayores++;
        } else {
          adultos++;
        }
      }

      return DashboardPerfilEtario(menores: menores, adultos: adultos, adultosMayores: mayores);
    } catch (_) {
      return DashboardPerfilEtario.empty;
    }
  }

  Future<List<DashboardDesglose>> _desgloseTiposVivienda(DashboardFiltroUbicacion f) async {
    try {
      var query = _client
          .from('registro_v')
          .select('id_tipo_v, tipo_vivienda(tipo_v), residencia(cut_com)')
          .eq('vigente', true);
      if (f.activo) {
        query = _client
            .from('registro_v')
            .select('id_tipo_v, tipo_vivienda(tipo_v), residencia!inner(cut_com)')
            .eq('vigente', true);
        query = _aplicarFiltroResidencia(query, 'residencia.cut_com', f);
      }
      final raw = await query;
      return _agruparPorEtiqueta(raw, (row) => _nestedString(row['tipo_vivienda'], 'tipo_v') ?? 'Sin tipo');
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardDesglose>> _desgloseEstadosVivienda(DashboardFiltroUbicacion f) async {
    try {
      var query = _client
          .from('registro_v')
          .select('id_estado_v, estado_vivienda(estado_v), residencia(cut_com)')
          .eq('vigente', true);
      if (f.activo) {
        query = _client
            .from('registro_v')
            .select('id_estado_v, estado_vivienda(estado_v), residencia!inner(cut_com)')
            .eq('vigente', true);
        query = _aplicarFiltroResidencia(query, 'residencia.cut_com', f);
      }
      final raw = await query;
      return _agruparPorEtiqueta(raw, (row) => _nestedString(row['estado_vivienda'], 'estado_v') ?? 'Sin estado');
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardDesglose>> _desgloseCategoriasCondicion(DashboardFiltroUbicacion f) async {
    try {
      List<dynamic> raw;
      if (!f.activo) {
        raw = await _client
            .from('condiciones_integ')
            .select('id_condicion, condiciones(tipo_condicion, categ_condiciones(categoria_c))');
      } else {
        var query = _client
            .from('condiciones_integ')
            .select(
              'id_condicion, condiciones(tipo_condicion, categ_condiciones(categoria_c)), '
              'integrante!inner(grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com))))',
            )
            .eq('integrante.grupofamiliar.registro_v.vigente', true);
        query = _aplicarFiltroResidencia(query, 'integrante.grupofamiliar.registro_v.residencia.cut_com', f);
        raw = await query;
      }

      return _agruparPorEtiqueta(raw, (row) {
        final cond = _nestedMap(row['condiciones']);
        final categ = cond != null ? _nestedMap(cond['categ_condiciones']) : null;
        return (categ?['categoria_c'] as String?)?.trim() ?? 'Sin categoría';
      });
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardDesglose>> _desgloseEspeciesMascota(DashboardFiltroUbicacion f) async {
    try {
      List<dynamic> raw;
      if (!f.activo) {
        raw = await _client.from('mascota').select('id_especie, tipo_especie(especie)');
      } else {
        var query = _client
            .from('mascota')
            .select(
              'id_especie, tipo_especie(especie), '
              'grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com)))',
            )
            .eq('grupofamiliar.registro_v.vigente', true);
        query = _aplicarFiltroResidencia(query, 'grupofamiliar.registro_v.residencia.cut_com', f);
        raw = await query;
      }
      return _agruparPorEtiqueta(raw, (row) => _nestedString(row['tipo_especie'], 'especie') ?? 'Sin especie');
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardDesglose>> _desgloseMaterialesPeligrosos(DashboardFiltroUbicacion f) async {
    try {
      List<dynamic> raw;
      if (!f.activo) {
        raw = await _client
            .from('mat_peligroso')
            .select('cantidad, id_mat_pelig, tipo_mat_peligroso(tipo_mat)');
      } else {
        var query = _client
            .from('mat_peligroso')
            .select(
              'cantidad, id_mat_pelig, tipo_mat_peligroso(tipo_mat), '
              'registro_v!inner(vigente, residencia!inner(cut_com))',
            )
            .eq('registro_v.vigente', true);
        query = _aplicarFiltroResidencia(query, 'registro_v.residencia.cut_com', f);
        raw = await query;
      }

      final mapa = <String, int>{};
      for (final row in raw) {
        final tipo = _nestedString(row['tipo_mat_peligroso'], 'tipo_mat') ?? 'Otro';
        final cant = _asInt(row['cantidad']) ?? 0;
        mapa[tipo] = (mapa[tipo] ?? 0) + cant;
      }
      return _mapaADesglose(mapa);
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardDesglose>> _desgloseMaterialesPiso(DashboardFiltroUbicacion f) async {
    try {
      List<dynamic> raw;
      if (!f.activo) {
        raw = await _client
            .from('piso_v')
            .select('id_mat_piso, tipo_mat_piso(material_piso), registro_v!inner(vigente)')
            .eq('registro_v.vigente', true);
      } else {
        var query = _client
            .from('piso_v')
            .select(
              'id_mat_piso, tipo_mat_piso(material_piso), '
              'registro_v!inner(vigente, residencia!inner(cut_com))',
            )
            .eq('registro_v.vigente', true);
        query = _aplicarFiltroResidencia(query, 'registro_v.residencia.cut_com', f);
        raw = await query;
      }
      return _agruparPorEtiqueta(
        raw,
        (row) => _nestedString(row['tipo_mat_piso'], 'material_piso') ?? 'Sin material',
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardDesglose>> _desgloseEstadosGrifo(DashboardFiltroUbicacion f) async {
    try {
      List<int> idsGrifos;
      if (!f.activo) {
        final raw = await _client.from('grifo').select('id_grifo');
        idsGrifos = raw.map((r) => _asInt(r['id_grifo'])).whereType<int>().toList();
      } else {
        var query = _client.from('grifo').select('id_grifo');
        query = _aplicarFiltroResidencia(query, 'cut_com', f);
        final raw = await query;
        idsGrifos = raw.map((r) => _asInt(r['id_grifo'])).whereType<int>().toList();
      }

      if (idsGrifos.isEmpty) return [];

      final ultimos = await Future.wait(idsGrifos.map(_ultimoEstadoGrifo));
      final mapa = <String, int>{};
      for (final estado in ultimos) {
        if (estado == null) continue;
        mapa[estado] = (mapa[estado] ?? 0) + 1;
      }

      final sinRegistro = idsGrifos.length - ultimos.whereType<String>().length;
      if (sinRegistro > 0) {
        mapa['Sin verificar'] = (mapa['Sin verificar'] ?? 0) + sinRegistro;
      }

      return _mapaADesglose(mapa);
    } catch (_) {
      return [];
    }
  }

  Future<String?> _ultimoEstadoGrifo(int idGrifo) async {
    try {
      final row = await _client
          .from('info_grifo')
          .select('estado_grifo(estado_g)')
          .eq('id_grifo', idGrifo)
          .order('fecha_registro', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
      return _nestedString(row['estado_grifo'], 'estado_g');
    } catch (_) {
      return null;
    }
  }

  List<DashboardDesglose> _agruparPorEtiqueta(
    List<dynamic> raw,
    String Function(Map<String, dynamic> row) etiquetaDe,
  ) {
    final mapa = <String, int>{};
    for (final item in raw) {
      if (item is! Map) continue;
      final etiqueta = etiquetaDe(Map<String, dynamic>.from(item));
      mapa[etiqueta] = (mapa[etiqueta] ?? 0) + 1;
    }
    return _mapaADesglose(mapa);
  }

  List<DashboardDesglose> _mapaADesglose(Map<String, int> mapa) {
    final items = mapa.entries
        .map((e) => DashboardDesglose(etiqueta: e.key, cantidad: e.value))
        .toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));
    return items;
  }

  // ── Conteos existentes ──────────────────────────────────────────────

  String _formatoFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> _contarIntegrantesActivos(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contarActivos('integrante', 'fecha_fin_i');
    try {
      var query = _client
          .from('integrante')
          .select(
            'id_integrante, grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com)))',
          )
          .isFilter('fecha_fin_i', null)
          .eq('grupofamiliar.registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'grupofamiliar.registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarIntegrantesEsteMes(DashboardFiltroUbicacion f, String desde, String hasta) async {
    if (!f.activo) return _contarEnRango('integrante', 'fecha_ini_i', desde, hasta);
    try {
      var query = _client
          .from('integrante')
          .select(
            'id_integrante, grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com)))',
          )
          .gte('fecha_ini_i', desde)
          .lte('fecha_ini_i', hasta)
          .eq('grupofamiliar.registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'grupofamiliar.registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarHogaresVigentes(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contar('registro_v', eq: {'vigente': true});
    try {
      var query = _client
          .from('registro_v')
          .select('id_registro, residencia!inner(cut_com)')
          .eq('vigente', true);
      query = _aplicarFiltroResidencia(query, 'residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarGruposEsteMes(DashboardFiltroUbicacion f, String desde, String hasta) async {
    if (!f.activo) return _contarEnRango('grupofamiliar', 'fecha_creacion', desde, hasta);
    try {
      var query = _client
          .from('grupofamiliar')
          .select('id_grupof, registro_v!inner(vigente, residencia!inner(cut_com))')
          .gte('fecha_creacion', desde)
          .lte('fecha_creacion', hasta)
          .eq('registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarBomberos(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contar('bombero');
    try {
      var query = _client.from('bombero').select('rut_num, companias_bomberos!inner(cut_com)');
      query = _aplicarFiltroResidencia(query, 'companias_bomberos.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarCompanias(DashboardFiltroUbicacion f) async {
    if (!f.activo) {
      try {
        final raw = await _client.from('bombero').select('id_compania');
        final ids = raw.map((r) => r['id_compania']).whereType<num>().map((n) => n.toInt()).toSet();
        return ids.length;
      } catch (_) {
        return 0;
      }
    }
    try {
      var query = _client.from('companias_bomberos').select('id_compania');
      query = _aplicarFiltroResidencia(query, 'cut_com', f);
      final raw = await query;
      return raw.map((r) => r['id_compania']).whereType<num>().map((n) => n.toInt()).toSet().length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarGrifos(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contar('grifo');
    try {
      var query = _client.from('grifo').select('id_grifo');
      query = _aplicarFiltroResidencia(query, 'cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarGrifosAtencion(DashboardFiltroUbicacion f) async {
    try {
      final estados = await _client.from('estado_grifo').select('id_estado_gr, estado_g');
      final idsAtencion = estados
          .where((e) {
            final estado = (e['estado_g'] as String? ?? '').toLowerCase();
            return estado.contains('dañado') ||
                estado.contains('danado') ||
                estado.contains('mantenimiento');
          })
          .map((e) => (e['id_estado_gr'] as num).toInt())
          .toList();
      if (idsAtencion.isEmpty) return 0;

      if (!f.activo) {
        final res = await _client
            .from('info_grifo')
            .select('id_grifo')
            .inFilter('id_estado_gr', idsAtencion)
            .count(CountOption.exact);
        return res.count;
      }

      var query = _client
          .from('info_grifo')
          .select('id_grifo, grifo!inner(cut_com)')
          .inFilter('id_estado_gr', idsAtencion);
      query = _aplicarFiltroResidencia(query, 'grifo.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarMascotas(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contar('mascota');
    try {
      var query = _client
          .from('mascota')
          .select('id_mascota, grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com)))')
          .eq('grupofamiliar.registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'grupofamiliar.registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _sumarMaterialesPeligrosos(DashboardFiltroUbicacion f) async {
    try {
      if (!f.activo) {
        final raw = await _client.from('mat_peligroso').select('cantidad');
        return _sumarCantidades(raw);
      }
      var query = _client
          .from('mat_peligroso')
          .select('cantidad, registro_v!inner(vigente, residencia!inner(cut_com))')
          .eq('registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'registro_v.residencia.cut_com', f);
      final raw = await query;
      return _sumarCantidades(raw);
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarCondicionesMedicas(DashboardFiltroUbicacion f) async {
    if (!f.activo) return _contar('condiciones_integ');
    try {
      var query = _client
          .from('condiciones_integ')
          .select(
            'id_integrante, integrante!inner(grupofamiliar!inner(registro_v!inner(vigente, residencia!inner(cut_com))))',
          )
          .eq('integrante.grupofamiliar.registro_v.vigente', true);
      query = _aplicarFiltroResidencia(query, 'integrante.grupofamiliar.registro_v.residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarRegistrosPorExpirar(DashboardFiltroUbicacion f) async {
    try {
      final limite = _formatoFecha(DateTime.now().add(const Duration(days: 30)));
      final hoy = _formatoFecha(DateTime.now());

      if (!f.activo) {
        final res = await _client
            .from('registro_v')
            .select('*')
            .eq('vigente', true)
            .gte('fecha_expiracion', hoy)
            .lte('fecha_expiracion', limite)
            .count(CountOption.exact);
        return res.count;
      }

      var query = _client
          .from('registro_v')
          .select('id_registro, residencia!inner(cut_com)')
          .eq('vigente', true)
          .gte('fecha_expiracion', hoy)
          .lte('fecha_expiracion', limite);
      query = _aplicarFiltroResidencia(query, 'residencia.cut_com', f);
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  dynamic _aplicarFiltroResidencia(dynamic query, String columna, DashboardFiltroUbicacion f) {
    if (f.cutCom != null) return query.eq(columna, f.cutCom!);
    if (f.cutComsRegion != null) return query.inFilter(columna, f.cutComsRegion!);
    return query;
  }

  int _sumarCantidades(List<dynamic> raw) {
    var total = 0;
    for (final row in raw) {
      final c = row['cantidad'];
      if (c is num) total += c.toInt();
    }
    return total;
  }

  Future<int> _contar(String tabla, {Map<String, dynamic>? eq}) async {
    try {
      var query = _client.from(tabla).select('*');
      if (eq != null) {
        for (final entry in eq.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      final res = await query.count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _contarActivos(String tabla, String columnaFin) async {
    try {
      final res = await _client.from(tabla).select('*').isFilter(columnaFin, null).count(CountOption.exact);
      return res.count;
    } catch (_) {
      return _contar(tabla);
    }
  }

  Future<int> _contarEnRango(String tabla, String columna, String desde, String hasta) async {
    try {
      final res = await _client
          .from(tabla)
          .select('*')
          .gte(columna, desde)
          .lte(columna, hasta)
          .count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String? _nestedString(dynamic parent, String key) {
    final m = parent is Map ? _nestedMap(parent) : null;
    if (m == null) return null;
    return (m[key] as String?)?.trim();
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}

extension on DashboardStats {
  DashboardStats copyWith({String? etiquetaUbicacion}) => DashboardStats(
        totalResidentes: totalResidentes,
        residentesEsteMes: residentesEsteMes,
        totalHogares: totalHogares,
        hogaresEsteMes: hogaresEsteMes,
        totalBomberos: totalBomberos,
        totalCompanias: totalCompanias,
        totalGrifos: totalGrifos,
        grifosRequierenAtencion: grifosRequierenAtencion,
        totalMascotas: totalMascotas,
        totalMaterialesPeligrosos: totalMaterialesPeligrosos,
        totalCondicionesMedicas: totalCondicionesMedicas,
        registrosPorExpirar: registrosPorExpirar,
        totalAlertas: totalAlertas,
        etiquetaUbicacion: etiquetaUbicacion ?? this.etiquetaUbicacion,
        totalGruposFamiliares: totalGruposFamiliares,
        gruposConCuenta: gruposConCuenta,
        hogaresEstadoDeficiente: hogaresEstadoDeficiente,
        bomberosAdministradores: bomberosAdministradores,
        perfilEtario: perfilEtario,
        tiposVivienda: tiposVivienda,
        estadosVivienda: estadosVivienda,
        categoriasCondicion: categoriasCondicion,
        especiesMascota: especiesMascota,
        materialesPeligrososPorTipo: materialesPeligrososPorTipo,
        materialesPiso: materialesPiso,
        estadosGrifo: estadosGrifo,
      );
}
