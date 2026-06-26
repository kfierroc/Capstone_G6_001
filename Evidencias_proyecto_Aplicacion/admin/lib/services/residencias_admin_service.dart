import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/grupo_familiar_detalle.dart';
import '../models/residencia_admin_detalle.dart';
import '../models/pagina_lista.dart';
import 'grupo_familiar_service.dart';

class ResidenciasAdminService {
  ResidenciasAdminService(this._client);

  final SupabaseClient _client;

  Future<List<ResidenciaListItem>> listarResidencias() async {
    final pag = await listarResidenciasPaginado(offset: 0, limit: 10000);
    return pag.items;
  }

  /// Página de residencias (máx. [limit], por defecto 20).
  Future<PaginaLista<ResidenciaListItem>> listarResidenciasPaginado({
    required int offset,
    int limit = kTamanoPaginaLista,
    int? cutCom,
    List<int>? cutComsRegion,
    int? idResidenciaExacto,
  }) async {
    if (cutComsRegion != null && cutComsRegion.isEmpty) {
      return const PaginaLista(items: [], hayMas: false);
    }

    try {
      final pedido = limit + 1;
      var query = _client.from('residencia').select(
            'id_residencia, calle, nro_direccion, cut_com, '
            'registro_v(id_registro, vigente, id_grupof, unidad)',
          );

      if (idResidenciaExacto != null) {
        query = query.eq('id_residencia', idResidenciaExacto);
      } else if (cutCom != null) {
        query = query.eq('cut_com', cutCom);
      } else if (cutComsRegion != null) {
        query = query.inFilter('cut_com', cutComsRegion);
      }

      final raw = await query.order('id_residencia').range(offset, offset + pedido - 1);
      final hayMas = raw.length > limit;
      final slice = hayMas ? raw.sublist(0, limit) : raw;

      final comunas = await _mapComunas(
        slice.map((r) => _asInt(r['cut_com'])).whereType<int>().toSet(),
      );

      final items = slice.map((row) => _mapListItem(row, comunas)).whereType<ResidenciaListItem>().toList();
      return PaginaLista(items: items, hayMas: hayMas);
    } catch (_) {
      return const PaginaLista(items: [], hayMas: false);
    }
  }

  ResidenciaListItem? _mapListItem(dynamic row, Map<int, String> comunas) {
    if (row is! Map) return null;
    final m = Map<String, dynamic>.from(row);

    final id = _asInt(m['id_residencia']);
    final calle = m['calle'] as String?;
    final nro = _asInt(m['nro_direccion']);
    if (id == null || calle == null || nro == null) return null;

    final cut = _asInt(m['cut_com']);
    final comuna = cut != null ? (comunas[cut] ?? 'Comuna $cut') : '—';

    final registroVigente = _registroVigenteMap(m['registro_v']);
    final direccion = _direccionCorta(calle, nro, registroVigente);
    final idGrupof = registroVigente != null ? _asInt(registroVigente['id_grupof']) : null;

    return ResidenciaListItem(
      idResidencia: id,
      direccion: direccion,
      comuna: comuna,
      registroVigente: registroVigente != null,
      tieneGrupoVinculado: idGrupof != null,
      cutCom: cut,
    );
  }

  Future<ResidenciaAdminDetalle?> obtenerDetalle(int idResidencia) async {
    try {
      final res = await _client
          .from('residencia')
          .select('id_residencia, calle, nro_direccion, lat, lon, cut_com')
          .eq('id_residencia', idResidencia)
          .maybeSingle();
      if (res == null) return null;

      final residencia = Map<String, dynamic>.from(res);
      final calle = (residencia['calle'] as String).trim();
      final nro = _asInt(residencia['nro_direccion'])!;
      final cut = _asInt(residencia['cut_com']);
      var comuna = '—';
      if (cut != null) {
        final row = await _client.from('comunas').select('comuna').eq('cut_com', cut).maybeSingle();
        comuna = (row?['comuna'] as String? ?? 'Comuna $cut').trim();
      }

      final lat = _asDouble(residencia['lat']);
      final lon = _asDouble(residencia['lon']);

      final registrosRaw = await _client
          .from('registro_v')
          .select(
            'id_registro, vigente, unidad, desc_depto_cond, notas_v, '
            'fecha_ini_r, fecha_ult_confirm, fecha_expiracion, id_tipo_v, id_estado_v, id_grupof',
          )
          .eq('id_residencia', idResidencia)
          .order('fecha_ini_r', ascending: false);

      final registroVigente = _registroVigenteFromList(registrosRaw);
      final registroRef = registroVigente ?? (registrosRaw.isNotEmpty ? Map<String, dynamic>.from(registrosRaw.first) : null);

      final gfService = GrupoFamiliarService(_client);
      GrupoFamiliarDetalle? grupoDetalle;
      DomicilioGrupoInfo domicilio = DomicilioGrupoInfo.sinRegistro;

      if (registroVigente != null) {
        final idGrupof = _asInt(registroVigente['id_grupof']);
        if (idGrupof != null) {
          grupoDetalle = await gfService.obtenerDetalle(idGrupof);
        }
        domicilio = await gfService.cargarDomicilioDesdeRegistro(registroVigente, residencia: residencia);
      } else if (registroRef != null) {
        domicilio = await gfService.cargarDomicilioDesdeRegistro(registroRef, residencia: residencia);
      } else {
        domicilio = DomicilioGrupoInfo(
          tieneRegistro: false,
          vigente: false,
          direccionCompleta: '$calle $nro, $comuna',
          comuna: comuna,
          tipoVivienda: '—',
          estadoVivienda: '—',
          fechaInicio: '—',
          fechaUltConfirm: '—',
          fechaExpiracion: '—',
          idResidencia: idResidencia,
          cutCom: cut,
          calle: calle,
          nroDireccion: nro,
          lat: lat,
          lon: lon,
        );
      }

      final direccionCorta = grupoDetalle?.direccion ?? '$calle $nro, $comuna';

      return ResidenciaAdminDetalle(
        idResidencia: idResidencia,
        calle: calle,
        nroDireccion: nro,
        cutCom: cut,
        direccionCorta: direccionCorta,
        comuna: comuna,
        lat: lat,
        lon: lon,
        grupoDetalle: grupoDetalle,
        domicilio: domicilio,
      );
    } catch (_) {
      return null;
    }
  }

  String _direccionCorta(String calle, int nro, Map<String, dynamic>? registroVigente) {
    final partes = <String>['$calle $nro'];
    if (registroVigente != null) {
      final unidad = registroVigente['unidad'] as String?;
      if (unidad != null && unidad.isNotEmpty) partes.add(unidad);
    }
    return partes.join(', ');
  }

  Map<String, dynamic>? _registroVigenteMap(dynamic registrosRaw) {
    for (final rv in _normalizarLista(registrosRaw)) {
      if (rv['vigente'] == true) return rv;
    }
    return null;
  }

  Map<String, dynamic>? _registroVigenteFromList(List<dynamic> registrosRaw) {
    for (final rv in registrosRaw) {
      if (rv is Map && rv['vigente'] == true) return Map<String, dynamic>.from(rv);
    }
    return null;
  }

  List<Map<String, dynamic>> _normalizarLista(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }
    if (raw is Map) return [Map<String, dynamic>.from(raw)];
    return [];
  }

  Future<Map<int, String>> _mapComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    try {
      final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
      return {
        for (final r in raw)
          if (_asInt(r['cut_com']) != null) _asInt(r['cut_com'])!: (r['comuna'] as String).trim(),
      };
    } catch (_) {
      return {};
    }
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  double? _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return null;
  }
}
