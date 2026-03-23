# PR17 – Responsive Layout — BuyerHomeScreen Shell + ArtisanHomeScreen Layout

**Project:** CraftBridge
**PR Number:** 17 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `BuyerHomeScreen` shell with responsive product grid placeholder and complete `ArtisanHomeScreen` layout with `MediaQuery`-driven responsive column structure.

---

## Section 2 – Assignments Covered

- Assignment 3.17 — Responsive Layout — BuyerHomeScreen Shell + ArtisanHomeScreen Layout

---

## Section 3 – Objective

This is the final PR assigned to Member 1. It completes two screens: `BuyerHomeScreen` receives its full shell — app bar, search bar placeholder, category chip row placeholder, and a responsive `GridView` stub — and `ArtisanHomeScreen` is updated to use `MediaQuery` to adapt its navigation card layout between single-column (narrow) and two-column (wide) arrangements. After this PR merges, Member 1's work is complete and the repository is handed off to Member 2 (PR18–PR34) and Member 3 (PR35–PR51). The `docs/PR17_Responsive_Layout.md` document produced here explains the responsive design decisions for Member 2 and Member 3 to follow in their screen implementations.

---

## Section 4 – Architecture Context

```
RoleRouterScreen
    └── role == buyer → BuyerHomeScreen (this PR — shell)

BuyerHomeScreen shell (after this PR):
  Scaffold
    ├── AppBar ("Discover")
    └── body: Column
          ├── search bar placeholder (TextField stub)
          ├── category chips row placeholder (horizontal scroll stub)
          └── Expanded → GridView.builder
                          └── placeholder ProductCard stubs
                              (real ProductCard + live data: PR23, PR26, PR32)

ArtisanHomeScreen responsive update (this PR):
  Before: Column with two _NavCard stacked vertically (always)
  After:  MediaQuery-driven layout:
            width < 600dp  → Column  (single card per row)
            width >= 600dp → Row with two Expanded _NavCards side by side

docs/PR17_Responsive_Layout.md ← produced this PR
```

This PR sits at the boundary between Member 1's work (PRs 01–17) and Member 2's work (PRs 18–34). The `BuyerHomeScreen` shell created here is replaced by Member 2's live implementation across PRs 23, 26, and 32. The responsive pattern demonstrated in `ArtisanHomeScreen` is the reference implementation for all grid and list screens in PRs 18–51.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/buyer/buyer_home_screen.dart`
- `lib/screens/artisan/artisan_home_screen.dart`
- `docs/PR17_Responsive_Layout.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`.
- Do NOT modify `role_router_screen.dart` or `splash_screen.dart`.
- Do NOT modify any widget placeholder files.
- Do NOT modify any provider files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/buyer/buyer_home_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `BuyerHomeScreen` and `_BuyerHomeScreenState`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`

**Constructor:** `const BuyerHomeScreen({super.key})`

---

**`_BuyerHomeScreenState` fields:**
```dart
final TextEditingController _searchController = TextEditingController();
String _selectedCategory = 'All';
int _currentNavIndex = 0;
```

---

**`dispose()` method:**
```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

---

**`build()` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- `appBar`: `AppBar` with:
  - `title: const Text('Discover')`
  - `actions`: `[IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign Out', onPressed: () => context.read<AuthProvider>().signOut())]`
- `body`: `Column` with `children`:
  1. `_buildSearchBar()` — result of private method call
  2. `_buildCategoryChips()` — result of private method call
  3. `Expanded` child: `_buildProductGrid()` — result of private method call
- `bottomNavigationBar`: `BottomNavigationBar` with:
  - `currentIndex: _currentNavIndex`
  - `onTap: (index) => setState(() => _currentNavIndex = index)`
  - `selectedItemColor`: `Theme.of(context).colorScheme.primary`
  - `unselectedItemColor`: `Theme.of(context).colorScheme.onSurface.withOpacity(0.5)`
  - `items`: three `BottomNavigationBarItem` entries:
    1. `BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home')`
    2. `BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Cart')`
    3. `BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders')`

---

**`_buildSearchBar()` method:**

```dart
Widget _buildSearchBar() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(
      AppConstants.defaultPadding,
      AppConstants.defaultPadding,
      AppConstants.defaultPadding,
      8,
    ),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (_) => setState(() {}),
    ),
  );
}
```

---

**`_buildCategoryChips()` method:**

```dart
Widget _buildCategoryChips() {
  final List<String> categories = ['All', ...AppConstants.productCategories];
  return SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final String category = categories[index];
        final bool isSelected = _selectedCategory == category;
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (_) => setState(() => _selectedCategory = category),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          showCheckmark: false,
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        );
      },
    ),
  );
}
```

---

**`_buildProductGrid()` method:**

```dart
Widget _buildProductGrid() {
  final double screenWidth = MediaQuery.of(context).size.width;
  final int crossAxisCount = screenWidth < 600 ? 2 : 3;
  return GridView.builder(
    padding: const EdgeInsets.all(AppConstants.defaultPadding),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
    ),
    itemCount: 6,
    itemBuilder: (context, index) {
      return _PlaceholderProductCard(index: index);
    },
  );
}
```

---

**`_PlaceholderProductCard` private widget** — defined in the same file below `BuyerHomeScreen`:

**Widget type:** `StatelessWidget`

**Class name:** `_PlaceholderProductCard`

**Constructor parameter:** `required final int index`

**`build` method returns:** `Card` with `child: Column` with `children`:
1. `Expanded` child: `Container` with `decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.08), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)))` and `child: Center(child: Icon(Icons.image_outlined, size: 40, color: Theme.of(context).colorScheme.primary.withOpacity(0.3)))`
2. `Padding` with `padding: const EdgeInsets.all(8)` and `child: Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:
   - `Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(4)))` — skeleton title placeholder
   - `const SizedBox(height: 4)`
   - `Container(height: 10, width: 80, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.07), borderRadius: BorderRadius.circular(4)))` — skeleton price placeholder

---

### `lib/screens/artisan/artisan_home_screen.dart`

Update the PR16 implementation. The only change is to the `body` `Column` — the two `_NavCard` calls are wrapped in a `MediaQuery`-driven responsive layout.

**Change:** Replace the static two-card `Column` section (items 7–9 in the PR16 children list — the two `_NavCard` calls and the `SizedBox` between them) with the following responsive layout block:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final bool isWide = constraints.maxWidth >= 600;
    if (isWide) {
      return Row(
        children: [
          Expanded(
            child: _NavCard(
              title: 'My Products',
              subtitle: 'Add, edit and manage your listings',
              icon: Icons.inventory_2_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageProductsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _NavCard(
              title: 'My Orders',
              subtitle: 'View and update incoming orders',
              icon: Icons.receipt_long_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArtisanOrdersScreen(),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        _NavCard(
          title: 'My Products',
          subtitle: 'Add, edit and manage your listings',
          icon: Icons.inventory_2_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManageProductsScreen(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _NavCard(
          title: 'My Orders',
          subtitle: 'View and update incoming orders',
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ArtisanOrdersScreen(),
            ),
          ),
        ),
      ],
    );
  },
),
```

All other parts of `artisan_home_screen.dart` — the welcome text, the `_NavCard` class definition, imports, app bar, sign-out button — are unchanged from PR16.

---

### `docs/PR17_Responsive_Layout.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: responsive layout in Flutter means the UI adapts to different screen sizes without separate codebases or layout files. CraftBridge targets Android phones as the primary device, with tablet and large-screen support as a secondary concern. The responsive patterns established in this PR — `MediaQuery` for screen dimensions, `LayoutBuilder` for constraint-based layouts, and dynamic `crossAxisCount` in `GridView` — are the reference implementations for all grid and list screens in PRs 18–51.

---

#### 2. Responsive Breakpoints

A table with columns: **Breakpoint**, **Width Range**, **Grid Columns**, **Layout Pattern**, **Used In**.

| Breakpoint | Width Range | Grid Columns | Layout Pattern | Used In |
|------------|-------------|--------------|----------------|---------|
| Phone portrait | < 360dp | 2 | Single column lists, 2-col grids | Default phone layout |
| Phone landscape | 360dp–599dp | 2 | Single column lists, 2-col grids | Rotated phone |
| Tablet / wide | ≥ 600dp | 3 | Side-by-side cards, 3-col grids | Tablets, large phones |

Followed by one paragraph noting that 600dp is the Material Design recommended small-to-medium breakpoint and is the single threshold used throughout CraftBridge for simplicity.

---

#### 3. `MediaQuery` vs `LayoutBuilder`

A prose section covering:

- **`MediaQuery.of(context).size.width`** gives the full screen width. Use it when the layout decision is based on the device screen size, not the available space within a parent widget. Example: choosing `crossAxisCount` in a full-width `GridView`.
- **`LayoutBuilder`** gives the `BoxConstraints` of the parent widget. Use it when the widget may be embedded inside another widget that constrains its available width — for example, a card inside a padded container. `constraints.maxWidth` is always the available space, not the screen width.
- In `ArtisanHomeScreen`, `LayoutBuilder` is used for the nav card row/column switch because the cards live inside a `Padding` widget — the available width is screen width minus `2 * defaultPadding`. Using `MediaQuery` here would apply the 600dp threshold to the full screen width, but `LayoutBuilder` applies it to the actual drawable area.
- In `BuyerHomeScreen._buildProductGrid`, `MediaQuery` is used for `crossAxisCount` because the `GridView` spans the full screen width with symmetric padding — the difference between screen width and available width is predictable and small.
- Rule of thumb: prefer `LayoutBuilder` for column/row layout switches; prefer `MediaQuery` for grid column count decisions.

---

#### 4. `GridView.builder` Configuration

A prose section covering the `SliverGridDelegateWithFixedCrossAxisCount` parameters used in `BuyerHomeScreen`:

- `crossAxisCount`: 2 for phones, 3 for tablets — determined by `MediaQuery` width threshold at 600dp.
- `crossAxisSpacing: 12` — horizontal gap between cards in pixels.
- `mainAxisSpacing: 12` — vertical gap between rows in pixels.
- `childAspectRatio: 0.75` — each card's width-to-height ratio is 3:4, giving product cards enough vertical space for an image and title without cropping.
- All `ProductCard` implementations in PRs 22, 23, and 32 must use this same delegate configuration to maintain visual consistency.

---

#### 5. `BottomNavigationBar` in `BuyerHomeScreen`

A prose section covering:

- `BuyerHomeScreen` is the only screen in CraftBridge with a `BottomNavigationBar` in the MVP.
- The shell in PR17 has three tabs — Home, Cart, Orders — but only the Home tab renders content. Cart and Orders tabs show placeholder content until PRs 33, 42, and 43 implement those screens.
- The full `BottomNavigationBar` with `IndexedStack` and cart badge is completed in PR45.
- `currentIndex` is managed as local state (`_currentNavIndex`) in `_BuyerHomeScreenState`. This is appropriate for tab index — it is purely UI state with no business logic or Firebase dependency.
- `selectedItemColor` and `unselectedItemColor` are set explicitly from `colorScheme.primary` and `onSurface` to ensure brand-consistent tab indicator colours.

---

#### 6. Placeholder Skeleton Cards

A prose section covering:

- `_PlaceholderProductCard` renders a skeleton layout — grey rectangles in place of the actual image, title, and price — rather than a loading spinner or empty state.
- Skeleton layouts communicate the shape of incoming content before data loads, which is better UX than a blank screen or a centred spinner for grid-based browsing screens.
- The placeholder is replaced by the real `ProductCard` widget in PR22 and wired to live Firestore data in PR32.
- The skeleton uses `withOpacity` on `colorScheme.primary` and `colorScheme.onSurface` for its placeholder colours — no hardcoded greys.

---

#### 7. Member 2 and Member 3 Handoff Notes

A prose section addressed to the next members, covering:

- `BuyerHomeScreen` shell is in place at `lib/screens/buyer/buyer_home_screen.dart`. Member 2 will modify this file in PR23 (responsive grid) and PR32 (live product data). The shell structure — search bar, category chips, grid — must be preserved; only the `_PlaceholderProductCard` and `itemCount` values change.
- `ArtisanHomeScreen` responsive layout is complete. Member 2 does not need to touch `artisan_home_screen.dart` — the responsive `LayoutBuilder` is already in place.
- All responsive decisions use the 600dp breakpoint. Do not introduce new breakpoints without updating this document.
- `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount` is the required grid pattern for all product grids. Do not use `GridView.count` or `GridView.extent`.
- `LayoutBuilder` is preferred over `MediaQuery` for column/row layout switches inside padded containers. Follow the pattern in `artisan_home_screen.dart`.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/buyer/buyer_home_screen.dart` | Full `BuyerHomeScreen` shell — app bar, search bar, category chips, responsive `GridView` with skeleton placeholders, `BottomNavigationBar` |
| 2 | `lib/screens/artisan/artisan_home_screen.dart` | Updated with `LayoutBuilder`-driven responsive nav card layout |
| 3 | `docs/PR17_Responsive_Layout.md` | Complete responsive layout reference document with all 7 sections |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR16 is merged to main**

Open your GitHub repository and confirm the `pr16-navigation-routes` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR17 branch**
```
git checkout -b pr17-responsive-layout
```

**Step 4 — Confirm `buyer_home_screen.dart` is the PR12 minimal stub**
```
cat lib/screens/buyer/buyer_home_screen.dart
```
Must show the PR12 stub — `StatelessWidget` with `Text('BuyerHomeScreen — implemented in PR17')`.

**Step 5 — Confirm `artisan_home_screen.dart` is the PR16 implementation**
```
grep 'LayoutBuilder' lib/screens/artisan/artisan_home_screen.dart
```
Must return no output — confirming `LayoutBuilder` is not yet present and the PR16 static layout is in place.

**Step 6 — Confirm `AppConstants.productCategories` is populated**
```
grep 'productCategories' lib/core/constants/app_constants.dart
```
Must return the list with all 7 category values. This is consumed by `_buildCategoryChips()`.

---

Manual setup for this PR is now complete.
Open `docs/PR17_Responsive_Layout.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must modify two Dart files and write one Markdown document.

---

**File 1: `lib/screens/buyer/buyer_home_screen.dart`**

Replace the PR12 stub entirely. Write the complete file as specified in Section 6:

1. All import statements.
2. `BuyerHomeScreen extends StatefulWidget` with `const` constructor.
3. `_BuyerHomeScreenState` with:
   - Three fields: `_searchController`, `_selectedCategory` (default `'All'`), `_currentNavIndex` (default `0`).
   - `dispose()` disposing `_searchController`.
   - `_buildSearchBar()` private method exactly as specified — `Padding` > `TextField` with search icon prefix, clear icon suffix (conditional on non-empty text), `onChanged` calling `setState`.
   - `_buildCategoryChips()` private method exactly as specified — `SizedBox(height: 48)` > `ListView.separated` with horizontal scroll, `['All', ...AppConstants.productCategories]` as the categories list, `FilterChip` for each with `selected` state, white label when selected, primary colour border when selected, `showCheckmark: false`.
   - `_buildProductGrid()` private method exactly as specified — `MediaQuery` width check for `crossAxisCount`, `GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount`, `itemCount: 6`, `_PlaceholderProductCard`.
   - `build()` returning `Scaffold` with app bar (sign-out action), `Column` body with `_buildSearchBar()`, `_buildCategoryChips()`, `Expanded(_buildProductGrid())`, and `BottomNavigationBar` with three items.
4. `_PlaceholderProductCard extends StatelessWidget` below `_BuyerHomeScreenState` with `required int index` and the skeleton `Card` layout as specified.

**Critical implementation rules:**
- `_buildCategoryChips` builds its list as `['All', ...AppConstants.productCategories]` using the spread operator — 'All' is prepended to the 7 product categories from `AppConstants`, giving 8 chips total.
- `FilterChip` with `showCheckmark: false` is required — the chip must not show a checkmark icon when selected.
- `_searchController.text.isNotEmpty` drives the visibility of the clear suffix icon. `onChanged: (_) => setState(() {})` triggers a rebuild so the clear button appears/disappears as text is typed.
- `BottomNavigationBar.currentIndex` is bound to `_currentNavIndex` — tapping a tab updates the index. The tab content does not change in this PR — only the index state is managed.
- `_PlaceholderProductCard` constructor uses `required final int index` — the `index` parameter is accepted but not used in the current skeleton implementation. It is present for forward compatibility with the real `ProductCard` replacement in PR22/PR32.

---

**File 2: `lib/screens/artisan/artisan_home_screen.dart`**

Make one targeted change to the existing PR16 implementation:

Replace the static two-card section of the `Column` children (the two `_NavCard` calls and the `SizedBox(height: 16)` between them) with the `LayoutBuilder` responsive block specified in Section 6.

The agent must:
- Preserve all other parts of the file exactly as they were in PR16.
- NOT change the `_NavCard` class definition.
- NOT change the welcome text, app bar, sign-out button, or any other `Column` children.
- Only replace the two `_NavCard` calls (and the `SizedBox` between them) with the single `LayoutBuilder` widget that contains both the wide `Row` and narrow `Column` variants.

---

**File 3: `docs/PR17_Responsive_Layout.md`**

Write the complete Markdown document with all 7 sections specified in Section 6. The agent must write:
- Section 1: 3–4 sentences overview.
- Section 2: Complete 3-row breakpoint table followed by the 600dp rationale paragraph.
- Section 3: Full prose covering all five `MediaQuery` vs `LayoutBuilder` distinction points.
- Section 4: Full prose covering all five `GridView.builder` delegate parameters.
- Section 5: Full prose covering all five `BottomNavigationBar` points.
- Section 6: Full prose covering all four skeleton card points.
- Section 7: Full prose covering all five Member 2 and Member 3 handoff notes.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `withOpacity` deprecation (use `withValues(alpha:)` if flagged), `FilterChip.selectedColor` vs `labelStyle` color conflict, `_PlaceholderProductCard` unused `index` parameter warning (suppress with `// ignore: unused_field` if needed or simply use `index` in a `Key` assignment), missing `const` on `SizedBox` separators.

2. **Verify `BuyerHomeScreen` is `StatefulWidget`**
   ```
   grep 'class BuyerHomeScreen extends StatefulWidget' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line.

3. **Verify `BottomNavigationBar` has three items**
   ```
   grep -c 'BottomNavigationBarItem' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return `3`.

4. **Verify `_buildCategoryChips` uses spread operator**
   ```
   grep '\.\.\.AppConstants\.productCategories' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line — confirming `'All'` is prepended via spread.

5. **Verify `LayoutBuilder` is present in `artisan_home_screen.dart`**
   ```
   grep 'LayoutBuilder' lib/screens/artisan/artisan_home_screen.dart
   ```
   Must return at least one line.

6. **Verify 600dp breakpoint is used in both files**
   ```
   grep '600' lib/screens/buyer/buyer_home_screen.dart
   grep '600' lib/screens/artisan/artisan_home_screen.dart
   ```
   Each must return at least one line — confirming the breakpoint constant is applied.

7. **Verify `_PlaceholderProductCard` is private**
   ```
   grep 'class _PlaceholderProductCard' lib/screens/buyer/buyer_home_screen.dart
   ```
   Must return one line with the underscore prefix.

8. **Verify document exists and has 7 sections**
   ```
   cat docs/PR17_Responsive_Layout.md
   ```
   Confirm all 7 sections are present. Confirm Section 2 contains the breakpoint table. Confirm Section 7 contains handoff notes for Member 2 and Member 3.

9. **Hot reload on emulator — BuyerHomeScreen test**
   ```
   flutter run
   ```
   Log in as a buyer (or temporarily force `BuyerHomeScreen` in `RoleRouterScreen`).
   Confirm:
   - `BuyerHomeScreen` renders with "Discover" app bar and sign-out icon.
   - Search bar is visible below the app bar with search icon prefix.
   - Typing in the search bar shows the clear (X) icon; clearing it hides the X.
   - Category chips row shows "All", "Pottery", "Textiles", "Jewellery", "Woodwork", "Paintings", "Leather", "Other" — 8 chips total.
   - Tapping a chip selects it (primary colour) and deselects the previous chip.
   - Product grid shows 6 skeleton placeholder cards with grey image area and grey title/price bars.
   - On a phone-width emulator: 2 columns in the grid.
   - `BottomNavigationBar` shows Home, Cart, Orders tabs. Tapping tabs updates the selected tab indicator.
   - Sign-out button functions correctly.
   Press `q` to quit.

10. **Hot reload on emulator — ArtisanHomeScreen responsive test**

    Log in as an approved artisan (or temporarily force `ArtisanHomeScreen`).
    Confirm:
    - On portrait phone width: two `_NavCard` widgets stack vertically.
    - Rotate the emulator to landscape (or resize to >= 600dp width): two `_NavCard` widgets appear side by side.
    - Both cards remain tappable and navigate correctly in both orientations.

11. **Verify only the correct files were modified**
    ```
    git diff --name-only
    ```
    Expected: `lib/screens/buyer/buyer_home_screen.dart`, `lib/screens/artisan/artisan_home_screen.dart`, `docs/PR17_Responsive_Layout.md`.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 17
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
git commit -m "PR17: Responsive Layout — BuyerHomeScreen Shell + ArtisanHomeScreen Layout"
git push origin pr17-responsive-layout
```

---

## Section 9 – Acceptance Criteria

- [ ] `BuyerHomeScreen` is a `StatefulWidget` with `_searchController`, `_selectedCategory`, and `_currentNavIndex` fields.
- [ ] `_buildSearchBar()` renders a `TextField` with search prefix icon and conditional clear suffix icon that appears when text is non-empty.
- [ ] `_buildCategoryChips()` renders 8 `FilterChip` widgets — "All" plus all 7 `AppConstants.productCategories` — in a horizontal `ListView`.
- [ ] Tapping a category chip updates `_selectedCategory` and visually selects the chip with primary colour.
- [ ] `_buildProductGrid()` uses `MediaQuery` to set `crossAxisCount` to 2 (< 600dp) or 3 (≥ 600dp) and renders 6 `_PlaceholderProductCard` skeleton items.
- [ ] `BuyerHomeScreen` has a `BottomNavigationBar` with exactly 3 items — Home, Cart, Orders — with `currentIndex` bound to `_currentNavIndex`.
- [ ] `ArtisanHomeScreen` uses `LayoutBuilder` to render nav cards in a `Column` (< 600dp) or side-by-side `Row` with `Expanded` (≥ 600dp).
- [ ] `docs/PR17_Responsive_Layout.md` exists with all 7 sections including the breakpoint table and Member 2/3 handoff notes.
- [ ] No new files were created and no files outside the three modified files were changed.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR17 for CraftBridge — my final PR as Member 1. I implemented the `BuyerHomeScreen` shell with a responsive product grid, search bar, and category chips, updated `ArtisanHomeScreen` with a `LayoutBuilder`-driven responsive card layout, and produced the responsive layout reference document for Member 2 and Member 3."

2. **`BuyerHomeScreen` as `StatefulWidget`:** "`BuyerHomeScreen` is `StatefulWidget` because it owns three pieces of local UI state — `_searchController` for the search input, `_selectedCategory` for the active chip, and `_currentNavIndex` for the bottom nav tab. None of these are business state — they don't go into a Provider. They're pure UI state owned by the screen."

3. **Category chips with spread operator:** "The chips list is built as `['All', ...AppConstants.productCategories]` — the spread operator inserts all 7 category strings from `AppConstants` after the 'All' entry, giving 8 chips total. `FilterChip` is used rather than `Chip` because it has built-in `selected` and `onSelected` semantics. `showCheckmark: false` prevents the default checkmark from cluttering the chip label."

4. **`_buildProductGrid()` with `MediaQuery`:** "`GridView.builder` with `SliverGridDelegateWithFixedCrossAxisCount` is the required grid pattern for CraftBridge. The `crossAxisCount` is determined by `MediaQuery.of(context).size.width` — 2 columns below 600dp, 3 columns at 600dp and above. `childAspectRatio: 0.75` gives each card a 3:4 portrait ratio — enough vertical space for a product image and a title line."

5. **`_PlaceholderProductCard` skeleton design:** "The placeholder card uses grey rectangles to simulate the shape of a real product card — a tall grey image area at the top and two short grey bars for title and price below. This is the skeleton screen pattern. It's better UX than a spinner because it tells the user what kind of content is coming and how many items to expect. The grey tones come from `colorScheme.primary.withOpacity(0.08)` and `colorScheme.onSurface.withOpacity(0.10)` — no hardcoded colours."

6. **`BottomNavigationBar` shell:** "The `BottomNavigationBar` has three tabs — Home, Cart, Orders. In this PR, tapping a tab only updates `_currentNavIndex` — the actual screen content doesn't change yet. The full implementation with `IndexedStack`, `CartScreen`, `BuyerOrdersScreen`, and a cart badge count comes in PR45. Building the shell now means Member 2 and Member 3 inherit the correct structure to fill in."

7. **`LayoutBuilder` in `ArtisanHomeScreen`:** "The `_NavCard` responsive switch uses `LayoutBuilder` rather than `MediaQuery` because the cards live inside a `Padding` widget — the available drawing area is narrower than the full screen. `LayoutBuilder` gives `constraints.maxWidth` — the actual available width — so the 600dp threshold applies to drawable space, not screen space. When width >= 600dp, the two cards are placed side by side in a `Row` with `Expanded` children. Below 600dp, they stack in a `Column`."

8. **`MediaQuery` vs `LayoutBuilder` rule of thumb:** "The reference document's Section 3 codifies the decision rule: use `MediaQuery` for grid column count decisions where the grid is full-width, use `LayoutBuilder` for column/row layout switches where the widget is inside a padded container. This rule is what Member 2 and Member 3 should follow for every grid and layout screen in PRs 18–51."

9. **Member handoff significance:** "PR17 is the last PR I own as Member 1. After this merges, Member 2 picks up at PR18 and Member 3 at PR35. The `docs/PR17_Responsive_Layout.md` document is a direct handoff note — Section 7 explicitly tells Member 2 which files to modify and what to preserve, and tells Member 3 which patterns to follow. This is the documentation-first philosophy of the project in action."

10. **What's Next:** "PR18 — owned by Member 2 — will implement `ManageProductsScreen` with a live `GridView` of `ProductCard` widgets, a FAB for adding products, swipe-to-delete, and an empty state, beginning the core artisan product management flow."