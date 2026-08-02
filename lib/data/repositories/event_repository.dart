import '../models/kai_event.dart';
import '../services/api_service.dart';

// The single source of truth for event data. View models ask it for events,
// and where events actually come from is its own private business.
//
// Today it is one line, and that looks like ceremony. The seam earns its keep
// the moment there is more than one source: REST now, Firebase push in Week
// Six, a cache for the bus ride. None of that reaches a screen.
class EventRepository {
  EventRepository({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<KaiEvent>> fetchEvents() => _api.fetchEvents();

  Future<KaiEvent> eatPortion(String eventId) => _api.eatPortion(eventId);

  Future<KaiEvent> fetchEventById(String eventId) => _api.fetchEventById(eventId);
}
