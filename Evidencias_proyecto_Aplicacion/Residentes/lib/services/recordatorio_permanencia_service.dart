import 'package:supabase_flutter/supabase_flutter.dart';

import 'gestion_residente_service.dart';
import 'notificacion_local_service.dart';

/// Estado del recordatorio mensual de permanencia en la residencia.
class EstadoRecordatorioPermanencia {
  EstadoRecordatorioPermanencia({
    required this.idRegistro,
    required this.fechaUltConfirm,
    required this.fechaExpiracion,
    required this.mesesDesdeConfirmacion,
    required this.diasHastaExpiracion,
    required this.requiereConfirmacionMensual,
    required this.permanenciaVencida,
    required this.permanenciaPorVencer,
  });

  final int idRegistro;
  final DateTime fechaUltConfirm;
  final DateTime fechaExpiracion;
  /// Meses calendario completos desde [fechaUltConfirm].
  final int mesesDesdeConfirmacion;
  final int diasHastaExpiracion;
  final bool requiereConfirmacionMensual;
  final bool permanenciaVencida;
  final bool permanenciaPorVencer;

  bool get tieneAlerta =>
      requiereConfirmacionMensual || permanenciaVencida || permanenciaPorVencer;

  int get cantidadAlertas {
    var n = 0;
    if (requiereConfirmacionMensual) n++;
    if (permanenciaVencida || permanenciaPorVencer) n++;
    return n;
  }
}

/// Recordatorios mensuales hasta desvincular el domicilio.
class RecordatorioPermanenciaService {
  RecordatorioPermanenciaService(this._client);

  final SupabaseClient _client;

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _mesesCalendario(DateTime desde, DateTime hasta) {
    final a = _soloFecha(desde);
    final b = _soloFecha(hasta);
    var months = (b.year - a.year) * 12 + (b.month - a.month);
    if (b.day < a.day) months--;
    return months;
  }

  static DateTime _addCalendarMonths(DateTime d, int months) {
    final total = d.month - 1 + months;
    final y = d.year + total ~/ 12;
    final m = total % 12 + 1;
    final lastDay = DateTime(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime(y, m, day);
  }

  /// Evalúa si corresponde recordatorio (≥ 1 mes desde última confirmación).
  Future<EstadoRecordatorioPermanencia?> evaluar() async {
    final ges = GestionResidenteService(_client);
    final ctx = await ges.contextoResidente();
    if (ctx?.idRegistro == null) return null;

    final row = await _client
        .from('registro_v')
        .select('id_registro, fecha_ult_confirm, fecha_expiracion, vigente')
        .eq('id_registro', ctx!.idRegistro!)
        .maybeSingle();
    if (row == null || row['vigente'] != true) return null;

    final hoy = _soloFecha(DateTime.now());
    final ultima = _parseFecha(row['fecha_ult_confirm']);
    final expira = _parseFecha(row['fecha_expiracion']);
    final meses = _mesesCalendario(ultima, hoy);
    final diasRest = expira.difference(hoy).inDays;

    return EstadoRecordatorioPermanencia(
      idRegistro: (row['id_registro'] as num).toInt(),
      fechaUltConfirm: ultima,
      fechaExpiracion: expira,
      mesesDesdeConfirmacion: meses,
      diasHastaExpiracion: diasRest,
      requiereConfirmacionMensual: meses >= 1,
      permanenciaVencida: diasRest < 0,
      permanenciaPorVencer: diasRest >= 0 && diasRest <= 7,
    );
  }

  DateTime _parseFecha(dynamic v) {
    if (v is String) return _soloFecha(DateTime.parse(v.split('T').first));
    return _soloFecha(DateTime.now());
  }

  /// Confirma que la información sigue vigente; reinicia el ciclo mensual.
  Future<void> confirmarInformacionMensual(int idRegistro) async {
    final hoy = _soloFecha(DateTime.now());
    final iso =
        '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
    await _client.from('registro_v').update({'fecha_ult_confirm': iso}).eq('id_registro', idRegistro);
    await _sincronizarNotificacionProgramada(idRegistro, hoy);
  }

  /// Tras renovar permanencia o confirmar, programa el próximo aviso (+ 1 mes).
  Future<void> sincronizarTrasActualizarPermanencia(int idRegistro) async {
    final row = await _client
        .from('registro_v')
        .select('fecha_ult_confirm')
        .eq('id_registro', idRegistro)
        .maybeSingle();
    if (row == null) return;
    await _sincronizarNotificacionProgramada(idRegistro, _parseFecha(row['fecha_ult_confirm']));
  }

  Future<void> cancelarAlDesvincular(int idRegistro) async {
    await NotificacionLocalService.cancelar(idRegistro);
  }

  Future<void> _sincronizarNotificacionProgramada(int idRegistro, DateTime fechaUltConfirm) async {
    final proxima = _addCalendarMonths(_soloFecha(fechaUltConfirm), 1);
    final meses = _mesesCalendario(fechaUltConfirm, proxima);
    await NotificacionLocalService.programarMensual(
      idRegistro: idRegistro,
      cuando: proxima,
      mesesTranscurridos: meses < 1 ? 1 : meses,
    );
  }
}
