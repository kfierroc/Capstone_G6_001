// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, uri_does_not_exist

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'google_places_models.dart';

Future<List<PlaceAutocompletePrediction>> googlePlacesAutocomplete(String input) async {
  if (input.trim().length < 3) return [];
  try {
    return await _googlePlacesAutocompleteImpl(input);
  } catch (_) {
    return [];
  }
}

Future<List<PlaceAutocompletePrediction>> _googlePlacesAutocompleteImpl(String input) async {
  await _ensurePlacesLoaded();
  final places = _placesNs();
  final autocompleteCtor = js_util.getProperty(places, 'AutocompleteService');
  final service = js_util.callConstructor(autocompleteCtor as Object, <Object>[]);
  final request = js_util.jsify({
    'input': input.trim(),
    'componentRestrictions': {'country': 'cl'},
  });

  final completer = Completer<List<PlaceAutocompletePrediction>>();
  void jsCallback(Object? predictions, Object status) {
    final st = status.toString();
    if (st != 'OK' && st != 'ZERO_RESULTS') {
      if (!completer.isCompleted) completer.complete([]);
      return;
    }
    if (predictions == null) {
      if (!completer.isCompleted) completer.complete([]);
      return;
    }
    final dartified = js_util.dartify(predictions);
    List<dynamic> listRaw = const [];
    try {
      listRaw = List<dynamic>.from(dartified as Iterable);
    } catch (_) {}
    final out = <PlaceAutocompletePrediction>[];
    for (final item in listRaw) {
      final m = Map<String, dynamic>.from(item as Map);
      final pid = m['place_id'] as String?;
      final desc = m['description'] as String?;
      if (pid == null || desc == null) continue;
      out.add(PlaceAutocompletePrediction(placeId: pid, description: desc));
    }
    if (!completer.isCompleted) completer.complete(out);
  }

  js_util.callMethod(service, 'getPlacePredictions', [
    request,
    js_util.allowInterop(jsCallback),
  ]);

  return completer.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => <PlaceAutocompletePrediction>[],
  );
}


Future<PlaceDetailsResult> googlePlacesPlaceDetails(String placeId) async {
  await _ensurePlacesLoaded();
  final div = html.DivElement();
  final places = _placesNs();
  final placesServiceCtor = js_util.getProperty(places, 'PlacesService');
  final ps = js_util.callConstructor(placesServiceCtor as Object, [div]);
  final request = js_util.jsify({
    'placeId': placeId,
    'fields': ['geometry', 'address_component', 'formatted_address'],
  });

  final completer = Completer<PlaceDetailsResult>();
  void jsCallback(Object? result, Object status) {
    final st = status.toString();
    if (st != 'OK') {
      if (!completer.isCompleted) {
        completer.completeError(GooglePlacesException('Place Details: $st'));
      }
      return;
    }
    if (result == null) {
      if (!completer.isCompleted) {
        completer.completeError(GooglePlacesException('Place Details sin resultado'));
      }
      return;
    }
    try {
      final parsed = _parsePlaceResultJs(result);
      if (!completer.isCompleted) completer.complete(parsed);
    } catch (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    }
  }

  js_util.callMethod(ps, 'getDetails', [
    request,
    js_util.allowInterop(jsCallback),
  ]);

  return completer.future.timeout(
    const Duration(seconds: 25),
    onTimeout: () => throw GooglePlacesException('Tiempo agotado al obtener el lugar'),
  );
}

Object _placesNs() {
  final google = js_util.getProperty(js_util.globalThis, 'google');
  final maps = js_util.getProperty(google as Object, 'maps');
  return js_util.getProperty(maps as Object, 'places') as Object;
}

Future<void> _ensurePlacesLoaded() async {
  for (var i = 0; i < 80; i++) {
    try {
      final g = js_util.getProperty(js_util.globalThis, 'google');
      if (g != null) {
        final maps = js_util.getProperty(g as Object, 'maps');
        final places = js_util.getProperty(maps as Object, 'places');
        if (places != null) return;
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

PlaceDetailsResult _parsePlaceResultJs(Object result) {
  final geometry = js_util.getProperty(result, 'geometry');
  if (geometry == null) {
    throw const FormatException('Sin geometry');
  }
  final location = js_util.getProperty(geometry as Object, 'location');
  if (location == null) {
    throw const FormatException('Sin location');
  }
  final latNum = js_util.callMethod(location as Object, 'lat', []);
  final lngNum = js_util.callMethod(location, 'lng', []);
  final lat = (latNum as num).toDouble();
  final lng = (lngNum as num).toDouble();

  String? route;
  String? streetNumber;
  final comps = js_util.getProperty(result, 'address_components');
  if (comps != null) {
    final dartified = js_util.dartify(comps);
    if (dartified is List) {
      for (final c in dartified) {
        final m = Map<String, dynamic>.from(c as Map);
        final types = (m['types'] as List<dynamic>?)?.cast<String>() ?? [];
        if (types.contains('route')) {
          route = m['long_name'] as String?;
        }
        if (types.contains('street_number')) {
          streetNumber = m['long_name'] as String?;
        }
      }
    }
  }

  final calle = route?.trim();
  final nro = PlaceDetailsResult.parseNroCalle(streetNumber);
  final formatted = js_util.getProperty(result, 'formatted_address') as String?;
  final ok = calle != null &&
      calle.isNotEmpty &&
      nro != null &&
      nro > 0 &&
      calle.length <= 150;

  return PlaceDetailsResult(
    lat: lat,
    lng: lng,
    calle: calle,
    nroDireccion: nro,
    formattedAddress: formatted,
    tieneFormatoCalleNumero: ok,
  );
}

