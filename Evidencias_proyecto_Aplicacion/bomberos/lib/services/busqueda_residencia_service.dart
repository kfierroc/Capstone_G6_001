import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/residencia_busqueda.dart';
import '../utils/busqueda_direccion.dart';
import '../utils/chile_format.dart';
import '../utils/supabase_parse.dart';

class BusquedaResidenciaException implements Exception {
  BusquedaResidenciaException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Búsqueda de residencias con [registro_v] vigente y no expirado.
class BusquedaResidenciaService {
  BusquedaResidenciaService(this._client);

  final SupabaseClient _client;

  static String _fechaHoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseFecha(dynamic v) {
    if (v is String) return DateTime.parse(v.split('T').first);
    return DateTime.now();
  }

  /// Si [cutCom] es null, búsqueda libre sin filtrar por comuna.
  Future<List<ResidenciaBusquedaResultado>> buscarActivas({
    required String termino,
    int? cutCom,
  }) async {
    final parsed = parsearTerminoDireccion(termino);
    final hoy = _fechaHoy();

    if (parsed.original.trim().isEmpty) {
      throw BusquedaResidenciaException('Ingresa una dirección para buscar.');
    }

    if (parsed.calle == null && parsed.numero == null) {
      throw BusquedaResidenciaException('Ingresa una calle o número de domicilio válido.');
    }

    try {
      var query = _client
          .from('registro_v')
          .select(
            'id_registro, id_residencia, unidad, desc_depto_cond, fecha_ult_confirm, id_grupof, '
            'residencia(id_residencia, calle, nro_direccion, cut_com)',
          )
          .eq('vigente', true)
          .gte('fecha_expiracion', hoy);

      if (parsed.soloNumero) {
        query = query.eq('residencia.nro_direccion', parsed.numero!);
      } else if (parsed.calleYNumero) {
        query = query
            .filter('residencia.calle', 'ilike', '%${escaparIlike(parsed.calle!)}%')
            .eq('residencia.nro_direccion', parsed.numero!);
      } else {
        final calle = parsed.calle!;
        final palabras = palabrasClaveCalle(calle);
        final terminoCalle = palabras.isNotEmpty ? palabras.first : calle;
        query = query.filter('residencia.calle', 'ilike', '%${escaparIlike(terminoCalle)}%');
      }

      if (cutCom != null) {
        query = query.eq('residencia.cut_com', cutCom);
      }

      final raw = await query.order('fecha_ult_confirm', ascending: false).limit(50);
      var filas = List<Map<String, dynamic>>.from(raw as List);

      // Si el número está almacenado como texto, reintentar con eq en string.
      if (filas.isEmpty && parsed.numero != null && (parsed.soloNumero || parsed.calleYNumero)) {
        filas = await _consultarPorNumeroTexto(parsed, cutCom, hoy);
      }

      // Refinar en cliente: número, palabras adicionales y coincidencias parciales.
      filas = _refinarFilas(filas, parsed);

      if (filas.isEmpty && parsed.calleYNumero) {
        // Reintento: calle sin filtrar número en servidor (nro puede venir como texto).
        var queryRelajada = _client
            .from('registro_v')
            .select(
              'id_registro, id_residencia, unidad, desc_depto_cond, fecha_ult_confirm, id_grupof, '
              'residencia(id_residencia, calle, nro_direccion, cut_com)',
            )
            .eq('vigente', true)
            .gte('fecha_expiracion', hoy)
            .filter('residencia.calle', 'ilike', '%${escaparIlike(parsed.calle!)}%');

        if (cutCom != null) {
          queryRelajada = queryRelajada.eq('residencia.cut_com', cutCom);
        }

        final raw2 = await queryRelajada.order('fecha_ult_confirm', ascending: false).limit(50);
        filas = _refinarFilas(List<Map<String, dynamic>>.from(raw2 as List), parsed);
      }

      if (filas.isEmpty) return [];

      final cuts = <int>{};
      for (final rv in filas) {
        final res = SupabaseParse.asMap(rv['residencia']);
        final cut = SupabaseParse.asInt(res?['cut_com']);
        if (cut != null) cuts.add(cut);
      }

      final comunasPorCut = await _mapaComunas(cuts);
      final grupos = filas
          .map((r) => SupabaseParse.asInt(r['id_grupof']))
          .whereType<int>()
          .toSet()
          .toList();
      final personasPorGrupo = await _conteoIntegrantes(grupos);
      final mascotasPorGrupo = await _conteoMascotas(grupos);

      final resultados = <ResidenciaBusquedaResultado>[];
      for (final rv in filas) {
        final res = SupabaseParse.asMap(rv['residencia']);
        if (res == null) continue;

        final idReg = SupabaseParse.asInt(rv['id_registro']);
        final idRes = SupabaseParse.asInt(rv['id_residencia']) ?? SupabaseParse.asInt(res['id_residencia']);
        final idGf = SupabaseParse.asInt(rv['id_grupof']);
        final cut = SupabaseParse.asInt(res['cut_com']);
        final calle = SupabaseParse.asString(res['calle']);
        final nroRaw = res['nro_direccion'];
        if (idReg == null || idRes == null || idGf == null || cut == null || calle == null) {
          continue;
        }
        if (cutCom != null && cut != cutCom) continue;

        final nroMostrar = ChileFormat.nroDireccionMostrar(nroRaw);
        final comuna = comunasPorCut[cut] ?? 'Comuna $cut';
        final unidad = SupabaseParse.asString(rv['unidad']);
        final descDepto = SupabaseParse.asString(rv['desc_depto_cond']);

        resultados.add(
          ResidenciaBusquedaResultado(
            idRegistro: idReg,
            idResidencia: idRes,
            idGrupof: idGf,
            direccionCompleta: _formatearDireccion(
              calle: calle,
              nroMostrar: nroMostrar,
              unidad: unidad,
              descDepto: descDepto,
              comuna: comuna,
            ),
            cantidadPersonas: personasPorGrupo[idGf] ?? 0,
            cantidadMascotas: mascotasPorGrupo[idGf] ?? 0,
            fechaUltimaActualizacion: _parseFecha(rv['fecha_ult_confirm']),
          ),
        );
      }
      return resultados;
    } on FormatException catch (e) {
      throw BusquedaResidenciaException(e.message);
    } on PostgrestException {
      throw BusquedaResidenciaException(
        'No se pudo completar la búsqueda. Verifica la dirección e intenta de nuevo.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _consultarPorNumeroTexto(
    TerminoDireccionBusqueda parsed,
    int? cutCom,
    String hoy,
  ) async {
    var query = _client
        .from('registro_v')
        .select(
          'id_registro, id_residencia, unidad, desc_depto_cond, fecha_ult_confirm, id_grupof, '
          'residencia(id_residencia, calle, nro_direccion, cut_com)',
        )
        .eq('vigente', true)
        .gte('fecha_expiracion', hoy)
        .eq('residencia.nro_direccion', parsed.numero.toString());

    if (parsed.calle != null && parsed.calle!.isNotEmpty) {
      query = query.filter('residencia.calle', 'ilike', '%${escaparIlike(parsed.calle!)}%');
    }
    if (cutCom != null) {
      query = query.eq('residencia.cut_com', cutCom);
    }

    final raw = await query.order('fecha_ult_confirm', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(raw as List);
  }

  static List<Map<String, dynamic>> _refinarFilas(
    List<Map<String, dynamic>> filas,
    TerminoDireccionBusqueda parsed,
  ) {
    if (filas.isEmpty) return filas;

    final palabras = parsed.calle != null ? palabrasClaveCalle(parsed.calle!) : <String>[];

    return filas.where((rv) {
      final res = SupabaseParse.asMap(rv['residencia']);
      if (res == null) return false;

      final calle = (SupabaseParse.asString(res['calle']) ?? '').toLowerCase();
      final nro = ChileFormat.parseNroDireccion(res['nro_direccion']);
      final nroTexto = res['nro_direccion']?.toString() ?? '';

      if (parsed.numero != null) {
        final coincideNumero = nro == parsed.numero || nroTexto.contains(parsed.numero.toString());
        if (!coincideNumero) return false;
      }

      if (palabras.isNotEmpty) {
        final coincideCalle = palabras.every((p) => calle.contains(p.toLowerCase()));
        if (!coincideCalle) return false;
      }

      return true;
    }).toList();
  }

  Future<Map<int, String>> _mapaComunas(Set<int> cuts) async {
    if (cuts.isEmpty) return {};
    final raw = await _client.from('comunas').select('cut_com, comuna').inFilter('cut_com', cuts.toList());
    final map = <int, String>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final cut = SupabaseParse.asInt(row['cut_com']);
      final nombre = SupabaseParse.asString(row['comuna']);
      if (cut != null && nombre != null) map[cut] = nombre;
    }
    return map;
  }

  Future<Map<int, int>> _conteoIntegrantes(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client
        .from('integrante')
        .select('id_grupof')
        .inFilter('id_grupof', idGrupos)
        .isFilter('fecha_fin_i', null);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_grupof']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<int, int>> _conteoMascotas(List<int> idGrupos) async {
    if (idGrupos.isEmpty) return {};
    final raw = await _client.from('mascota').select('id_grupof').inFilter('id_grupof', idGrupos);
    final map = <int, int>{};
    for (final row in List<Map<String, dynamic>>.from(raw as List)) {
      final id = SupabaseParse.asInt(row['id_grupof']);
      if (id == null) continue;
      map[id] = (map[id] ?? 0) + 1;
    }
    return map;
  }

  static String _formatearDireccion({
    required String calle,
    required String nroMostrar,
    String? unidad,
    String? descDepto,
    required String comuna,
  }) {
    final partes = <String>['$calle $nroMostrar'];
    if (unidad != null && unidad.isNotEmpty) {
      partes.add(unidad);
    } else if (descDepto != null && descDepto.isNotEmpty) {
      partes.add(descDepto);
    }
    partes.addAll([comuna, 'Santiago']);
    return partes.join(', ');
  }
}
