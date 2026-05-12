import 'google_places_backend_io.dart' if (dart.library.html) 'google_places_backend_web.dart' as backend;
import 'google_places_models.dart';

/// Facade para Autocomplete y Place Details (REST en IO, JS API en web).
class GooglePlacesService {
  Future<List<PlaceAutocompletePrediction>> autocomplete(String input) {
    return backend.googlePlacesAutocomplete(input);
  }

  Future<PlaceDetailsResult> placeDetails(String placeId) {
    return backend.googlePlacesPlaceDetails(placeId);
  }
}
