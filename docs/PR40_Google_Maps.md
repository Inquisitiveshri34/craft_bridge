# PR40 – Google Maps — Artisan Location on ProductDetailScreen

**Project:** CraftBridge
**PR Number:** 40 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Integrate `google_maps_flutter` into `ProductDetailScreen` — display a static map with an artisan location marker using hardcoded coordinates as a stub for the artisan location field.

---

## Section 2 – Assignments Covered

- Assignment 3.40 — Google Maps — Artisan Location on ProductDetailScreen

---

## Section 3 – Objective

This PR adds a Google Maps widget to `ProductDetailScreen` showing the artisan's approximate location — giving buyers geographic context about where a product was made. Because `UserModel` does not have a `latitude`/`longitude` field (the model is locked), this PR uses hardcoded stub coordinates per artisan name as a demonstration. The real buyer location and distance calculation are added in PR41. The map is non-interactive — a static view centered on the artisan's location with a single marker — implemented using `google_maps_flutter`.

---

## Section 4 – Architecture Context

```
ProductDetailScreen
  └── _buildMapSection()          ← new method this PR
        └── GoogleMap widget
              ├── initialCameraPosition: artisan stub coords
              ├── markers: {artisan location marker}
              ├── zoomControlsEnabled: false
              ├── myLocationButtonEnabled: false
              └── height: 200

pubspec.yaml:
  google_maps_flutter: ^2.9.0   ← added this PR

Platform configuration (manual — agent handles where possible):
  android/app/src/main/AndroidManifest.xml
    → <meta-data android:name="com.google.android.geo.API_KEY"
                 android:value="YOUR_API_KEY"/>

Stub artisan coordinates (hardcoded for MVP):
  'Meera Devi'    → LatLng(26.9124, 75.7873)  // Jaipur
  'Ravi Kumar'    → LatLng(12.9716, 77.5946)  // Bengaluru
  'Pradeep Nair'  → LatLng(8.5241, 76.9366)   // Thiruvananthapuram
  'Sunita Sharma' → LatLng(28.6139, 77.2090)  // Delhi
  default         → LatLng(20.5937, 78.9629)  // India centre

Files modified this PR:
  pubspec.yaml
  lib/screens/buyer/product_detail_screen.dart
  android/app/src/main/AndroidManifest.xml
```

This PR sits after Firestore security rules (PR39) and before user location (PR41). PR41 adds `geolocator` and buyer distance calculation building on the map widget added here.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `pubspec.yaml` — add `google_maps_flutter`
- `lib/screens/buyer/product_detail_screen.dart`
- `android/app/src/main/AndroidManifest.xml` — add Maps API key meta-data

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

Add `google_maps_flutter: ^2.9.0` under the `dependencies:` section, after `firebase_messaging: ^15.1.3`.

After editing, run:
```
flutter pub get
```

---

### `android/app/src/main/AndroidManifest.xml`

Add the following `<meta-data>` tag inside the `<application>` element, before the `<activity>` tag:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**Note:** `YOUR_GOOGLE_MAPS_API_KEY` is a placeholder. In a real deployment, this would be replaced with an actual Google Maps API key obtained from the Google Cloud Console. For the MVP emulator demo, the Maps widget will render with a "This page can't load Google Maps correctly" overlay if no valid key is provided — the map tiles will not load but the widget structure and marker will be correct. The placeholder value is committed intentionally — for a production release, the key would be injected via CI/CD environment variables or a secrets manager.

---

### `lib/screens/buyer/product_detail_screen.dart`

Three targeted changes to the PR32 implementation.

---

**Change 1 — Add import:**

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
```

---

**Change 2 — Add `_getArtisanLocation()` private method to `_ProductDetailScreenState`:**

```dart
LatLng _getArtisanLocation() {
  switch (widget.product.artisanName) {
    case 'Meera Devi':
      return const LatLng(26.9124, 75.7873); // Jaipur
    case 'Ravi Kumar':
      return const LatLng(12.9716, 77.5946); // Bengaluru
    case 'Pradeep Nair':
      return const LatLng(8.5241, 76.9366); // Thiruvananthapuram
    case 'Sunita Sharma':
      return const LatLng(28.6139, 77.2090); // Delhi
    default:
      return const LatLng(20.5937, 78.9629); // India centre
  }
}
```

---

**Change 3 — Add `_buildMapSection()` method:**

Add after `_buildQuantitySelector()`:

```dart
Widget _buildMapSection() {
  final LatLng artisanLocation = _getArtisanLocation();
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
      Text(
        'Made by ${widget.product.artisanName}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.6),
            ),
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
            markers: {
              Marker(
                markerId: const MarkerId('artisan-location'),
                position: artisanLocation,
                infoWindow: InfoWindow(
                  title: widget.product.artisanName,
                  snippet: widget.product.category,
                ),
              ),
            },
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

**`GoogleMap` configuration notes:**

- `liteModeEnabled: true` — renders a static bitmap snapshot of the map instead of a full interactive map. This is Android-only — on iOS it falls back to the standard map. Lite mode is appropriate for non-interactive location display and uses less memory.
- All gesture flags disabled (`scrollGesturesEnabled: false`, etc.) — the map is informational only, not interactive.
- `zoomControlsEnabled: false` and `myLocationButtonEnabled: false` — removes the default Google Maps UI chrome.
- `myLocationEnabled: false` — does not attempt to access device location in this PR (location is added in PR41).
- `zoom: 11` — city-level zoom, appropriate for showing the artisan's general area.
- `ClipRRect` with `borderRadius: BorderRadius.circular(12)` — rounds the map corners to match the card aesthetic from `AppTheme`.

---

**Change 4 — Add `_buildMapSection()` call to `build()`:**

In the `build()` method's inner `Column` children list (inside the `Padding` widget), add `_buildMapSection()` after the `_buildQuantitySelector()` call and before the `const SizedBox(height: 16)` that precedes the `CustomButton`.

The updated inner `Column` children order in the `Padding` block:

```
1.  Row (title + price)
2.  SizedBox(height: 8)
3.  Row (store icon + artisan name)
4.  SizedBox(height: 4)
5.  Container (category chip)
6.  Divider(height: 32)
7.  Text('About this product')
8.  SizedBox(height: 8)
9.  Text(description)
10. SizedBox(height: 16)
11. Row (stock indicator)
12. Divider(height: 32)
13. _buildQuantitySelector()
14. _buildMapSection()          ← added this PR
15. SizedBox(height: 16)
16. CustomButton('Add to Cart')
17. SizedBox(height: 32)
```

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `pubspec.yaml` | `google_maps_flutter: ^2.9.0` added |
| 2 | `lib/screens/buyer/product_detail_screen.dart` | `_getArtisanLocation()`, `_buildMapSection()` with `GoogleMap` widget added; map section inserted between quantity selector and add-to-cart button |
| 3 | `android/app/src/main/AndroidManifest.xml` | Maps API key `<meta-data>` added inside `<application>` |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must modify three files.

---

**Step 1: Update `pubspec.yaml`**

Add `google_maps_flutter: ^2.9.0` to `dependencies:` after `firebase_messaging: ^15.1.3`. Run:
```
flutter pub get
```

---

**Step 2: Update `android/app/src/main/AndroidManifest.xml`**

Open the file and locate the `<application` element. Add the `<meta-data>` tag as the first child of `<application>`, before any `<activity>` tag:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

Do not modify any other element in the file.

---

**File: `lib/screens/buyer/product_detail_screen.dart`**

Make four targeted changes to the PR32 implementation:

**Change 1:** Add `import 'package:google_maps_flutter/google_maps_flutter.dart';` to the import block.

**Change 2:** Add `_getArtisanLocation()` method to `_ProductDetailScreenState` after `_buildImageFallback()`.

**Change 3:** Add `_buildMapSection()` method after `_buildQuantitySelector()`, exactly as specified in Section 6.

**Change 4:** In `build()`, locate the `_buildQuantitySelector()` call in the inner `Column` children. Add `_buildMapSection()` immediately after it (item 14 in the column), before the `const SizedBox(height: 16)` that precedes `CustomButton`.

**Critical rules:**
- `liteModeEnabled: true` must be set — this prevents the full interactive map from loading unnecessarily.
- All gesture flags must be `false` — the map is display-only.
- `myLocationEnabled: false` — do not request device location in this PR.
- The `Marker` must use `MarkerId('artisan-location')` as a `const`.
- `ClipRRect` wraps the `SizedBox` containing `GoogleMap` — not the other way round.
- `_buildMapSection()` returns a `Column` starting with `const Divider(height: 32)` — this provides the visual separator above the map section.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter pub get`**
   ```
   flutter pub get
   ```
   Confirm `google_maps_flutter` resolves without errors.

2. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `MarkerId` requires `const`; `GoogleMap` properties — `liteModeEnabled` is Android-only but the parameter exists on both platforms; `Set<Marker>` — `markers:` parameter requires a `Set`, use `{ Marker(...) }`.

3. **Verify `google_maps_flutter` in `pubspec.yaml`**
   ```
   grep 'google_maps_flutter' pubspec.yaml
   ```
   Must return one line.

4. **Verify API key in `AndroidManifest.xml`**
   ```
   grep 'geo.API_KEY' android/app/src/main/AndroidManifest.xml
   ```
   Must return one line — the `<meta-data>` tag.

5. **Verify `_getArtisanLocation` exists**
   ```
   grep '_getArtisanLocation' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least two lines — definition and call in `_buildMapSection`.

6. **Verify `GoogleMap` widget is present**
   ```
   grep 'GoogleMap(' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least one line.

7. **Verify `liteModeEnabled: true`**
   ```
   grep 'liteModeEnabled' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line.

8. **Verify all gestures disabled**
   ```
   grep 'GesturesEnabled: false\|zoomControlsEnabled: false' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least five lines — one per gesture flag.

9. **Verify `_buildMapSection` is called in `build`**
   ```
   grep '_buildMapSection' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return at least two lines — definition and call.

10. **Hot reload on emulator — map display test**
    ```
    flutter run
    ```
    Log in as a buyer → browse products → tap any product card.
    Confirm:
    - `ProductDetailScreen` loads with all existing sections.
    - Below the quantity selector: "Artisan Location" section heading, "Made by [artisan name]" subtitle.
    - A 200px-tall rounded map widget renders.
    - On Android emulator without a valid API key: map renders with "Google Maps Platform" watermark and/or "This page can't load Google Maps correctly" message — this is expected. The map widget structure is correct.
    - On Android emulator WITH a valid API key: map shows Jaipur/Bengaluru/Delhi area tiles (depending on artisan) with a red marker.
    - Map is non-interactive — scrolling the map does not pan it.
    - "Add to Cart" button still visible below the map section.
    - Back button returns to `BuyerHomeScreen` with Hero animation.

    **Artisan-specific coordinate test:**
    - Find a product by "Meera Devi" → map centers on Jaipur area.
    - Find a product by "Ravi Kumar" → map centers on Bengaluru area.
    - Find a product by an artisan not in the switch → map centers on India centre.

    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `pubspec.yaml`, `pubspec.lock`, `lib/screens/buyer/product_detail_screen.dart`, `android/app/src/main/AndroidManifest.xml`.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 40
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
git commit -m "PR40: Google Maps — Artisan Location on ProductDetailScreen"
git push origin pr40-google-maps
```

---

## Section 9 – Acceptance Criteria

- [ ] `pubspec.yaml` contains `google_maps_flutter: ^2.9.0`.
- [ ] `android/app/src/main/AndroidManifest.xml` contains the `com.google.android.geo.API_KEY` `<meta-data>` tag inside `<application>`.
- [ ] `ProductDetailScreen` imports `google_maps_flutter`.
- [ ] `_getArtisanLocation()` returns a `LatLng` based on `widget.product.artisanName` with a default fallback to India centre.
- [ ] `_buildMapSection()` returns a `Column` with a divider, "Artisan Location" heading, artisan name subtitle, and a `ClipRRect`-wrapped 200px `GoogleMap`.
- [ ] `GoogleMap` has `liteModeEnabled: true`, all gesture flags `false`, `zoomControlsEnabled: false`, `myLocationEnabled: false`.
- [ ] `GoogleMap` `markers` set contains one `Marker` at the artisan's stub location with `InfoWindow` showing artisan name and category.
- [ ] `_buildMapSection()` is called in `build()` after `_buildQuantitySelector()` and before the "Add to Cart" `CustomButton`.
- [ ] Map section renders on the emulator without crashing (even without a valid API key).
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR40 for CraftBridge. I integrated `google_maps_flutter` into `ProductDetailScreen` — adding an artisan location map that shows buyers where each product was made, using hardcoded stub coordinates for the demo and setting up the map infrastructure that PR41 builds on."

2. **`google_maps_flutter` package:** "`google_maps_flutter` is Google's official Flutter plugin for the Maps SDK. It wraps the native Android and iOS Maps SDKs in a Flutter widget. The `GoogleMap` widget renders in a platform view — a native Android or iOS view embedded in the Flutter widget tree. This gives map rendering performance comparable to a native app."

3. **`liteModeEnabled: true`:** "Lite mode renders the map as a static bitmap snapshot rather than a full interactive map. For a non-interactive location display, lite mode is significantly more efficient — it uses less memory and CPU and doesn't maintain a live map session. The tradeoff is that the map doesn't respond to gestures, which is exactly what we want here. `liteModeEnabled` is Android-only — iOS doesn't have an equivalent, so it silently falls back to a standard non-interactive map."

4. **Stub coordinates design:** "`_getArtisanLocation()` uses a switch on `widget.product.artisanName` to return hardcoded coordinates for the demo personas from PR05 — Meera Devi in Jaipur, Ravi Kumar in Bengaluru, etc. The default case returns India's geographic centre. This works for the demo because the stub product data uses these exact artisan names. In a production app, artisan location would be stored in Firestore (PR41 explores this with buyer location) and read from `ProductModel`."

5. **`UserModel` lock and workaround:** "`UserModel` is locked after PR07 — adding `latitude` and `longitude` fields would require modifying a locked file. The stub coordinates are the MVP workaround. A post-MVP enhancement would add a `GeoPoint` field to `UserModel` (requiring the model to be unlocked), stored when the artisan sets up their shop, and fetched as part of the product or user data."

6. **Map UI configuration:** "All gesture flags are disabled — `scrollGesturesEnabled`, `zoomGesturesEnabled`, `rotateGesturesEnabled`, `tiltGesturesEnabled` all `false`. This prevents the map from capturing scroll events that should scroll the `ProductDetailScreen`'s `SingleChildScrollView`. A user scrolling the product detail page would otherwise accidentally interact with the map."

7. **`InfoWindow` on the marker:** "The `Marker` has an `InfoWindow` with `title: widget.product.artisanName` and `snippet: widget.product.category`. On a full interactive map, tapping the marker would show this info window. In lite mode on Android, tapping the marker is not interactive — but the `InfoWindow` data is still defined for when the map is used in a non-lite context."

8. **API key placeholder:** "The `AndroidManifest.xml` change adds a `<meta-data>` tag with `YOUR_GOOGLE_MAPS_API_KEY` as a placeholder. Without a valid key, the map renders with a 'can't load Google Maps' overlay — the widget structure and marker are correct, but no map tiles load. For a real deployment, the key would be obtained from Google Cloud Console → Maps SDK for Android, and ideally injected via CI/CD rather than committed to the repository."

9. **`ClipRRect` for rounded corners:** "The `GoogleMap` widget is wrapped in `ClipRRect(borderRadius: BorderRadius.circular(12))` — this clips the map to have rounded corners matching the card aesthetic from `AppTheme.cardTheme`. Without `ClipRRect`, the map would have sharp corners that look out of place in the warm rounded design of the app."

10. **What's Next:** "PR41 will add the `geolocator` package to get the buyer's current device location and display the distance from the buyer to the artisan on `ProductDetailScreen`, building on the map infrastructure established in this PR."