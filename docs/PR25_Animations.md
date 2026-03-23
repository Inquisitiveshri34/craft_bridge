# PR25 – Animations — Product Card Transitions + Screen Transitions

**Project:** CraftBridge
**PR Number:** 25 of 51
**Assigned To:** Member 2
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Add `Hero` animations between `ProductCard` and `ProductDetailScreen`, `AnimatedOpacity` fade-in on `BuyerHomeScreen` content load, and `PageRouteBuilder` slide transition for `AddEditProductScreen` navigation.

---

## Section 2 – Assignments Covered

- Assignment 3.25 — Animations — Product Card Transitions + Screen Transitions

---

## Section 3 – Objective

This PR adds three categories of animation to CraftBridge: `Hero` animations that smoothly transition product images from the grid to the detail screen, `AnimatedOpacity` that fades in the product grid content after the screen mounts, and a custom `PageRouteBuilder` slide-up transition for navigating to `AddEditProductScreen`. These animations make the app feel polished and responsive without adding any new business logic. All animation work is additive — no existing widget trees are restructured.

---

## Section 4 – Architecture Context

```
Animation 1 — Hero transition:
  BuyerHomeScreen
    └── ProductCard
          └── Hero(tag: 'product-$productId')   ← already in PR22
                └── Image.file / fallback

  ProductDetailScreen
    └── Hero(tag: 'product-$productId')          ← added this PR
          └── product image widget

Animation 2 — AnimatedOpacity fade-in:
  BuyerHomeScreen (_BuyerHomeScreenState)
    └── _contentOpacity: double (0.0 → 1.0)
    └── initState() → Future.delayed(100ms) → setState(_contentOpacity = 1.0)
    └── AnimatedOpacity wraps the body Column content

Animation 3 — PageRouteBuilder slide-up:
  ManageProductsScreen
    └── FAB onPressed → _slideUpRoute(AddEditProductScreen())
          └── PageRouteBuilder with SlideTransition
                └── Tween<Offset>(begin: Offset(0, 1), end: Offset.zero)

Files modified this PR:
  lib/screens/buyer/buyer_home_screen.dart       ← AnimatedOpacity
  lib/screens/buyer/product_detail_screen.dart   ← Hero tag on image
  lib/screens/artisan/manage_products_screen.dart ← PageRouteBuilder FAB
```

This PR sits after Storage upload (PR24) and before `ProductProvider` (PR26). All three animations are UI-only additions — no Provider, no Firebase, no model changes.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/buyer/buyer_home_screen.dart`
- `lib/screens/buyer/product_detail_screen.dart`
- `lib/screens/artisan/manage_products_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/buyer/buyer_home_screen.dart`

Add `AnimatedOpacity` fade-in to the product grid content. Three targeted changes only.

---

**Change 1 — Add `_contentOpacity` field:**

Add to `_BuyerHomeScreenState` after `int _currentNavIndex = 0`:

```dart
double _contentOpacity = 0.0;
```

---

**Change 2 — Add `initState()` with opacity trigger:**

Add `initState()` override to `_BuyerHomeScreenState`:

```dart
@override
void initState() {
  super.initState();
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      setState(() => _contentOpacity = 1.0);
    }
  });
}
```

The 100ms delay ensures the first frame renders before the opacity animation begins — preventing a flash of transparent content on the first build.

---

**Change 3 — Wrap body `Column` in `AnimatedOpacity`:**

In `build()`, wrap the body `Column` (the one containing `_buildSearchBar()`, `_buildCategoryChips()`, and `Expanded(_buildProductGrid())`) in:

```dart
AnimatedOpacity(
  opacity: _contentOpacity,
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeIn,
  child: Column(
    children: [
      _buildSearchBar(),
      _buildCategoryChips(),
      Expanded(child: _buildProductGrid()),
    ],
  ),
)
```

The `body` of the `Scaffold` becomes `AnimatedOpacity(...)` directly, not a `Column` wrapping `AnimatedOpacity`.

---

### `lib/screens/buyer/product_detail_screen.dart`

Add a `Hero` widget wrapping the image area so it connects to the `Hero` in `ProductCard`.

The PR23 stub `ProductDetailScreen` has a `Padding` > `Column` body. Add a `Hero`-wrapped image placeholder as the first visual element above the title text.

---

**Updated `build()` method for `ProductDetailScreen`:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'product-$productId',
            child: Container(
              height: 280,
              width: double.infinity,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 72,
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'By $artisanName',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ProductDetailScreen — fully implemented in PR32/PR40/PR41/PR44',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.4),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Key change:** The `Hero` wraps a `Container` of height 280 with the image placeholder icon — this gives the `Hero` animation a visible surface to animate from card to detail screen. The `Hero` tag `'product-$productId'` matches exactly the tag in `ProductCard` from PR22.

---

### `lib/screens/artisan/manage_products_screen.dart`

Replace the FAB's `Navigator.push(MaterialPageRoute(...))` call with a custom `PageRouteBuilder` slide-up transition.

---

**Add `_slideUpRoute` private method to `_ManageProductsScreenState`:**

```dart
PageRouteBuilder<void> _slideUpRoute(Widget page) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const Offset begin = Offset(0.0, 1.0);
      const Offset end = Offset.zero;
      const Curve curve = Curves.easeOutCubic;
      final Tween<Offset> tween = Tween<Offset>(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
```

---

**Update FAB `onPressed`:**

Replace:
```dart
onPressed: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AddEditProductScreen(),
  ),
),
```

With:
```dart
onPressed: () => Navigator.push(
  context,
  _slideUpRoute(const AddEditProductScreen()),
),
```

No other changes to `manage_products_screen.dart`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/buyer/buyer_home_screen.dart` | `_contentOpacity` field, `initState()` with 100ms fade trigger, `AnimatedOpacity` wrapping body `Column` |
| 2 | `lib/screens/buyer/product_detail_screen.dart` | `Hero`-wrapped 280px image placeholder connecting to `ProductCard` hero tag |
| 3 | `lib/screens/artisan/manage_products_screen.dart` | `_slideUpRoute()` method, FAB updated to use slide-up `PageRouteBuilder` |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must make targeted modifications to three files. No new files, no new folders, no dependency changes.

---

**File 1: `lib/screens/buyer/buyer_home_screen.dart`**

Make three targeted changes:

**Change 1:** Add `double _contentOpacity = 0.0;` to `_BuyerHomeScreenState` field declarations after `int _currentNavIndex = 0`.

**Change 2:** Add `initState()` override after the field declarations:
```dart
@override
void initState() {
  super.initState();
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      setState(() => _contentOpacity = 1.0);
    }
  });
}
```

**Change 3:** In `build()`, locate the body `Column` containing `_buildSearchBar()`, `_buildCategoryChips()`, and `Expanded(child: _buildProductGrid())`. Wrap this `Column` in `AnimatedOpacity` as specified in Section 6. The `Scaffold`'s `body` parameter must now receive `AnimatedOpacity` as its direct child.

**Critical rules:**
- `initState()` must call `super.initState()` first.
- The `mounted` check inside `Future.delayed` is required — if the widget is disposed within 100ms (unlikely but possible), the `setState` must be skipped.
- `AnimatedOpacity` must wrap the entire body `Column` — not just the grid — so the search bar and chips also fade in together.
- `duration: const Duration(milliseconds: 400)` and `curve: Curves.easeIn` must be used exactly.

---

**File 2: `lib/screens/buyer/product_detail_screen.dart`**

Replace the entire PR23 `build()` method with the updated version specified in Section 6. The class declaration, constructor, and fields are unchanged. Only `build()` is replaced.

**Critical rules:**
- `Hero` tag must be exactly `'product-$productId'` — matching the tag in `ProductCard`.
- The `Hero` child is a `Container` of `height: 280` — not a `SizedBox`, not a widget with `Expanded`. A fixed height is required for the Hero animation to have a defined size on both screens.
- `SingleChildScrollView` wraps the outer `Column` — the 280px image area plus the info padding may exceed screen height on small devices.

---

**File 3: `lib/screens/artisan/manage_products_screen.dart`**

Make two targeted changes:

**Change 1:** Add `_slideUpRoute(Widget page)` as a private method to `_ManageProductsScreenState`, exactly as specified in Section 6.

**Change 2:** In `build()`, find the FAB `onPressed` callback. Replace `MaterialPageRoute(builder: (_) => const AddEditProductScreen())` with `_slideUpRoute(const AddEditProductScreen())`.

**Critical rules:**
- `_slideUpRoute` is a method of `_ManageProductsScreenState` — it uses `PageRouteBuilder<void>`.
- `Offset(0.0, 1.0)` is the starting offset — the page enters from below the screen bottom.
- `CurveTween(curve: Curves.easeOutCubic)` is chained to the `Tween<Offset>` via `.chain()` — this is the correct Flutter animation pattern for applying a curve to a tween.
- `transitionDuration: const Duration(milliseconds: 350)` — 350ms is long enough to feel deliberate without being sluggish.
- No other changes to `manage_products_screen.dart`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `CurveTween` — confirm it is from `package:flutter/animation.dart` (included in `material.dart`); `PageRouteBuilder<void>` generic type — explicit void return type prevents type inference warnings; `AnimatedOpacity` child must be a non-null widget; `Future.delayed` callback `mounted` check — required.

2. **Verify `AnimatedOpacity` is in `buyer_home_screen.dart`**
   ```
   grep 'AnimatedOpacity' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least one line.

3. **Verify `_contentOpacity` field and `initState`**
   ```
   grep '_contentOpacity' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least three lines — field declaration, `setState` in `initState`, and usage in `AnimatedOpacity`.

4. **Verify `Hero` tag in `product_detail_screen.dart`**
   ```
   grep "product-\$productId" lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line — the `Hero` tag string.

5. **Verify `Hero` height is 280**
   ```
   grep '280' lib/screens/buyer/product_detail_screen.dart
   ```
   Must return one line — the `Container` height.

6. **Verify `_slideUpRoute` method exists**
   ```
   grep '_slideUpRoute' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least two lines — the method definition and the FAB call.

7. **Verify `PageRouteBuilder` is used**
   ```
   grep 'PageRouteBuilder' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return at least one line.

8. **Verify `Offset(0.0, 1.0)` is the start offset**
   ```
   grep 'Offset(0.0, 1.0)' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return one line — confirming slide-from-bottom direction.

9. **Verify `MaterialPageRoute` is no longer in FAB**
   ```
   grep 'MaterialPageRoute' lib/screens/artisan/manage_products_screen.dart
   ```
   Must return no output — the FAB must use `_slideUpRoute`, not `MaterialPageRoute`.

10. **Hot reload on emulator — Hero animation test**
    ```
    flutter run
    ```
    Log in as a buyer.
    Confirm:
    - On `BuyerHomeScreen` mount: the search bar, chips, and product grid fade in smoothly over ~400ms (visible as a brief opacity transition from 0 to 1).
    - Tap any `ProductCard` → observe the product image area animating from the grid card position to the 280px area at the top of `ProductDetailScreen`.
    - Press back → observe the Hero animating back from `ProductDetailScreen` to the grid card.
    - The Hero animation is smooth and the image area is visible throughout the transition.

    Log in as an artisan.
    Confirm:
    - Tap FAB (+) on `ManageProductsScreen` → `AddEditProductScreen` slides up from the bottom of the screen over ~350ms.
    - Press back → `AddEditProductScreen` slides back down.
    - The slide transition uses `Curves.easeOutCubic` — fast start, decelerating at the end (not a linear slide).

    Press `q` to quit.

11. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/buyer/buyer_home_screen.dart`, `lib/screens/buyer/product_detail_screen.dart`, and `lib/screens/artisan/manage_products_screen.dart` should appear.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 25
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
git commit -m "PR25: Animations — Product Card Transitions + Screen Transitions"
git push origin pr25-animations
```

---

## Section 9 – Acceptance Criteria

- [ ] `BuyerHomeScreen` declares `double _contentOpacity = 0.0` and overrides `initState()` to set it to `1.0` after a 100ms `Future.delayed` with a `mounted` check.
- [ ] The body `Column` in `BuyerHomeScreen.build()` is wrapped in `AnimatedOpacity` with `duration: Duration(milliseconds: 400)` and `curve: Curves.easeIn`.
- [ ] `ProductDetailScreen` contains a `Hero` widget with tag `'product-$productId'` wrapping a 280px-tall `Container` image placeholder.
- [ ] The `Hero` tag in `ProductDetailScreen` exactly matches the tag format used in `ProductCard` — `'product-$productId'`.
- [ ] `ManageProductsScreen` defines a `_slideUpRoute(Widget page)` method that returns a `PageRouteBuilder` with `SlideTransition` entering from `Offset(0.0, 1.0)` to `Offset.zero`.
- [ ] The FAB `onPressed` in `ManageProductsScreen` uses `_slideUpRoute` instead of `MaterialPageRoute`.
- [ ] The slide transition uses `Curves.easeOutCubic` and `Duration(milliseconds: 350)`.
- [ ] On the emulator, the product grid fades in smoothly on `BuyerHomeScreen` mount.
- [ ] On the emulator, tapping a `ProductCard` produces a visible `Hero` animation to `ProductDetailScreen`.
- [ ] On the emulator, tapping the FAB on `ManageProductsScreen` produces a slide-up animation to `AddEditProductScreen`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR25 for CraftBridge. I added three animation layers — a `Hero` transition between product cards and the detail screen, an `AnimatedOpacity` fade-in for `BuyerHomeScreen` content, and a `PageRouteBuilder` slide-up transition for `AddEditProductScreen` — all purely additive with no structural changes to existing widget trees."

2. **`Hero` animation mechanics:** "Flutter's `Hero` widget automatically animates a widget from one screen to another when both screens contain a `Hero` with the same `tag`. The `ProductCard` in PR22 already wraps its image in `Hero(tag: 'product-$productId')`. This PR adds a matching `Hero(tag: 'product-$productId')` to `ProductDetailScreen`. Flutter handles the rest — interpolating the position, size, and shape between the card's grid position and the detail screen's full-width 280px area."

3. **Why `Hero` tags must be unique:** "If two `ProductCard` widgets on screen have the same `Hero` tag — which would happen if `productId` were not unique — Flutter would throw a `Hero` tag conflict error. The `'product-'` prefix plus the product ID guarantees uniqueness across all product cards in the grid. This is why the `productId` parameter was included in `ProductCard` even though it isn't displayed — it exists solely for the `Hero` tag."

4. **`AnimatedOpacity` vs `FadeTransition`:** "`AnimatedOpacity` is an implicit animation — it automatically interpolates between the current `opacity` value and the new value whenever the value changes. `FadeTransition` is an explicit animation that requires an `AnimationController`. For a simple one-shot fade-in on screen mount, `AnimatedOpacity` is the right tool — less boilerplate, no controller lifecycle to manage."

5. **100ms delay before opacity trigger:** "The 100ms `Future.delayed` in `initState()` ensures the first frame renders at `opacity: 0.0` before the fade begins. Without the delay, the `setState` and the first `build` could happen in the same frame, and the animation might not be visible. The 100ms is imperceptible to the user but guarantees the animation plays from transparent to opaque on the next frame."

6. **`mounted` check in `Future.delayed`:** "If `BuyerHomeScreen` is disposed within 100ms of mounting — for example, if the user immediately navigates away during a fast login — the `Future.delayed` callback would fire on a disposed widget. The `mounted` check prevents `setState` from being called on a disposed `State` object, which would throw a framework error."

7. **`PageRouteBuilder` slide-up transition:** "`MaterialPageRoute` uses a platform-default transition — on Android, a right-to-left slide. For `AddEditProductScreen`, a bottom-to-top slide feels more appropriate — it suggests the form is appearing 'above' the current screen, like a modal. `PageRouteBuilder` gives full control over the transition animation. `Curves.easeOutCubic` starts fast and decelerates to a stop, matching the 'springing up' feel of a bottom sheet or modal."

8. **`Tween.chain(CurveTween)` pattern:** "The animation is built as `Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic))`. `.chain()` composes two `Animatable` objects — the tween handles value interpolation, the `CurveTween` handles timing. `animation.drive(tween)` then runs the composed tween against the route's animation controller. This is the recommended Flutter pattern for curved tweens."

9. **Emulator demonstration:** "On the emulator: opening `BuyerHomeScreen` shows the search bar and grid fading in from transparent over 400ms — subtle but visible. Tapping a product card, the image area smoothly expands from the grid cell to fill the top of the detail screen. Pressing back, it contracts back. Tapping the FAB on the artisan screen, the add-product form slides up from the bottom. Pressing back, it slides back down."

10. **What's Next:** "PR26 will implement `ProductProvider` — creating the full product state management layer and implementing `FirestoreService.getProducts()` and `getProductsByArtisan()` — enabling the first live Firestore product reads in the app."