# PR41 – User Location — Buyer Location + Nearby Context

**Project:** CraftBridge
**PR Number:** 41 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Add `geolocator` package, request buyer device location permission, calculate and display distance from buyer to artisan on `ProductDetailScreen`.

---

## Section 2 – Assignments Covered

- Assignment 3.41 — User Location — Buyer Location + Nearby Context

---

## Section 3 – Objective

This PR adds buyer location context to `ProductDetailScreen` — requesting the device's GPS location, computing the straight-line distance to the artisan's stub coordinates from PR40, and displaying the distance below the map. If the buyer denies location permission or the device cannot provide a location, the distance display is gracefully hidden. The map camera position is also updated to show both the buyer and artisan locations when buyer location is available. This PR uses the `geolocator` package for cross-platform location access.

---

## Section 4 – Architecture Context

```
ProductDetailScreen (_ProductDetailScreenState)
  │
  ├── New fields (this PR):
  │     ├── Position? _buyerPosition
  │     └── bool _isLoadingLocation
  │
  ├── initState() → _fetchBuyerLocation()
  │
  ├── _fetchBuyerLocation()
  │     ├── Geolocator.checkPermission()
  │     ├── if denied → Geolocator.requestPermission()
  │     ├── if granted → Geolocator.getCurrentPosition()
  │     └── setState(_buyerPosition = position)
  │
  ├── _calculateDistance()
  │     └── Geolocator.distanceBetween(buyer, artisan)
  │           → metres → converted to km
  │
  └── _buildMapSection() (updated this PR)
        ├── if _buyerPosition != null → add buyer marker to map
        ├── distance chip below map
        └── CameraPosition still centered on artisan

pubspec.yaml:
  geolocator: ^13.0.1   ← added this PR

Platform permissions:
  android/app/src/main/AndroidManifest.xml
    → ACCESS_FINE_LOCATION
    → ACCESS_COARSE_LOCATION

  ios/Runner/Info.plist
    → NSLocationWhenInUseUsageDescription

Files modified this PR:
  pubspec.yaml
  lib/screens/buyer/product_detail_screen.dart
  android/app/src/main/AndroidManifest.xml
  ios/Runner/Info.plist
```

This PR sits after Google Maps (PR40) and before `CartProvider` + `CartScreen` (PR42). It builds directly on the `_buildMapSection()` and `_getArtisanLocation()` methods added in PR40.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `pubspec.yaml` — add `geolocator`
- `lib/screens/buyer/product_detail_screen.dart`
- `android/app/src/main/AndroidManifest.xml` — add location permissions
- `ios/Runner/Info.plist` — add location usage description

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new Dart files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any widget files.
- Do NOT modify any other screen files.

---

## Section 6 – Technical Requirements

---

### `pubspec.yaml`

Add `geolocator: ^13.0.1` under the `dependencies:` section, after `google_maps_flutter: ^2.9.0`.

---

### `android/app/src/main/AndroidManifest.xml`

Add the following two permission declarations inside the `<manifest>` element, before the `<application>` tag:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

---

### `ios/Runner/Info.plist`

Add the following key-value pair inside the `<dict>` element:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>CraftBridge uses your location to show how far you are from artisans.</string>
```

---

### `lib/screens/buyer/product_detail_screen.dart`

Five targeted changes to the PR40 implementation.

---

**Change 1 — Add import:**

```dart
import 'package:geolocator/geolocator.dart';
```

---

**Change 2 — Add new state fields to `_ProductDetailScreenState`:**

Add after `bool _isAddingToCart = false`:

```dart
Position? _buyerPosition;
bool _isLoadingLocation = false;
```

---

**Change 3 — Add `_fetchBuyerLocation()` method:**

```dart
Future<void> _fetchBuyerLocation() async {
  setState(() => _isLoadingLocation = true);
  try {
    LocationPermission permission =
        await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return;
    }
    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    setState(() {
      _buyerPosition = position;
      _isLoadingLocation = false;
    });
  } catch (e) {
    setState(() => _isLoadingLocation = false);
  }
}
```

**Implementation notes:**

- `LocationAccuracy.medium` — city-block level accuracy, sufficient for distance display and faster than `high` (GPS) accuracy.
- `LocationPermission.deniedForever` — the user has permanently denied location in system settings. In this case, `requestPermission()` would not show a dialog. The method returns silently — no error is surfaced to the user.
- The entire method is wrapped in try-catch — location services can throw on emulators or devices where GPS is unavailable.

---

**Change 4 — Add `_calculateDistance()` method:**

```dart
String _calculateDistance() {
  if (_buyerPosition == null) return '';
  final LatLng artisanLocation = _getArtisanLocation();
  final double distanceInMetres = Geolocator.distanceBetween(
    _buyerPosition!.latitude,
    _buyerPosition!.longitude,
    artisanLocation.latitude,
    artisanLocation.longitude,
  );
  final double distanceInKm = distanceInMetres / 1000;
  if (distanceInKm < 1) {
    return '${distanceInMetres.toStringAsFixed(0)} m away';
  }
  return '${distanceInKm.toStringAsFixed(1)} km away';
}
```

**Implementation notes:**

- `Geolocator.distanceBetween()` uses the Haversine formula to calculate straight-line distance between two `LatLng` points in metres.
- Distance under 1km is shown in metres. Distance over 1km is shown in kilometres with one decimal.
- Returns empty string when `_buyerPosition` is null — the caller checks for empty string before rendering.

---

**Change 5 — Update `initState()` to call `_fetchBuyerLocation()`:**

```dart
@override
void initState() {
  super.initState();
  _quantity = 1;
  _fetchBuyerLocation();
}
```

---

**Change 6 — Update `_buildMapSection()` to show buyer marker and distance:**

Replace the PR40 `_buildMapSection()` with:

```dart
Widget _buildMapSection() {
  final LatLng artisanLocation = _getArtisanLocation();
  final Set<Marker> markers = {
    Marker(
      markerId: const MarkerId('artisan-location'),
      position: artisanLocation,
      infoWindow: InfoWindow(
        title: widget.product.artisanName,
        snippet: widget.product.category,
      ),
    ),
  };
  if (_buyerPosition != null) {
    markers.add(
      Marker(
        markerId: const MarkerId('buyer-location'),
        position: LatLng(
          _buyerPosition!.latitude,
          _buyerPosition!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue,
        ),
        infoWindow: const InfoWindow(title: 'Your location'),
      ),
    );
  }
  final String distanceText = _calculateDistance();
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(height: 32),
      Text(
        'Artisan Location',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: Text(
              'Made by ${widget.product.artisanName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
          if (_isLoadingLocation)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (distanceText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distanceText,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color:
                              Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 200,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: artisanLocation,
              zoom: 11,
            ),
            markers: markers,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            liteModeEnabled: true,
          ),
        ),
      ),
    ],
  );
}
```

**Key changes from PR40:**

- `markers` is now a mutable `Set<Marker>` — a blue buyer-location marker is conditionally added when `_buyerPosition` is not null.
- The artisan name row becomes a `Row` with an `Expanded` text and either a loading spinner (while fetching location) or a distance chip (when location is available).
- The map widget itself is unchanged.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `pubspec.yaml` | `geolocator: ^13.0.1` added |
| 2 | `lib/screens/buyer/product_detail_screen.dart` | `_buyerPosition`, `_isLoadingLocation` fields; `_fetchBuyerLocation()`, `_calculateDistance()` methods; `initState()` updated; `_buildMapSection()` updated with buyer marker and distance chip |
| 3 | `android/app/src/main/AndroidManifest.xml` | `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions added |
| 4 | `ios/Runner/Info.plist` | `NSLocationWhenInUseUsageDescription` added |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify four files.

---

**Step 1: Update `pubspec.yaml`**

Add `geolocator: ^13.0.1` after `google_maps_flutter: ^2.9.0`. Run `flutter pub get`.

---

**Step 2: Update `android/app/src/main/AndroidManifest.xml`**

Add `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` `<uses-permission>` tags inside `<manifest>`, before `<application>`.

---

**Step 3: Update `ios/Runner/Info.plist`**

Add `NSLocationWhenInUseUsageDescription` key-value pair inside `<dict>`.

---

**File: `lib/screens/buyer/product_detail_screen.dart`**

Make six targeted changes:

1. Add `geolocator` import.
2. Add `_buyerPosition` and `_isLoadingLocation` fields.
3. Add `_fetchBuyerLocation()` method after `_handleAddToCart()`.
4. Add `_calculateDistance()` method after `_fetchBuyerLocation()`.
5. Update `initState()` to add `_fetchBuyerLocation()` call after `_quantity = 1`.
6. Replace `_buildMapSection()` with the updated version.

**Critical rules:**
- `_fetchBuyerLocation()` must be called in `initState()` — not inside `build()`. Calling it in `build()` would re-fetch location on every rebuild.
- `LocationPermission.deniedForever` must be handled — return silently without error.
- `Geolocator.distanceBetween()` is a static method — no instance needed.
- `BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)` for the buyer marker — distinguishes it from the default red artisan marker.
- The distance chip is only shown when `distanceText.isNotEmpty` — null-safe rendering.
- The loading spinner replaces the distance chip while `_isLoadingLocation` is true.
- PR40's `_getArtisanLocation()` and all existing `_buildMapSection()` infrastructure are preserved — only the marker set and subtitle row change.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter pub get`**
   ```
   flutter pub get
   ```
   Confirm `geolocator` resolves without errors.

2. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `LocationSettings` — new API in `geolocator` ^11+, replaces the old `desiredAccuracy` parameter; `Position` type from `geolocator`; `Geolocator.distanceBetween` is static.

3. **Verify `geolocator` in `pubspec.yaml`**
   ```
   grep 'geolocator' pubspec.yaml
   ```
   Must return one line.

4. **Verify location permissions in `AndroidManifest.xml`**
   ```
   grep 'LOCATION' android/app/src/main/AndroidManifest.xml
   ```
   Must return two lines — `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`.

5. **Verify `NSLocationWhenInUseUsageDescription` in `Info.plist`**
   ```
   grep 'NSLocationWhenInUseUsageDescription' ios/Runner/Info.plist
   ```
   Must return one line.

6. **Verify `_fetchBuyerLocation` is called in `initState`**
   ```
   grep '_fetchBuyerLocation' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least two lines — definition and call in `initState`.

7. **Verify `_calculateDistance` method exists**
   ```
   grep '_calculateDistance' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least two lines — definition and call in `_buildMapSection`.

8. **Verify buyer marker added to markers set**
   ```
   grep 'buyer-location' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line — the buyer `MarkerId`.

9. **Verify `LocationPermission.deniedForever` is handled**
   ```
   grep 'deniedForever' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line.

10. **Hot reload on emulator — location and distance test**
    ```
    flutter run
    ```
    Log in as a buyer → tap any product card.

    **Android emulator (location simulation):**
    - On the Android emulator, open Extended Controls (⋮ in the emulator toolbar) → Location → set a custom location (e.g. latitude 26.9, longitude 75.8 for Jaipur area).
    - Navigate to `ProductDetailScreen` for a "Meera Devi" product.
    - Confirm: a small loading spinner appears briefly in the map subtitle row.
    - After location resolves: a distance chip appears (e.g. "12.3 km away" or similar).
    - Blue marker appears on the map at the simulated buyer location.
    - Red marker remains at the artisan location.

    **Permission denial test:**
    - Reset app permissions in the emulator settings.
    - Open the app → navigate to `ProductDetailScreen` → when permission dialog appears, deny it.
    - Confirm: no crash, no distance chip shows, map still renders with only the artisan marker.

    **No location (emulator without GPS):**
    - Confirm app doesn't hang — `_isLoadingLocation` returns to `false`, distance chip not shown.

    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `pubspec.yaml`, `pubspec.lock`, `lib/screens/buyer/product_detail_screen.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 41
  Failed Check: [exact check that failed]
  Error Output: [exact error message or description]
  Root Cause: [agent's diagnosis]
  Suggested Fix: [exact steps the developer should take to resolve it]
  ```

**If all checks pass:**

Output:
```
VERIFICATION PASSED
All Section 9 acceptance criteria confirmed.
Proceeding to commit and push.
```

Then run:
```
git add .
git commit -m "PR41: User Location — Buyer Location + Nearby Context"
git push origin pr41-user-location
```

---

## Section 9 – Acceptance Criteria

- [ ] `pubspec.yaml` contains `geolocator: ^13.0.1`.
- [ ] `AndroidManifest.xml` contains both `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions.
- [ ] `ios/Runner/Info.plist` contains `NSLocationWhenInUseUsageDescription`.
- [ ] `_ProductDetailScreenState` declares `Position? _buyerPosition` and `bool _isLoadingLocation`.
- [ ] `initState()` calls `_fetchBuyerLocation()`.
- [ ] `_fetchBuyerLocation()` handles `LocationPermission.denied` (requests permission), `LocationPermission.deniedForever` (returns silently), and success (sets `_buyerPosition`).
- [ ] `_calculateDistance()` uses `Geolocator.distanceBetween()` and returns a human-readable distance string or empty string when position is null.
- [ ] `_buildMapSection()` adds a blue buyer marker when `_buyerPosition` is not null.
- [ ] Distance chip is shown when `distanceText.isNotEmpty`, loading spinner shown while `_isLoadingLocation` is true.
- [ ] Location permission denial does not crash the app — map renders normally with only the artisan marker.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR41 for CraftBridge. I added buyer location context to `ProductDetailScreen` — requesting device GPS permission, calculating the straight-line distance to the artisan using the Haversine formula, and displaying a distance chip next to the map subtitle with a blue buyer location marker on the map."

2. **`geolocator` package:** "`geolocator` is the standard Flutter package for cross-platform location access. It abstracts the Android `FusedLocationProviderClient` and iOS `CoreLocation` APIs into a unified Dart interface. `Geolocator.checkPermission()`, `requestPermission()`, `getCurrentPosition()`, and `distanceBetween()` are the four methods used in this PR."

3. **`_fetchBuyerLocation()` permission flow:** "The permission flow is: check current permission status → if denied, request → if still denied or deniedForever, return silently → if granted, get position. `LocationPermission.deniedForever` means the user has gone into system settings and permanently denied the app. In this case, `requestPermission()` won't show a dialog — we must return without error. The app continues without distance display."

4. **`LocationAccuracy.medium` choice:** "`LocationAccuracy.medium` gives city-block level accuracy — typically within 100 metres. For showing distance to an artisan's general area, this is more than sufficient. `LocationAccuracy.high` would use GPS and take longer to acquire a fix. `medium` uses cell towers and WiFi for a faster, battery-friendlier position."

5. **`Geolocator.distanceBetween()` Haversine formula:** "`Geolocator.distanceBetween(lat1, lon1, lat2, lon2)` calculates straight-line distance between two GPS coordinates using the Haversine formula — accounting for Earth's curvature. The result is in metres. Dividing by 1000 gives kilometres. The `_calculateDistance()` method formats under 1km as metres ('500 m away') and over 1km as one-decimal kilometres ('23.4 km away')."

6. **Blue buyer marker with `BitmapDescriptor.hueBlue`:** "The buyer marker uses `BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)` — a blue tinted version of the default red pin. This visually distinguishes 'where you are' (blue) from 'where the artisan is' (red), using the standard map convention. The artisan marker uses the default red pin with no `icon` parameter."

7. **`initState()` location fetch timing:** "`_fetchBuyerLocation()` is called in `initState()` — before the first build. This means the location request starts as soon as the detail screen opens. While location is being fetched, `_isLoadingLocation` is `true` and a small `CircularProgressIndicator` (14×14, `strokeWidth: 2`) shows in the map subtitle row. When location arrives, `setState` triggers a rebuild showing the distance chip."

8. **Distance chip design:** "The distance chip is a `Container` with primary-colour background at 10% opacity, a `near_me_outlined` icon at 12sp, and the distance text at `bodySmall` weight 600 in the primary colour. It's compact — placed inline in the map subtitle row alongside the artisan name. If location is unavailable, the chip simply doesn't render — `distanceText.isNotEmpty` guards it."

9. **`try-catch` in `_fetchBuyerLocation()`:** "Location operations can throw platform exceptions — on emulators without GPS enabled, on devices with location services disabled at the OS level, or when the `geolocator` plugin hasn't been configured correctly. The try-catch ensures none of these failures crash `ProductDetailScreen`. On any error, `_isLoadingLocation` is set to `false` and no distance is shown."

10. **What's Next:** "PR42 will implement `CartProvider` and fully wire `CartScreen` — replacing the single-item stub checkout with a multi-item cart backed by `CartProvider` local state, with quantity management and the full checkout flow."