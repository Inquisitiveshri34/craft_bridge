# PR45 – BottomNavigationBar — Buyer Nav Shell Complete

**Project:** CraftBridge
**PR Number:** 45 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Polish and complete the `BuyerHomeScreen` navigation shell — verify `IndexedStack` tab behaviour, refine the cart badge, add tab-aware app bar, and produce the buyer navigation documentation.

---

## Section 2 – Assignments Covered

- Assignment 3.45 — BottomNavigationBar — Buyer Nav Shell Complete

---

## Section 3 – Objective

PR43 implemented the functional `IndexedStack` navigation with `BottomNavigationBar` and a cart badge. This PR completes and polishes the buyer navigation shell — verifying correct `IndexedStack` tab preservation behaviour, refining the cart badge animation, adding a `FloatingActionButton` shortcut to the cart on the Home tab, and producing `docs/PR45_Buyer_Nav_Shell.md` documenting the buyer navigation architecture. No major structural changes — this PR is primarily a refinement and documentation PR that ensures the buyer nav shell is production-quality before the dark mode (PR46) and error handling (PR47) PRs.

---

## Section 4 – Architecture Context

```
BuyerHomeScreen (after this PR)
  │
  ├── Scaffold
  │     ├── AppBar (tab-aware title + conditional actions)
  │     ├── body: IndexedStack (3 children — mounted simultaneously)
  │     │     ├── [0] Home: AnimatedOpacity → Column(search, chips, grid)
  │     │     ├── [1] Cart: CartScreen
  │     │     └── [2] Orders: BuyerOrdersScreen
  │     │
  │     ├── floatingActionButton: (only on Home tab)
  │     │     └── AnimatedScale FAB → navigates to cart tab
  │     │
  │     └── bottomNavigationBar: Consumer<CartProvider>
  │           └── BottomNavigationBar (3 tabs)
  │                 ├── Home
  │                 ├── Cart (Badge with itemCount)
  │                 └── Orders
  │
  └── _currentNavIndex drives everything

New this PR:
  FAB on Home tab → jumps to Cart tab (setState(_currentNavIndex = 1))
  FAB animates in/out with AnimatedScale based on cart item count
  Cart badge uses AnimatedSwitcher for smooth count transitions
  docs/PR45_Buyer_Nav_Shell.md produced
```

This PR sits after review form (PR44) and before dark mode (PR46). Since PR43 already implemented the full `IndexedStack` + `BottomNavigationBar`, this PR adds the FAB shortcut, animates the badge, and documents the architecture.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/buyer/buyer_home_screen.dart`
- `docs/PR45_Buyer_Nav_Shell.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any widget files.
- Do NOT modify any other screen files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/buyer/buyer_home_screen.dart`

Three targeted additions to the PR43 implementation. The `IndexedStack`, `BottomNavigationBar`, `AppBar`, `Consumer<CartProvider>` badge, and all search/filter/grid logic are preserved unchanged.

---

**Change 1 — Add `FloatingActionButton` to `Scaffold`:**

In `build()`, add `floatingActionButton` as a named parameter of `Scaffold`:

```dart
floatingActionButton: _currentNavIndex == 0
    ? Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          return AnimatedScale(
            scale: cartProvider.itemCount > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: FloatingActionButton.extended(
              onPressed: () =>
                  setState(() => _currentNavIndex = 1),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(
                '${cartProvider.itemCount} item${cartProvider.itemCount == 1 ? '' : 's'}',
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          );
        },
      )
    : null,
```

**Behaviour:**
- The FAB is only rendered on the Home tab (`_currentNavIndex == 0`). On Cart and Orders tabs, `floatingActionButton: null` removes it.
- `AnimatedScale` scales the FAB from 0.0 to 1.0 when cart items are added — giving a smooth pop-in effect. When the cart is emptied, the FAB scales back to 0.0.
- `FloatingActionButton.extended` shows both an icon and a label — "2 items" or "1 item" with correct singular/plural.
- Tapping the FAB sets `_currentNavIndex = 1`, switching to the Cart tab.
- `backgroundColor: Theme.of(context).colorScheme.primary` — brand brown, consistent with the app theme.

---

**Change 2 — Wrap cart badge `Text` in `AnimatedSwitcher`:**

In the `BottomNavigationBar` `Consumer<CartProvider>`, update the `Badge.label` to use `AnimatedSwitcher` for smooth count transitions:

Replace:
```dart
label: Text('${cartProvider.itemCount}'),
```

With:
```dart
label: AnimatedSwitcher(
  duration: const Duration(milliseconds: 150),
  child: Text(
    '${cartProvider.itemCount}',
    key: ValueKey<int>(cartProvider.itemCount),
  ),
),
```

Apply this change to both the `icon` and `activeIcon` `Badge.label` instances.

**`AnimatedSwitcher` behaviour:** When `cartProvider.itemCount` changes, the `ValueKey` changes, and `AnimatedSwitcher` cross-fades between the old and new count text. This prevents the badge count from jumping abruptly — it fades from "2" to "3" smoothly.

---

**Change 3 — Add `floatingActionButtonLocation` to position FAB:**

```dart
floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
```

`centerFloat` positions the extended FAB at the horizontal centre of the screen, floating above the `BottomNavigationBar`. This is the standard position for a contextual action FAB.

---

### `docs/PR45_Buyer_Nav_Shell.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: `BuyerHomeScreen` implements CraftBridge's only `BottomNavigationBar` — a three-tab navigation shell with Home, Cart, and Orders. The shell uses `IndexedStack` to keep all three screens mounted simultaneously, preserving state across tab switches. A `FloatingActionButton` on the Home tab provides a quick shortcut to the cart when items are present.

---

#### 2. `IndexedStack` vs `PageView` vs `Navigator.push`

A table with columns: **Approach**, **State Preservation**, **Memory Usage**, **Build Cost on Switch**, **CraftBridge Choice**.

| Approach | State Preservation | Memory Usage | Build Cost on Switch | CraftBridge Choice |
|----------|-------------------|--------------|---------------------|--------------------|
| `IndexedStack` | Full — all screens mounted | Higher — all screens in memory | Zero — no rebuild | ✓ Yes |
| `PageView` | Full — lazy mounting with `keepAlive` | Medium | Zero after first build | No |
| `Navigator.push` | None — screen rebuilt on each push | Low | Full rebuild on each switch | No |

Followed by one paragraph explaining: `IndexedStack` was chosen for CraftBridge because the `ProductProvider` stream for the Home tab and the `OrderProvider` stream for the Orders tab are already active — switching tabs costs zero performance. The higher memory usage is acceptable for three screens.

---

#### 3. Cart Badge Architecture

A prose section covering:

- The cart badge on the Cart `BottomNavigationBarItem` uses Flutter's built-in `Badge` widget (Material 3, Flutter 3.10+).
- `isLabelVisible: cartProvider.itemCount > 0` — badge hidden when cart is empty.
- `AnimatedSwitcher` wraps the badge count text with a `ValueKey<int>(cartProvider.itemCount)` — triggers a cross-fade animation when the count changes.
- The entire `BottomNavigationBar` is wrapped in `Consumer<CartProvider>` — any cart change triggers a rebuild of the full navigation bar, updating the badge.
- The same `cartProvider.itemCount` drives the FAB label on the Home tab.

---

#### 4. `FloatingActionButton.extended` on Home Tab

A prose section covering:

- The FAB only appears on the Home tab — `_currentNavIndex == 0 ? FAB : null`.
- `AnimatedScale` with `scale: cartProvider.itemCount > 0 ? 1.0 : 0.0` gives a pop-in/pop-out effect when items are added or removed.
- `FloatingActionButton.extended` shows icon + text label — more informative than a plain FAB for a cart shortcut.
- `FloatingActionButtonLocation.centerFloat` positions the FAB above the `BottomNavigationBar` at horizontal centre.
- The FAB is a secondary navigation shortcut — the Cart tab in `BottomNavigationBar` is the primary navigation path.

---

#### 5. Tab-Aware `AppBar` Behaviour

A prose section covering:

- `AppBar` title changes based on `_currentNavIndex`: "Discover" (0), "My Cart" (1), "My Orders" (2).
- Sign-out `IconButton` only appears on the Home tab — Cart and Orders tabs have no action icons.
- `BuyerOrdersScreen.automaticallyImplyLeading: false` — when displayed inside `IndexedStack`, the Orders screen has no back button. The user navigates between tabs via `BottomNavigationBar`.

---

#### 6. State Preservation Verification

A prose section covering the manual verification procedure:

- Scroll the product grid down on the Home tab.
- Switch to Orders tab.
- Switch back to Home tab.
- Verify: scroll position in the product grid is preserved — the `IndexedStack` never unmounts the Home content.
- Add a product to the cart from the Home tab.
- Switch to Cart tab — the added item is present without a reload.
- Switch back to Home — the badge count is still correct.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/buyer/buyer_home_screen.dart` | Cart FAB with `AnimatedScale`, `FloatingActionButtonLocation.centerFloat`, `AnimatedSwitcher` on badge count |
| 2 | `docs/PR45_Buyer_Nav_Shell.md` | Complete buyer nav shell documentation with all 6 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must make targeted changes to one Dart file and write one Markdown document.

---

**File: `lib/screens/buyer/buyer_home_screen.dart`**

Make three targeted changes to the PR43 implementation:

**Change 1:** In `build()`, add `floatingActionButton:` as a named parameter of `Scaffold`. The FAB renders `null` when `_currentNavIndex != 0` and a `Consumer<CartProvider>`-wrapped `AnimatedScale(FloatingActionButton.extended(...))` when `_currentNavIndex == 0`.

**Change 2:** In both `icon` and `activeIcon` `Badge` instances in the `BottomNavigationBar`, wrap the `Text('${cartProvider.itemCount}')` in `AnimatedSwitcher` with `duration: Duration(milliseconds: 150)` and `ValueKey<int>(cartProvider.itemCount)`.

**Change 3:** Add `floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat` as a named parameter of `Scaffold`.

**Critical rules:**
- `AnimatedScale` wraps `FloatingActionButton.extended` — not the other way round.
- `scale: cartProvider.itemCount > 0 ? 1.0 : 0.0` — FAB scales to zero (invisible) when cart is empty.
- `floatingActionButton: null` when `_currentNavIndex != 0` — FAB absent on Cart and Orders tabs.
- `AnimatedSwitcher` `child` must have a `key` that changes when the value changes — `ValueKey<int>(cartProvider.itemCount)` satisfies this.
- All PR43 structure — `IndexedStack`, `Consumer<CartProvider>` on `BottomNavigationBar`, `AppBar` dynamic title, `_buildSearchBar`, `_buildCategoryChips`, `_buildProductGrid` — is preserved unchanged.

---

**File 2: `docs/PR45_Buyer_Nav_Shell.md`**

Write the complete Markdown document with all 6 sections as specified in Section 6.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. Common issues: `AnimatedScale` child must not be null — the `FloatingActionButton.extended` is always provided, scale handles visibility; `AnimatedSwitcher` requires `key` on child to detect changes; `FloatingActionButtonLocation` is in `material.dart`.

2. **Verify `FloatingActionButton.extended` is added**
   ```
   grep 'FloatingActionButton.extended' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line.

3. **Verify `AnimatedScale` wraps FAB**
   ```
   grep 'AnimatedScale' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least one line.

4. **Verify FAB is null on non-Home tabs**
   ```
   grep 'floatingActionButton:' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line containing the `_currentNavIndex == 0 ?` conditional.

5. **Verify `AnimatedSwitcher` on badge**
   ```
   grep 'AnimatedSwitcher' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least two lines — one for each `Badge` instance (icon and activeIcon).

6. **Verify `ValueKey` on `AnimatedSwitcher` child**
   ```
   grep 'ValueKey' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return at least two lines.

7. **Verify `FloatingActionButtonLocation.centerFloat`**
   ```
   grep 'centerFloat' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line.

8. **Verify document has 6 sections**
   ```
   cat docs/PR45_Buyer_Nav_Shell.md
   ```
   Confirm all 6 sections present. Confirm Section 2 has the comparison table. Confirm Section 6 covers the manual state preservation verification procedure.

9. **Hot reload on emulator — nav shell polish test**
   ```
   flutter run
   ```
   Log in as a buyer.

   **FAB appearance test:**
   - On Home tab with empty cart: no FAB visible.
   - Add a product to cart: FAB pops in with `AnimatedScale` — "1 item" label visible.
   - Add another product: FAB label updates to "2 items" smoothly.
   - Cart badge on `BottomNavigationBar` updates with `AnimatedSwitcher` cross-fade.
   - Tap FAB: switches to Cart tab, FAB disappears (not on Cart tab).
   - Return to Home tab: FAB visible again.
   - Remove all items from cart: FAB scales out smoothly.

   **Tab behaviour test:**
   - Scroll Home tab grid down → switch to Orders → switch back → scroll position preserved.
   - `AppBar` title changes correctly across all three tabs.
   - Sign-out button only visible on Home tab.

   Press `q` to quit.

10. **Verify only correct files were modified**
    ```
    git diff --name-only
    ```
    Only `lib/screens/buyer/buyer_home_screen.dart` and `docs/PR45_Buyer_Nav_Shell.md` should appear.

11. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 45
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
git commit -m "PR45: BottomNavigationBar — Buyer Nav Shell Complete"
git push origin pr45-buyer-nav-shell
```

---

## Section 9 – Acceptance Criteria

- [ ] `BuyerHomeScreen` has a `FloatingActionButton.extended` that appears only on the Home tab (`_currentNavIndex == 0`) and is `null` on other tabs.
- [ ] The FAB is wrapped in `AnimatedScale` with `scale: cartProvider.itemCount > 0 ? 1.0 : 0.0` — invisible when cart is empty, animated in when items are added.
- [ ] The FAB label shows the correct item count with singular/plural ("1 item" / "2 items").
- [ ] Tapping the FAB sets `_currentNavIndex = 1`, switching to the Cart tab.
- [ ] `FloatingActionButtonLocation.centerFloat` positions the FAB above the `BottomNavigationBar`.
- [ ] Both `Badge.label` instances in `BottomNavigationBar` (icon and activeIcon) use `AnimatedSwitcher` with `ValueKey<int>(cartProvider.itemCount)`.
- [ ] All PR43 structure is preserved — `IndexedStack`, `Consumer<CartProvider>` badge, dynamic `AppBar` title, sign-out on Home only.
- [ ] `docs/PR45_Buyer_Nav_Shell.md` exists with all 6 sections including the `IndexedStack` comparison table.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR45 for CraftBridge. I polished the buyer navigation shell — adding a `FloatingActionButton.extended` cart shortcut on the Home tab that animates in when items are in the cart, smoothing the badge count transitions with `AnimatedSwitcher`, and documenting the full navigation architecture."

2. **`FloatingActionButton.extended` cart shortcut:** "The extended FAB shows an icon and label — 'shopping cart icon + 2 items' — giving buyers a quick way to jump to the cart without taking their eyes off the product grid. It only appears on the Home tab and only when the cart has items. On the Cart and Orders tabs, `floatingActionButton: null` removes it entirely."

3. **`AnimatedScale` pop-in effect:** "`AnimatedScale` wraps the FAB and scales from 0.0 to 1.0 when `cartProvider.itemCount` goes from 0 to 1. The transition uses `Curves.easeInOut` over 200ms — the FAB springs into view when the first item is added and springs out when the last item is removed. `scale: 0.0` makes the widget invisible and non-interactive without removing it from the tree."

4. **`AnimatedSwitcher` on badge count:** "When the cart count changes from 2 to 3, the badge label would normally jump abruptly from '2' to '3'. `AnimatedSwitcher` with `ValueKey<int>(cartProvider.itemCount)` cross-fades between the old and new text over 150ms. The `ValueKey` is essential — `AnimatedSwitcher` compares the new and old widget keys to decide whether to animate. Without the key, it wouldn't detect the change."

5. **`FloatingActionButtonLocation.centerFloat`:** "`centerFloat` positions the extended FAB at horizontal centre, floating above the `BottomNavigationBar` with standard Material padding. An extended FAB positioned at `endFloat` (the default) would be right-aligned and feel cramped. `centerFloat` gives the label room to breathe and matches the Material 3 recommended position for bottom-bar FABs."

6. **Why both `icon` and `activeIcon` badges need `AnimatedSwitcher`:** "The `BottomNavigationBarItem.icon` is shown when the tab is unselected; `activeIcon` is shown when selected. Both need the animated badge update — if only `icon` had the animation, switching to the Cart tab (triggering `activeIcon`) would show a static badge count."

7. **`IndexedStack` vs `PageView` vs `Navigator.push` table:** "Section 2 of the documentation compares the three tab navigation approaches. `IndexedStack` wins on state preservation — all three screens are mounted and their streams are active. The cost is higher memory usage, which is acceptable for three lightweight screens. `Navigator.push` would rebuild the Orders screen every time the buyer switches to it, potentially showing a loading spinner on every tab switch."

8. **FAB as secondary navigation:** "`BottomNavigationBar` remains the primary navigation — accessible from any tab. The FAB is a secondary shortcut for a specific context: browsing products with items in the cart. It reinforces the CTA without replacing the navigation bar. The sign-out icon in the AppBar follows the same principle — contextual actions for the current tab only."

9. **Emulator demonstration:** "On the emulator: empty cart — no FAB. Add a product — the FAB springs in at the bottom centre with 'shopping cart + 1 item'. Tap another product, add it — FAB updates to '2 items' with a smooth badge transition. Tap the FAB — jumps to Cart tab, FAB disappears. Navigate back to Home — FAB reappears. Clear the cart — FAB springs out."

10. **What's Next:** "PR46 will add dark mode to CraftBridge — implementing `ThemeProvider`, adding `darkTheme` to `AppTheme`, and wiring both themes to `main.dart` with a toggle that persists the user's preference."