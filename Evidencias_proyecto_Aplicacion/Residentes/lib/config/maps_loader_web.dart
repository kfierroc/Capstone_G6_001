// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

/// Inyecta la API JavaScript de Google Maps y espera a que termine de cargar.
/// Así el widget [GoogleMap] en web no intenta usar `google.maps` antes de tiempo.
Future<void> loadGoogleMapsScript(String apiKey) async {
  if (apiKey.isEmpty) return;

  const id = 'gmaps-js-api';
  if (html.document.getElementById(id) != null) {
    return;
  }

  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..id = id
    ..async = true
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&loading=async';

  script.onLoad.listen((_) {
    if (!completer.isCompleted) completer.complete();
  });
  script.onError.listen((html.Event event) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('No se pudo cargar el script de Google Maps (revisa la API key y la consola del navegador).'),
      );
    }
  });

  html.document.head!.append(script);

  await completer.future.timeout(
    const Duration(seconds: 45),
    onTimeout: () => throw TimeoutException(
      'Tiempo de espera agotado al cargar Google Maps JS.',
      const Duration(seconds: 45),
    ),
  );
}
