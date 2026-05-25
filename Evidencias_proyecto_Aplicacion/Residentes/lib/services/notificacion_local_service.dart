import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones locales del dispositivo (Android / iOS). En web solo in-app.
class NotificacionLocalService {
  NotificacionLocalService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static const _canalId = 'recordatorio_permanencia';
  static const _canalNombre = 'Confirmación de domicilio';

  static Future<void> inicializar() async {
    if (kIsWeb || _inicializado) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Santiago'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _canalId,
            _canalNombre,
            description: 'Recordatorios mensuales para confirmar datos del domicilio',
            importance: Importance.high,
          ),
        );

    _inicializado = true;
  }

  static Future<void> solicitarPermisoAndroid() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> programarMensual({
    required int idRegistro,
    required DateTime cuando,
    required int mesesTranscurridos,
  }) async {
    if (kIsWeb || !_inicializado) return;

    await cancelar(idRegistro);

    var programada = DateTime(cuando.year, cuando.month, cuando.day, 10, 0);
    final ahora = DateTime.now();
    if (!programada.isAfter(ahora)) {
      programada = ahora.add(const Duration(days: 1));
    }

    final loc = tz.local;
    final tzFecha = tz.TZDateTime(
      loc,
      programada.year,
      programada.month,
      programada.day,
      programada.hour,
      programada.minute,
    );

    final mesTxt = mesesTranscurridos == 1 ? '1 mes' : '$mesesTranscurridos meses';
    await _plugin.zonedSchedule(
      idRegistro,
      'Confirmación de domicilio',
      'Han pasado $mesTxt en tu residencia. ¿Tu información sigue siendo correcta? Abre la app para confirmar.',
      tzFecha,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNombre,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelar(int idRegistro) async {
    if (kIsWeb) return;
    await _plugin.cancel(idRegistro);
  }
}
