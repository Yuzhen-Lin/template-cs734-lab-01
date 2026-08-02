import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/kai_event.dart';
import '../feed/events_view_model.dart';
import '../feed/kai_home_page.dart';
import '../feed/portions_pill.dart';
import 'package:geolocator/geolocator.dart';

// A screen with an address of its own. The router hands it an id out of the
// URL and it looks the event up itself, instead of being passed one by the
// screen that opened it. That is what makes the URL enough to build a screen,
// and it is the whole reason a notification can land you here.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isLoading = true;
  String? _error;
  KaiEvent? _event;
  double? _distanceMetres;
  String? _locationError;
  bool _isCheckingLocation = false;
  bool _permissionPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final event = await context.read<EventsViewModel>().repo.fetchEventById(
        widget.id,
      );
      setState(() {
        this._event = event;
        _isLoading = false;
      });
      _checkLocation();
    } catch (e) {
      setState(() {
        _error = 'Could not reach the Kai server';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkLocation() async {
    if (_event == null) return;

    setState(() {
      _isCheckingLocation = true;
      _locationError = null;
      _permissionPermanentlyDenied = false;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled.';
          _isCheckingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permissions are denied.';
            _isCheckingLocation = false;
            _permissionPermanentlyDenied = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permissions are permanently denied. Please enable them in settings.';
          _isCheckingLocation = false;
          _permissionPermanentlyDenied = true;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _event!.lat,
        _event!.lng,
      );
      setState(() {
        _distanceMetres = distance;
        _locationError = null;
        _isCheckingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _isCheckingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              FilledButton(
                onPressed: _loadEvent,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(event.name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(event.emoji, style: const TextStyle(fontSize: 96)),
            const SizedBox(height: 24),
            Text(event.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(event.location),
            const SizedBox(height: 8),
            // Live from the server, same as the card. Pull to refresh the feed
            // and this number moves too: they read the same event object.
            PortionsPill(event: event),
            // The same widget as the feed, in its third home in the app. Star
            // it here, go back, and the card and the badge already know: all
            // three watch one source of truth, and none of them synchronise.
            const SizedBox(height: 8),

            if (_isCheckingLocation)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(child: Text(_locationError!)),
                    const SizedBox(width: 8),
                    if (_permissionPermanentlyDenied)
                      FilledButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Open Settings'),
                      )
                    else
                      FilledButton(
                        onPressed: _checkLocation,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ),
            if (_distanceMetres != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _distanceMetres! < 1000
                      ? 'Distance: ${_distanceMetres!.toStringAsFixed(0)} m'
                      : 'Distance: ${(_distanceMetres! / 1000).toStringAsFixed(2)} km',
                ),
              ),

            const SizedBox(height: 8),
            FavouriteButton(event: event),
          ],
        ),
      ),
    );
  }
}
