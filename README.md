# Lab 01: Extending Kai Finder

**COMPSCI 734 - Mobile, Web & Enterprise Computing. Week Two, Thursday.**

You're given the stopping point from Tuesday's lecture. You have Kai Finder v0.2: a feed of campus free-food events fetched over HTTP from the Kai Events server, a favourite star with one shared source of truth behind it, a detail screen with a URL of its own, a feed that can sort itself by how far away the food is, and the whole thing laid out in feature and data folders.

In today's lab, you will practice the concepts introduced in this week's lectures by extending this app further.

Tasks 1 through 3 are **core tasks**, with 4 and 5 being stretch goals (but still highly recommended practice in preparation for your team projects and the course test!). You're welcome to do the lab activities individually, or in pairs / teams - your choice.

## Task 0: pre-flight

### 1. Start your own Kai Events server

Every one of you runs your own copy. It is a single-file Express server with no database.

```sh
git clone https://github.com/UOA-CS734-S2-2026/example_02_kai_server.git
cd example_02_kai_server
npm install
npm start
```

It listens on port **3734**. Check it in a browser or with curl:

```sh
curl localhost:3734/events
```

Six events come back. Every 15 seconds each one loses a random 0 to 2 portions, and the server logs every tick, so leave that terminal where you can see it. You can call the `/reset` endpoint to put all the food back (or just restart the server).

The endpoints you will need today:

| Method | Path              | What it does                                          |
| ------ | ----------------- | ----------------------------------------------------- |
| GET    | `/events`         | The whole list, with about 300ms of artificial latency |
| GET    | `/events/:id`     | One event, or a 404                                   |
| POST   | `/events/:id/eat` | Someone took one. Returns the updated event            |
| POST   | `/reset`          | Puts all the food back                                |

Each event looks like this:

```json
{
  "id": "free-samosas",
  "name": "Free samosas",
  "location": "City Campus quad",
  "emoji": "🥟",
  "portionsLeft": 25,
  "isActive": true,
  "lat": -36.8517,
  "lng": 174.7687
}
```

### 2. Run this app

Use the following terminal commands, or the "Run" or "Debug" options in VS Code:

```sh
flutter pub get
flutter run
```

### 3. Check your base URL

`lib/data/services/api_service.dart` has one line that decides where the app looks for the server:

```dart
static const _base = 'http://10.0.2.2:3734';
```

`10.0.2.2` is the **Android emulator's** name for your own machine. The emulator cannot see `localhost`, because to it, `localhost` is the emulated phone. If you are running anywhere else, change that one line:

| Target                         | Base URL                |
| ------------------------------ | ----------------------- |
| Android emulator               | `http://10.0.2.2:3734`  |
| Chrome, macOS, Windows, Linux  | `http://localhost:3734` |
| iOS simulator                  | `http://localhost:3734` |
| A real phone on the same Wi-Fi | `http://<your-ip>:3734` |

### 4. Break it on purpose

Stop the server with Ctrl+C. Pull the feed down to refresh. You should get the error view and a Try again button. Start the server again, tap Try again, and the feed comes back.

**Checkpoint:** six events on screen, portion counts falling each time you pull to refresh, a card that opens a detail screen with a working back button, and a working error state when the server is gone. You have written no code yet. That is the point: you have inherited an app that already handles loading, error and data, and everything you add today has to keep doing the same.

## What you are starting with

Review these files before starting to code yourself. The folder shape is the one from the end of Tuesday's lecture: features own screens, `data/` owns everything about where information comes from.

| File                                            | What lives there                                                                            |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `lib/main.dart`                                 | `main()`, the app widget, and `createRouter()`: the go_router route table                     |
| `lib/data/models/kai_event.dart`                | The `KaiEvent` model, including `lat`/`lng`, and its `fromJson` factory                       |
| `lib/data/services/api_service.dart`            | Everything that knows what HTTP is. Its `http.Client` is injectable, so tests can fake it     |
| `lib/data/repositories/event_repository.dart`   | The seam between the view model and the service. One line today, and the place new sources go |
| `lib/features/feed/events_view_model.dart`      | A `ChangeNotifier` holding `isLoading`, `error`, `events`, the favourites, and the distances  |
| `lib/features/feed/kai_home_page.dart`          | The feed screen: app bar, the three states, `KaiEventCard`, `FavouriteButton`                 |
| `lib/features/event_detail/event_detail_screen.dart` | The detail screen at `/event/:id`, which looks its event up in the view model            |
| `test/widget_test.dart`                         | Eight tests that never touch the network                                                     |

Run `flutter analyze` and `flutter test` now, so you know they are green before you change anything. Keep running them as you go.

**Where new code goes.** A new widget for the feed belongs in `lib/features/feed/`. A new screen gets its own folder under `lib/features/`. Anything that talks to the server goes in `lib/data/services/` and is reached through the repository. Following the shape you inherited is part of the exercise: it is exactly the discipline your project team will need in week one.

## Task 1: a stateless widget, `PortionsPill`

**About 10 minutes.**

Right now each card says `Engineering courtyard  -  40 left` as one flat string. Replace the count with a small coloured pill that tells you at a glance whether it is worth walking over there.

**Build:** a new `StatelessWidget` called `PortionsPill` in its own file under `lib/features/feed/`, taking a `KaiEvent` and rendering a rounded, coloured badge:

| Portions left    | Reads as            |
| ---------------- | ------------------- |
| More than 10     | Plenty (green)      |
| 3 to 10          | Going fast (amber)  |
| Fewer than 3     | Almost gone (red)   |
| `isActive` false | Gone (grey)         |

Then use it in `KaiEventCard` instead of the `... left` text.

**Hints:** a `Container` with `decoration: BoxDecoration(color: ..., borderRadius: BorderRadius.circular(...))` and some `padding` makes a good-looking pill. Keep the colour decision in a small private helper or a getter so the `build` method stays readable. The widget must be a pure function of its input: no `setState`, no fields it changes, nothing remembered between builds. Everything it needs is already in the `KaiEvent` it was handed.

**Checkpoint:** pull to refresh a few times and watch pills change colour on their own as the server eats through the food. An event that hits zero goes grey.

**Think about:** you did not write a single line of state management for this, and the pill still keeps up with live data. Why? What is actually rebuilding it?

## Task 2: a stateful widget and a POST, the "I ate one" button

**About 15 minutes.**

Add an **Eat** button to every card. Tapping it tells the server that a portion has gone, and the count on screen updates to whatever the server says it now is.

**Build, in four pieces:**

1. **In `ApiService`:** a method that POSTs to `/events/:id/eat`. The server replies with the updated event as JSON, so parse it with the `fromJson` factory you already have and return a `KaiEvent`. Check the status code, the same way `fetchEvents` does.
2. **In `EventRepository`:** pass it through. One line, like `fetchEvents`. Nothing above this layer should learn that HTTP exists.
3. **In `EventsViewModel`:** a method that calls the repository, replaces that one event in the `events` list with the one that came back, and calls `notifyListeners()`.
4. **A new `StatefulWidget`, `EatButton`:** it holds a single `bool` of its own, something like `_isEating`. While the request is in flight, the button is disabled and shows a small spinner. When the future completes, it is enabled again. If the request fails, tell the user (a `SnackBar` is fine) and leave the count alone.

**Hints:** `_isEating` is exactly the kind of state that belongs in a widget. Nothing else in the app cares whether *this* button is mid-request, which is the test for `setState` versus the view model. Remember `async`/`await` inside a `try`/`catch`/`finally`, and check `mounted` before calling `setState` after an `await`. An event with nothing left should not be eatable.

**Checkpoint:** tap Eat and three things happen. The pill count drops by one, your server terminal logs `eat: ...`, and hammering the button does not fire two requests, because the second tap lands on a disabled button.

**Think about:**

- Your view model updates one event from the POST response. The lazier option is to call `load()` again and refetch everything. Try it, and watch what happens to the screen. Which would you ship?
- **Optimistic UI:** a real app often decrements the number the instant you tap, before the server has answered, so the app feels immediate. What does it then have to do when the request fails? What does that cost you in code?
- What should happen if two people eat the last samosa at the same time?

## Task 3: make the detail screen stand on its own

**About 15 minutes.**

You already have a detail screen, and it cheats. Open `lib/features/event_detail/event_detail_screen.dart` and look at how it gets its event:

```dart
final event = context.watch<EventsViewModel>().byId(id);
```

It digs the event out of the feed's list. That works perfectly right up until somebody arrives here from a notification or a shared link, with no feed ever loaded and nothing to dig through. A screen with an address of its own has to be able to build itself from that address alone.

**Build:**

1. **In `ApiService`:** `fetchEvent(String id)`, hitting `GET /events/:id`. Same shape as `fetchEvents`, one object instead of a list. Pass it through `EventRepository` as well.
2. **Turn `EventDetailScreen` into a `StatefulWidget`** that owns its own `isLoading`, `error` and `event`, kicks the fetch off in `initState`, and handles all three states itself: spinner, error with a retry button, or the event.
3. **Reuse what you have built:** the live `PortionsPill` and the `EatButton` from Task 2 both belong on this screen. That should be close to zero new work. If it is not, look at why.
4. **Make the deep link real:** give `createRouter()` an `initialLocation` parameter, and pass it down from the app widget.

**Hints:** the id already arrives as `state.pathParameters['id']`, and the route table already exists, so you are changing how the screen loads rather than how it is reached. Not everything has to go in the view model: this screen's fetch belongs to this screen. Note that the `EatButton` on this screen needs the updated event back so the screen can redraw, while the feed's copy does not, because the feed watches the view model.

**Checkpoint:** the deep-link one. Point the router at `/event/free-samosas` as its initial location, hot restart, and the app opens **straight onto the samosas**, with a back button that lands you on the feed, and it fetches its own data to get there. That is the whole argument from the lecture made real: a notification about pizza can open the pizza, because the screen has an address and can act on it alone.

**Think about:** what would break if the id in the URL does not exist? Try `/event/nope` and make the app do something sensible.

## Task 4: may I ask? The whole permission tree (homework)

**About 15 minutes.** Start it today if you get here, finish it before Monday.

Tuesday's demo took the happy path: press `near_me`, allow, get distances. Real permission handling is a state machine, and the branches you did not see are where the work is. Your job is the rest of the tree, on the **detail screen**, showing "About 320 m from you".

**Build:**

1. On the detail screen, work out the distance with `Geolocator.getCurrentPosition()` and `Geolocator.distanceBetween(...)`, which returns metres. The model already carries `lat` and `lng`.
2. **Handle every branch, not just the happy one.** This is the actual exercise:

   - Is location even switched on? `Geolocator.isLocationServiceEnabled()`
   - What are we allowed to do? `Geolocator.checkPermission()`
   - Not asked yet? `Geolocator.requestPermission()`
   - **Denied:** no distance, but leave a way back in. A "Show distance" button that asks again is enough.
   - **Denied forever:** the OS will never show your dialog again. Say so in plain words and offer `Geolocator.openAppSettings()`.
   - **Granted:** show the distance.

3. Then go back to `EventsViewModel.sortByDistance()`, which currently gives up silently on a refusal, and decide honestly whether it should.

The Android permission is already declared for you in `android/app/src/main/AndroidManifest.xml`, because the lecture demo needed it. **On iOS you still have to do it yourself:** `ios/Runner/Info.plist` has the key commented out, and while it is commented out the dialog will never appear.

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Kai Finder uses your location to show how far away the free food is.</string>
```

**Moving the emulator around.** The Android emulator is parked in California by default, so everything on campus will be about 10,000 km away until you move it. Open the three-dots menu next to the emulator, choose **Location**, type a latitude and longitude, and hit **Set location**. Campus is roughly `-36.8523, 174.7691`. From a terminal it is:

```sh
adb emu geo fix 174.7691 -36.8523
```

Longitude first. Yes, that is the opposite order from everywhere else. Set it while the app is running, and expect the very first request to be slow or to come back empty: nothing has asked Android for a location yet, so there is no fix to hand you. Once one has landed, every later request is instant.

The first time you allow location, Google Play services may put up its own **"For a better experience, your device will need to use Location Accuracy"** dialog on top of yours. Tap **Turn on**. That one is not yours and not a bug.

**Checkpoint:** it behaves correctly in all the outcomes. Deny once and the affordance to ask again is there. Deny forever (or deny twice on Android) and you get an explanation plus a route to Settings, not a dead screen. Grant it and the distance is plausible for wherever you put the emulator.

**Think about:** you have just made the permission *mechanics* work. Whether it is reasonable to ask at that exact moment is a different question, and it is Monday's lecture.

## Task 5: stretch, the map (take-home)

This is the piece of the Kai Finder vision we have been describing since Week One, and it is genuinely an afternoon's work.

```sh
flutter pub add flutter_map latlong2
```

Add a map screen: OpenStreetMap tiles centred on campus, one marker per **active** event using the coordinates the server sends, and tapping a marker navigates to that event's detail screen, reusing the route you already have. Add it to the router as its own path so you can deep link to it too, and give it a home under `lib/features/`.

**Hints:** `FlutterMap` takes `MapOptions` (an `initialCenter` as a `LatLng` and an `initialZoom`) and a list of layers: a `TileLayer` for the map itself and a `MarkerLayer` for your pins. Set `userAgentPackageName` on the tile layer, because the OpenStreetMap tile servers ask you to identify yourself. Events with nothing left should not be pins you can walk to.

**Two things that will happen to you, and neither is your fault:**

1. **The Android build breaks the moment you add `flutter_map`**, with `Could not find method kotlin()` pointing at a file inside `~/.pub-cache`. `flutter_map` depends on `path_provider`, whose Android implementation now uses the `jni` package, whose Gradle script does not get on with Android Gradle Plugin 9. Nothing in your code is wrong. Pin that one transitive package by adding this to `pubspec.yaml`, at the top level, next to `dependencies:`, and run `flutter pub get`:

   ```yaml
   dependency_overrides:
     path_provider_android: 2.2.23
   ```

   Reading a stack trace, working out that the failure is in somebody else's package, and pinning around it is a genuine part of the job. This is what it looks like.

2. **A warning about OpenStreetMap tile usage** appears in your console on first run. That is expected. Read it: those tile servers run on donations, and it is worth knowing whose infrastructure your free map is using.

No API key. No billing account. No credit card. Compare that with what `google_maps_flutter` would have wanted from you before it drew a single tile, and you have the build-versus-buy argument from Tuesday in your hands.

## Where to look things up

- go_router: https://pub.dev/packages/go_router
- geolocator: https://pub.dev/packages/geolocator
- flutter_map: https://docs.fleaflet.dev
- The Flutter widget catalogue: https://docs.flutter.dev/ui/widgets
- Tuesday's demo repo, tags `step-01-baseline` to `step-13-layers`: https://github.com/UOA-CS734-S2-2026/example_03_kai_finder_v02

## Getting stuck is fine, staying stuck is not

Ask. That is what the session is for.

A model solution lives on the **`solution`** branch of this repository, one commit per task, so you can compare your answer with another one or pick up a task you did not get to:

```sh
git log --oneline solution
```

Read it after you have had a real go at the task, not before. The point of this lab is the twenty minutes where it does not work.
