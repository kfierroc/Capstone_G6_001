import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_catalog_service.dart';

class ComunaUbicacionItem {
  const ComunaUbicacionItem({
    required this.cutCom,
    required this.nombre,
    required this.cutReg,
    required this.regionNombre,
  });

  final int cutCom;
  final String nombre;
  final int cutReg;
  final String regionNombre;
}

class UbicacionCatalogData {
  const UbicacionCatalogData({
    required this.regiones,
    required this.comunas,
  });

  final List<CatalogItem> regiones;
  final List<ComunaUbicacionItem> comunas;

  Map<int, int> get comunaARegion => {
        for (final c in comunas) c.cutCom: c.cutReg,
      };

  List<CatalogItem> comunasDropdown({int? cutReg}) {
    final lista = cutReg == null ? comunas : comunas.where((c) => c.cutReg == cutReg);
    return lista
        .map((c) => CatalogItem(id: c.cutCom, label: c.nombre))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }
}

class UbicacionCatalogService {
  UbicacionCatalogService(this._client);

  final SupabaseClient _client;

  Future<UbicacionCatalogData> cargar() async {
    final regiones = await AdminCatalogService(_client).regiones();
    final comunas = await _cargarComunas();
    return UbicacionCatalogData(regiones: regiones, comunas: comunas);
  }

  Future<List<ComunaUbicacionItem>> _cargarComunas() async {
    try {
      final raw = await _client
          .from('comunas')
          .select('cut_com, comuna, provincias(cut_reg, regiones(region))')
          .order('comuna');

      return raw.map(_mapComunaEmbed).whereType<ComunaUbicacionItem>().toList();
    } catch (_) {
      return _cargarComunasFallback();
    }
  }

  ComunaUbicacionItem? _mapComunaEmbed(dynamic row) {
    if (row is! Map) return null;
    final m = Map<String, dynamic>.from(row);
    final cutCom = _asInt(m['cut_com']);
    final nombre = (m['comuna'] as String?)?.trim();
    if (cutCom == null || nombre == null || nombre.isEmpty) return null;

    final prov = _nestedMap(m['provincias']);
    final cutReg = prov != null ? _asInt(prov['cut_reg']) : null;
    final regiones = prov != null ? _nestedMap(prov['regiones']) : null;
    final regionNombre = regiones != null ? (regiones['region'] as String?)?.trim() : null;

    if (cutReg == null) return null;
    return ComunaUbicacionItem(
      cutCom: cutCom,
      nombre: nombre,
      cutReg: cutReg,
      regionNombre: regionNombre ?? 'Región $cutReg',
    );
  }

  Future<List<ComunaUbicacionItem>> _cargarComunasFallback() async {
    try {
      final comunasRaw = await _client.from('comunas').select('cut_com, comuna, cut_prov').order('comuna');
      final provRaw = await _client.from('provincias').select('cut_prov, cut_reg');
      final regRaw = await _client.from('regiones').select('cut_reg, region');

      final provAReg = {
        for (final p in provRaw)
          (p['cut_prov'] as num).toInt(): (p['cut_reg'] as num).toInt(),
      };
      final regNombre = {
        for (final r in regRaw)
          (r['cut_reg'] as num).toInt(): (r['region'] as String).trim(),
      };

      return comunasRaw.map((row) {
        final cutCom = (row['cut_com'] as num).toInt();
        final cutProv = (row['cut_prov'] as num).toInt();
        final cutReg = provAReg[cutProv];
        if (cutReg == null) return null;
        return ComunaUbicacionItem(
          cutCom: cutCom,
          nombre: (row['comuna'] as String).trim(),
          cutReg: cutReg,
          regionNombre: regNombre[cutReg] ?? 'Región $cutReg',
        );
      }).whereType<ComunaUbicacionItem>().toList();
    } catch (_) {
      return [];
    }
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }
}
