// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

/// Inyecta la API JavaScript de Google Maps antes de usar [GoogleMap] en web.
Future<void> loadGoogleMapsScript(String apiKey) async {
  if (apiKey.isEmpty) return;

  const id = 'gmaps-js-api';
  if (html.document.getElementById(id) != null) return;

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = id
    ..async = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async';

  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(StateError('No se pudo cargar Google Maps JS.'));
    }
  });

  html.document.head!.append(script);

  await completer.future.timeout(
    const Duration(seconds: 45),
    onTimeout: () => throw TimeoutException('Tiempo agotado al cargar Google Maps.', const Duration(seconds: 45)),
  );
}
