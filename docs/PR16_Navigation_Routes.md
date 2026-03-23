# PR16 – Navigator + Routes — Full Navigation Wired

**Project:** CraftBridge
**PR Number:** 16 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Complete `ArtisanHomeScreen` shell with navigation cards to `ManageProductsScreen` and `ArtisanOrdersScreen`, and complete `AdminHomeScreen` shell with navigation cards to `ManageUsersScreen` and `ManageAllOrdersScreen`.

---

## Section 2 – Assignments Covered

- Assignment 3.16 — Navigator + Routes — Full Navigation Wired

---

## Section 3 – Objective

This PR implements the navigation layer for the artisan and admin roles — giving both home screens their full layout and navigation cards so that every role-based route from `RoleRouterScreen` leads to a functional, navigable screen rather than a stub text. `ArtisanHomeScreen` displays a personalised welcome and two large navigation cards for product management and order tracking. `AdminHomeScreen` displays two navigation cards for user management and platform-wide order monitoring. Minimal stubs are created for all downstream navigation targets that do not yet have implementations, ensuring the full navigation graph is walkable end-to-end on the emulator after this PR.

---

## Section 4 – Architecture Context

```
RoleRouterScreen
    ├── role == admin   → AdminHomeScreen (this PR)
    │                         ├── "Manage Users"  → ManageUsersScreen stub
    │                         └── "All Orders"    → ManageAllOrdersScreen stub
    │
    └── role == artisan + approved → ArtisanHomeScreen (this PR)
                                          ├── "My Products" → ManageProductsScreen stub
                                          └── "My Orders"   → ArtisanOrdersScreen stub

Navigation pattern used in both home screens:
  Navigator.push(context, MaterialPageRoute(builder: (_) => const TargetScreen()))

AuthProvider consumed in ArtisanHomeScreen:
  context.watch<AuthProvider>().currentUser?.displayName → welcome message

Files modified this PR:
  lib/screens/artisan/artisan_home_screen.dart     ← full implementation
  lib/screens/admin/admin_home_screen.dart         ← full implementation
  lib/screens/artisan/manage_products_screen.dart  ← minimal stub upgrade
  lib/screens/artisan/artisan_orders_screen.dart   ← minimal stub upgrade
  lib/screens/admin/manage_users_screen.dart       ← minimal stub upgrade
  lib/screens/admin/manage_all_orders_screen.dart  ← minimal stub upgrade
```

This PR sits after session persistence (PR15) and before `BuyerHomeScreen` shell (PR17). After this PR, all three role-based home screens have at least a navigable shell — `BuyerHomeScreen` from PR12 is already a stub and is completed in PR17. The navigation stubs created here are replaced by their full implementations in PRs 18, 30, 48.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/artisan/artisan_home_screen.dart`
- `lib/screens/admin/admin_home_screen.dart`
- `lib/screens/artisan/manage_products_screen.dart`
- `lib/screens/artisan/artisan_orders_screen.dart`
- `lib/screens/admin/manage_users_screen.dart`
- `lib/screens/admin/manage_all_orders_screen.dart`

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `auth_provider.dart`.
- Do NOT modify `role_router_screen.dart` or `splash_screen.dart`.
- Do NOT modify any widget files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/artisan/artisan_home_screen.dart`

**Widget type:** `StatelessWidget`

**Class name:** `ArtisanHomeScreen`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/screens/artisan/manage_products_screen.dart`
- `package:craft_bridge/screens/artisan/artisan_orders_screen.dart`

**Constructor:** `const ArtisanHomeScreen({super.key})`

**`build` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- `appBar`: `AppBar` with:
  - `title: const Text('My Shop')`
  - `actions`: `[IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign Out', onPressed: () => context.read<AuthProvider>().signOut())]`
- `body`: `SafeArea` wrapping `SingleChildScrollView` wrapping `Padding` with `padding: const EdgeInsets.all(AppConstants.defaultPadding)` wrapping a `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:

  1. `Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
  2. `const SizedBox(height: 4)`
  3. `Text(context.watch<AuthProvider>().currentUser?.displayName ?? 'Artisan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))`
  4. `const SizedBox(height: 8)`
  5. `Text('Manage your shop and track orders below.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
  6. `const SizedBox(height: 32)`
  7. `_NavCard` widget call — My Products card (see `_NavCard` spec below)
  8. `const SizedBox(height: 16)`
  9. `_NavCard` widget call — My Orders card

---

**`_NavCard` private widget** — defined in the same file below `ArtisanHomeScreen`:

**Widget type:** `StatelessWidget`

**Class name:** `_NavCard` (private)

**Constructor parameters:**
- `required final String title`
- `required final String subtitle`
- `required final IconData icon`
- `required final VoidCallback onTap`
- `final Color? iconColor` — defaults to `null` (falls back to `colorScheme.primary`)

**`build` method returns:** `Card` with `child: InkWell` with `borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius)` and `onTap: onTap` and `child: Padding` with `padding: const EdgeInsets.all(20)` and `child: Row` with `children`:
1. `Container` with `width: 56`, `height: 56`, `decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12))` and `child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 28)`
2. `const SizedBox(width: 16)`
3. `Expanded` child: `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and children:
   - `Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))`
   - `const SizedBox(height: 4)`
   - `Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
4. `Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))`

---

**`_NavCard` calls in `ArtisanHomeScreen.build`:**

My Products card:
```dart
_NavCard(
  title: 'My Products',
  subtitle: 'Add, edit and manage your listings',
  icon: Icons.inventory_2_outlined,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ManageProductsScreen()),
  ),
)
```

My Orders card:
```dart
_NavCard(
  title: 'My Orders',
  subtitle: 'View and update incoming orders',
  icon: Icons.receipt_long_outlined,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ArtisanOrdersScreen()),
  ),
)
```

---

### `lib/screens/admin/admin_home_screen.dart`

**Widget type:** `StatelessWidget`

**Class name:** `AdminHomeScreen`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/screens/admin/manage_users_screen.dart`
- `package:craft_bridge/screens/admin/manage_all_orders_screen.dart`

**Constructor:** `const AdminHomeScreen({super.key})`

**`build` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- `appBar`: `AppBar` with:
  - `title: const Text('Admin Dashboard')`
  - `actions`: `[IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign Out', onPressed: () => context.read<AuthProvider>().signOut())]`
- `body`: `SafeArea` wrapping `SingleChildScrollView` wrapping `Padding` with `padding: const EdgeInsets.all(AppConstants.defaultPadding)` wrapping a `Column` with `crossAxisAlignment: CrossAxisAlignment.start` and `children`:

  1. `Text('Platform Overview', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))`
  2. `const SizedBox(height: 4)`
  3. `Text('Manage users and monitor all orders from here.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
  4. `const SizedBox(height: 32)`
  5. `_AdminNavCard` widget call — Manage Users card
  6. `const SizedBox(height: 16)`
  7. `_AdminNavCard` widget call — All Orders card

---

**`_AdminNavCard` private widget** — defined in the same file below `AdminHomeScreen`.

Identical structure to `_NavCard` in `artisan_home_screen.dart`. Declare it independently in `admin_home_screen.dart` — do NOT import or reference `_NavCard` from `artisan_home_screen.dart` (it is private). Same constructor parameters as `_NavCard`.

**`_AdminNavCard` calls in `AdminHomeScreen.build`:**

Manage Users card:
```dart
_AdminNavCard(
  title: 'Manage Users',
  subtitle: 'Review and approve artisan registrations',
  icon: Icons.people_outline,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
  ),
)
```

All Orders card:
```dart
_AdminNavCard(
  title: 'All Orders',
  subtitle: 'Monitor every order across the platform',
  icon: Icons.list_alt_outlined,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ManageAllOrdersScreen()),
  ),
)
```

---

### Minimal stubs — four files

Each of the following files receives the same minimal stub treatment. Replace the existing PR01 placeholder comment with a `StatelessWidget` stub:

**`lib/screens/artisan/manage_products_screen.dart`:**
```dart
import 'package:flutter/material.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Products')),
      body: const Center(
        child: Text('ManageProductsScreen — implemented in PR18'),
      ),
    );
  }
}
```

**`lib/screens/artisan/artisan_orders_screen.dart`:**
```dart
import 'package:flutter/material.dart';

class ArtisanOrdersScreen extends StatelessWidget {
  const ArtisanOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: const Center(
        child: Text('ArtisanOrdersScreen — implemented in PR30'),
      ),
    );
  }
}
```

**`lib/screens/admin/manage_users_screen.dart`:**
```dart
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: const Center(
        child: Text('ManageUsersScreen — implemented in PR48'),
      ),
    );
  }
}
```

**`lib/screens/admin/manage_all_orders_screen.dart`:**
```dart
import 'package:flutter/material.dart';

class ManageAllOrdersScreen extends StatelessWidget {
  const ManageAllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: const Center(
        child: Text('ManageAllOrdersScreen — implemented in PR48'),
      ),
    );
  }
}
```

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/artisan/artisan_home_screen.dart` | Full `ArtisanHomeScreen` with welcome text, two `_NavCard` navigation cards, sign-out action |
| 2 | `lib/screens/admin/admin_home_screen.dart` | Full `AdminHomeScreen` with platform overview heading, two `_AdminNavCard` navigation cards, sign-out action |
| 3 | `lib/screens/artisan/manage_products_screen.dart` | Minimal stub with `AppBar` titled "My Products" |
| 4 | `lib/screens/artisan/artisan_orders_screen.dart` | Minimal stub with `AppBar` titled "My Orders" |
| 5 | `lib/screens/admin/manage_users_screen.dart` | Minimal stub with `AppBar` titled "Manage Users" |
| 6 | `lib/screens/admin/manage_all_orders_screen.dart` | Minimal stub with `AppBar` titled "All Orders" |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR15 is merged to main**

Open your GitHub repository and confirm the `pr15-session-persistence` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR16 branch**
```
git checkout -b pr16-navigation-routes
```

**Step 4 — Confirm `artisan_home_screen.dart` is the PR12 minimal stub**
```
cat lib/screens/artisan/artisan_home_screen.dart
```
Must show the PR12 stub — `StatelessWidget` with `Text('ArtisanHomeScreen — implemented in PR16')`.

**Step 5 — Confirm `admin_home_screen.dart` is the PR12 minimal stub**
```
cat lib/screens/admin/admin_home_screen.dart
```
Must show the PR12 stub — `StatelessWidget` with `Text('AdminHomeScreen — implemented in PR48')`. Note: the stub said PR48 because the admin screen was originally planned for PR48 — PR16 now creates the shell. This is expected.

**Step 6 — Confirm the four downstream stub files are PR01 placeholders**
```
cat lib/screens/artisan/manage_products_screen.dart
cat lib/screens/artisan/artisan_orders_screen.dart
cat lib/screens/admin/manage_users_screen.dart
cat lib/screens/admin/manage_all_orders_screen.dart
```
All four must show their PR01 single-comment placeholder lines.

---

Manual setup for this PR is now complete.
Open `docs/PR16_Navigation_Routes.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must modify six files. No new files are created.

---

**File 1: `lib/screens/artisan/artisan_home_screen.dart`**

Replace the PR12 stub entirely. Write the complete file as specified in Section 6:

1. All import statements.
2. `class ArtisanHomeScreen extends StatelessWidget` with `const` constructor.
3. `build()` returning `Scaffold` with `AppBar` (title "My Shop", sign-out action), `SafeArea` > `SingleChildScrollView` > `Padding` > `Column` with all 9 children as specified, using `_NavCard` for the two navigation cards.
4. `class _NavCard extends StatelessWidget` defined below `ArtisanHomeScreen` with all 5 constructor parameters and the `Card` > `InkWell` > `Padding` > `Row` layout exactly as specified.

**Critical rules:**
- `context.watch<AuthProvider>()` is used for the welcome name — this is in `build`, appropriate for `watch`.
- `context.read<AuthProvider>().signOut()` is used in the `AppBar` action — this is in a callback, appropriate for `read`.
- `_NavCard` is private — underscore prefix. It must not be exported.
- Do not add a `const` constructor to `_NavCard` — `VoidCallback` and `Color?` parameters prevent const.

---

**File 2: `lib/screens/admin/admin_home_screen.dart`**

Replace the PR12 stub entirely. Write the complete file as specified in Section 6:

1. All import statements.
2. `class AdminHomeScreen extends StatelessWidget` with `const` constructor.
3. `build()` returning `Scaffold` with `AppBar` (title "Admin Dashboard", sign-out action), `SafeArea` > `SingleChildScrollView` > `Padding` > `Column` with all 7 children as specified.
4. `class _AdminNavCard extends StatelessWidget` defined below `AdminHomeScreen` — identical structure to `_NavCard` but declared independently in this file.

**Critical rules:**
- `_AdminNavCard` is a separate class from `_NavCard`. Do NOT import `artisan_home_screen.dart` to reuse `_NavCard`. The duplication is intentional — private widgets cannot be shared across files.
- Same `context.read<AuthProvider>().signOut()` pattern for the sign-out button.

---

**Files 3–6: Four minimal stubs**

For each of the four stub files, replace the PR01 placeholder comment with the `StatelessWidget` stub specified in Section 6. Each stub must have an `AppBar` with the correct title as specified.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues: `withOpacity` deprecation (use `withValues(alpha:)` if flagged), `_NavCard` constructor missing `super.key`, `const` incorrectly applied to `_NavCard` or `_AdminNavCard` constructor.

2. **Verify `_NavCard` is private and defined in `artisan_home_screen.dart`**
   ```
   grep 'class _NavCard' lib/screens/artisan/artisan_home_screen.dart
   ```
   Must return one line with the underscore prefix.

3. **Verify `_AdminNavCard` is private and defined in `admin_home_screen.dart`**
   ```
   grep 'class _AdminNavCard' lib/screens/admin/admin_home_screen.dart
   ```
   Must return one line with the underscore prefix.

4. **Verify sign-out actions are present in both home screens**
   ```
   grep 'signOut' lib/screens/artisan/artisan_home_screen.dart
   grep 'signOut' lib/screens/admin/admin_home_screen.dart
   ```
   Each must return one line.

5. **Verify `Navigator.push` is used for navigation cards**
   ```
   grep -c 'Navigator.push' lib/screens/artisan/artisan_home_screen.dart
   grep -c 'Navigator.push' lib/screens/admin/admin_home_screen.dart
   ```
   Each must return `2` — one for each navigation card.

6. **Verify four stub files have `AppBar` titles**
   ```
   grep 'AppBar' lib/screens/artisan/manage_products_screen.dart
   grep 'AppBar' lib/screens/artisan/artisan_orders_screen.dart
   grep 'AppBar' lib/screens/admin/manage_users_screen.dart
   grep 'AppBar' lib/screens/admin/manage_all_orders_screen.dart
   ```
   Each must return at least one line.

7. **Hot reload on emulator — artisan navigation test**
   ```
   flutter run
   ```
   To test the artisan flow, either:
   - Log in with an approved artisan account (if one was created during PR14 testing), or
   - Temporarily modify `RoleRouterScreen` to always return `ArtisanHomeScreen()` for testing purposes — then revert.

   Confirm:
   - `ArtisanHomeScreen` renders with "My Shop" app bar, welcome text, and two navigation cards ("My Products" and "My Orders").
   - Tapping "My Products" navigates to the `ManageProductsScreen` stub with "My Products" app bar and stub text.
   - Back button returns to `ArtisanHomeScreen`.
   - Tapping "My Orders" navigates to the `ArtisanOrdersScreen` stub.
   - Back button returns to `ArtisanHomeScreen`.
   - Sign-out button in app bar calls `AuthProvider.signOut()` and navigates to `LoginScreen`.

8. **Hot reload on emulator — admin navigation test**

   Log in with the admin account (role set to `'admin'` in Firestore) or temporarily force `AdminHomeScreen`:
   - `AdminHomeScreen` renders with "Admin Dashboard" app bar and two navigation cards.
   - Tapping "Manage Users" navigates to `ManageUsersScreen` stub.
   - Tapping "All Orders" navigates to `ManageAllOrdersScreen` stub.
   - Sign-out functions correctly.

9. **Verify modified files**
   ```
   git diff --name-only
   ```
   Expected: all six files listed in Section 5 Allowed file modification.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 16
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
git commit -m "PR16: Navigator + Routes — Full Navigation Wired"
git push origin pr16-navigation-routes
```

---

## Section 9 – Acceptance Criteria

- [ ] `ArtisanHomeScreen` is a `StatelessWidget` rendering a "My Shop" `AppBar`, personalised welcome using `AuthProvider.currentUser?.displayName`, and two `_NavCard` navigation cards for "My Products" and "My Orders".
- [ ] `AdminHomeScreen` is a `StatelessWidget` rendering an "Admin Dashboard" `AppBar` and two `_AdminNavCard` navigation cards for "Manage Users" and "All Orders".
- [ ] `_NavCard` is a private `StatelessWidget` defined in `artisan_home_screen.dart` with `Card` > `InkWell` > `Padding` > `Row` layout including icon container, title/subtitle column, and chevron.
- [ ] `_AdminNavCard` is a private `StatelessWidget` defined in `admin_home_screen.dart` with identical layout to `_NavCard`, declared independently.
- [ ] Both home screens have a sign-out `IconButton` in the `AppBar` that calls `context.read<AuthProvider>().signOut()`.
- [ ] All four downstream stub files (`ManageProductsScreen`, `ArtisanOrdersScreen`, `ManageUsersScreen`, `ManageAllOrdersScreen`) are `StatelessWidget` classes with correctly titled `AppBar` widgets.
- [ ] Tapping each navigation card on the emulator navigates to the correct stub screen.
- [ ] Back button from each stub screen returns to the correct home screen.
- [ ] Sign-out from either home screen triggers `AuthProvider.signOut()` and the app routes to `LoginScreen`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR16 for CraftBridge. I implemented the full navigation shells for `ArtisanHomeScreen` and `AdminHomeScreen` — giving both roles navigable home screens with `_NavCard` and `_AdminNavCard` components — and created minimal stubs for all four downstream screens so the complete navigation graph is walkable on the emulator."

2. **`StatelessWidget` choice for home screens:** "Both home screens are `StatelessWidget` because they own no local state. The artisan's display name comes from `context.watch<AuthProvider>()` — the provider is the state owner, not the screen. Navigation is done via `Navigator.push` callbacks in the card's `onTap`. No `StatefulWidget` is needed."

3. **`_NavCard` and `_AdminNavCard` private widget pattern:** "Both home screens define a private navigation card widget — `_NavCard` in the artisan file and `_AdminNavCard` in the admin file. They are structurally identical but declared separately. The underscore prefix makes them private to their file — they cannot be imported or referenced from other files. This is intentional: reusable-across-the-project widgets live in `lib/widgets/`, while widgets that are only meaningful within one screen live as private classes in that screen's file."

4. **`_NavCard` layout dissection:** "The card layout is `Card` > `InkWell` > `Padding` > `Row`. `Card` provides the elevation and rounded corners from `AppTheme.cardTheme`. `InkWell` provides the tap ripple effect — it must be inside the `Card`, not wrapping it, so the ripple is clipped to the card's rounded corners. The `Row` has three children: a circular icon container, an `Expanded` column with title and subtitle, and a right-facing chevron icon."

5. **`context.watch` vs `context.read` in `ArtisanHomeScreen`:** "`context.watch<AuthProvider>()` is used in the `build` method to read `currentUser?.displayName` — the welcome message should update if the user's name changes. `context.read<AuthProvider>().signOut()` is used in the `AppBar` action callback — a one-time call from a button tap doesn't need to rebuild the widget, so `read` is correct."

6. **Sign-out flow from home screens:** "The sign-out `IconButton` calls `context.read<AuthProvider>().signOut()`. This clears `_currentUser` in `AuthProvider` and calls `notifyListeners()`. `RoleRouterScreen`, which uses `context.watch<AuthProvider>()`, rebuilds and evaluates `currentUser == null`, returning `LoginScreen()`. The entire transition happens reactively — no explicit `Navigator` call needed from the home screen."

7. **Navigation stubs with `AppBar` titles:** "The four stub screens have `AppBar` widgets with correct titles — 'My Products', 'My Orders', 'Manage Users', 'All Orders'. This is important for the emulator demo: when a card is tapped, the screen title in the app bar confirms the correct stub was reached. The `AppBar` also provides a default back button, so returning to the home screen requires no additional navigation code."

8. **Navigator.push for card navigation:** "Each navigation card uses `Navigator.push` to navigate forward — not `pushReplacement`. This is correct because the user should be able to press back from `ManageProductsScreen` to return to `ArtisanHomeScreen`. `pushReplacement` is only used when the source screen should not be in the back stack — like `SplashScreen` and `RoleRouterScreen`."

9. **Emulator demonstration:** "On the emulator, logging in as an approved artisan lands on `ArtisanHomeScreen` with the personalised welcome and two cards. Tapping 'My Products' pushes the stub screen with the 'My Products' app bar. Back returns to home. Tapping the logout icon calls `signOut()` and the app transitions reactively to `LoginScreen`. The same walkthrough works for the admin role."

10. **What's Next:** "PR17 will implement the `BuyerHomeScreen` shell with a product grid placeholder and complete `ArtisanHomeScreen`'s responsive layout using `MediaQuery` — the last PR before the Member 1 handoff."