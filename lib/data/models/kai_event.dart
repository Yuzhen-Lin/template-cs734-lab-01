// A tiny data class for one free-food event.
// Note for students: named parameters, required, and a const constructor.
class KaiEvent {
  const KaiEvent({
    required this.id,
    required this.name,
    required this.location,
    required this.emoji,
    required this.portionsLeft,
    required this.lat,
    required this.lng,
  });

  // A stable identity. Yesterday the widget remembered whether it was starred;
  // today the view model remembers, and it needs a name for each event.
  final String id;
  final String name;
  final String location;
  final String emoji;
  final int portionsLeft;

  // Where the food actually is. Nothing uses these yet: upgrade four does.
  final double lat;
  final double lng;

  bool get isActive => portionsLeft > 0;

  // jsonDecode hands back maps and lists. Convert into a real class
  // immediately, at the edge, so the rest of the app never sees a
  // Map<String, dynamic> and never guesses at a key name.
  factory KaiEvent.fromJson(Map<String, dynamic> json) => KaiEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    location: json['location'] as String,
    emoji: json['emoji'] as String,
    portionsLeft: json['portionsLeft'] as int,
    // JSON numbers arrive as int or double depending on what was written, so
    // read them as num and convert. -36.85 is a double, but a flat -36 is not.
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );
}

// The hard-coded kaiEvents list used to live here. The server is the source
// of the data now, so it is gone.
