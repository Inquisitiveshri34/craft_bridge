# PR13 – Widget Tree + Reactive UI — LoginScreen + RegistrationScreen Shells

**Project:** CraftBridge
**PR Number:** 13 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Implement `LoginScreen` and `RegistrationScreen` shells — full widget tree, form structure, role selector, and `AuthProvider` wiring without validation logic.

---

## Section 2 – Assignments Covered

- Assignment 3.13 — Widget Tree + Reactive UI — LoginScreen + RegistrationScreen Shells

---

## Section 3 – Objective

This PR builds the complete widget trees for `LoginScreen` and `RegistrationScreen` — every field, every layout element, and every `AuthProvider` connection — as non-validating shells. The forms are fully rendered and interactive but do not yet perform input validation or show field-level error messages; those are added in PR14. The role selector on `RegistrationScreen` is fully functional — tapping "I am an Artisan" reveals the bio field and tapping "I am a Buyer" hides it. `AuthProvider` tap handlers are wired so button taps call the correct provider methods, but error display and loading state handling are minimal in this PR and completed in PR14.

---

## Section 4 – Architecture Context

```
RoleRouterScreen
    │
    └── currentUser == null → LoginScreen
                                    │
                              "Don't have an account?" → RegistrationScreen
                                                                │
                                                    "Already have an account?" → LoginScreen

LoginScreen
  └── Scaffold → SingleChildScrollView → Padding → Column
        ├── app logo + app name
        ├── "Welcome back" subtitle
        ├── CustomTextField (email)
        ├── CustomTextField (password, obscured)
        ├── CustomButton ("Log In") → AuthProvider.signIn()
        ├── error text (AuthProvider.errorMessage)
        └── TextButton → RegistrationScreen

RegistrationScreen (StatefulWidget — owns role + bio visibility state)
  └── Scaffold → SingleChildScrollView → Padding → Column
        ├── "Create Account" title
        ├── CustomTextField (display name)
        ├── CustomTextField (email)
        ├── CustomTextField (password)
        ├── CustomTextField (confirm password)
        ├── role selector (two tappable role cards)
        │     ├── "I am an Artisan" card → selectedRole = 'artisan', showBio = true
        │     └── "I am a Buyer" card   → selectedRole = 'buyer',   showBio = false
        ├── CustomTextField (bio) — visible only when selectedRole == 'artisan'
        ├── CustomButton ("Create Account") → AuthProvider.signUp()
        ├── error text (AuthProvider.errorMessage)
        └── TextButton → LoginScreen
```

This PR sits after `RoleRouterScreen` (PR12) and before full form validation (PR14). The screens are navigable and connected to `AuthProvider` — a user can attempt sign-in and sign-up and the `AuthProvider` methods will be called — but field-level validation errors are not yet shown. The `CustomTextField` and `CustomButton` widgets from PR09 are used throughout.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist.

**Allowed file modification:**
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/registration_screen.dart`

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
- Do NOT modify any provider files.
- Do NOT modify `pubspec.yaml`.

---

## Section 6 – Technical Requirements

---

### `lib/screens/auth/login_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `LoginScreen` and `_LoginScreenState`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/widgets/custom_text_field.dart`
- `package:craft_bridge/widgets/custom_button.dart`
- `package:craft_bridge/screens/auth/registration_screen.dart`

---

**`LoginScreen` class:**
```dart
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
```

---

**`_LoginScreenState` fields:**
```dart
final _formKey = GlobalKey<FormState>();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
bool _obscurePassword = true;
```

---

**`dispose()` method:**
```dart
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```

---

**`_handleSignIn()` method:**
```dart
Future<void> _handleSignIn() async {
  final authProvider = context.read<AuthProvider>();
  await authProvider.signIn(
    _emailController.text,
    _passwordController.text,
  );
}
```

---

**`build()` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- No `AppBar`
- `body`: `SafeArea` wrapping `SingleChildScrollView` wrapping `Padding` with `padding: const EdgeInsets.all(AppConstants.defaultPadding)` wrapping a `Form` with `key: _formKey` wrapping a `Column` with `crossAxisAlignment: CrossAxisAlignment.stretch` and `children`:

  1. `const SizedBox(height: 48)`
  2. `Center` child: `Icon(Icons.shopping_bag_outlined, size: 64, color: Theme.of(context).colorScheme.primary)`
  3. `const SizedBox(height: 16)`
  4. `Center` child: `Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary))`
  5. `const SizedBox(height: 8)`
  6. `Center` child: `Text('Welcome back', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
  7. `const SizedBox(height: 40)`
  8. `CustomTextField(label: 'Email', hint: 'Enter your email', controller: _emailController, keyboardType: TextInputType.emailAddress, textCapitalization: TextCapitalization.none)`
  9. `const SizedBox(height: 16)`
  10. `CustomTextField(label: 'Password', hint: 'Enter your password', controller: _passwordController, obscureText: _obscurePassword, suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))`
  11. `const SizedBox(height: 8)`
  12. `Consumer<AuthProvider>` — reads `authProvider.errorMessage` — if non-null renders: `Padding(padding: const EdgeInsets.only(top: 8), child: Text(authProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)))`
  13. `const SizedBox(height: 24)`
  14. `Consumer<AuthProvider>` — reads `authProvider.isLoading` — renders: `CustomButton(label: 'Log In', onPressed: authProvider.isLoading ? null : _handleSignIn, isLoading: authProvider.isLoading)`
  15. `const SizedBox(height: 16)`
  16. `Center` child: `TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())), child: const Text("Don't have an account? Register"))`

---

### `lib/screens/auth/registration_screen.dart`

**Widget type:** `StatefulWidget`

**Class names:** `RegistrationScreen` and `_RegistrationScreenState`

**Imports:**
- `package:flutter/material.dart`
- `package:provider/provider.dart`
- `package:craft_bridge/providers/auth_provider.dart`
- `package:craft_bridge/core/constants/app_constants.dart`
- `package:craft_bridge/widgets/custom_text_field.dart`
- `package:craft_bridge/widgets/custom_button.dart`

---

**`RegistrationScreen` class:**
```dart
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}
```

---

**`_RegistrationScreenState` fields:**
```dart
final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();
final _bioController = TextEditingController();
bool _obscurePassword = true;
bool _obscureConfirmPassword = true;
String _selectedRole = AppConstants.roleBuyer;
```

---

**`dispose()` method:**
```dart
@override
void dispose() {
  _nameController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  _bioController.dispose();
  super.dispose();
}
```

---

**`_handleSignUp()` method:**
```dart
Future<void> _handleSignUp() async {
  final authProvider = context.read<AuthProvider>();
  await authProvider.signUp(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
    role: _selectedRole,
    bio: _bioController.text,
  );
}
```

---

**`_buildRoleCard()` method:**
```dart
Widget _buildRoleCard({
  required String role,
  required String title,
  required String subtitle,
  required IconData icon,
}) {
  final bool isSelected = _selectedRole == role;
  return GestureDetector(
    onTap: () => setState(() => _selectedRole = role),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    ),
  );
}
```

---

**`build()` method:**

Returns a `Scaffold` with:
- `backgroundColor`: `Theme.of(context).colorScheme.surface`
- `appBar`: `AppBar` with `title: const Text('Create Account')`, `backgroundColor: Colors.transparent`, `elevation: 0`, `foregroundColor: Theme.of(context).colorScheme.onSurface`
- `body`: `SafeArea` wrapping `SingleChildScrollView` wrapping `Padding` with `padding: const EdgeInsets.all(AppConstants.defaultPadding)` wrapping a `Form` with `key: _formKey` wrapping a `Column` with `crossAxisAlignment: CrossAxisAlignment.stretch` and `children`:

  1. `Text('Join CraftBridge', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))`
  2. `const SizedBox(height: 4)`
  3. `Text('Create your account to get started', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))`
  4. `const SizedBox(height: 32)`
  5. `CustomTextField(label: 'Display Name', hint: 'Your full name', controller: _nameController, textCapitalization: TextCapitalization.words)`
  6. `const SizedBox(height: 16)`
  7. `CustomTextField(label: 'Email', hint: 'Enter your email', controller: _emailController, keyboardType: TextInputType.emailAddress, textCapitalization: TextCapitalization.none)`
  8. `const SizedBox(height: 16)`
  9. `CustomTextField(label: 'Password', hint: 'Min. 6 characters', controller: _passwordController, obscureText: _obscurePassword, suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)))`
  10. `const SizedBox(height: 16)`
  11. `CustomTextField(label: 'Confirm Password', hint: 'Re-enter your password', controller: _confirmPasswordController, obscureText: _obscureConfirmPassword, suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)))`
  12. `const SizedBox(height: 24)`
  13. `Text('I am a...', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))`
  14. `const SizedBox(height: 12)`
  15. `_buildRoleCard(role: AppConstants.roleArtisan, title: 'Artisan', subtitle: 'I create and sell handcrafted products', icon: Icons.brush_outlined)`
  16. `const SizedBox(height: 12)`
  17. `_buildRoleCard(role: AppConstants.roleBuyer, title: 'Buyer', subtitle: 'I want to discover and buy handcrafted goods', icon: Icons.shopping_bag_outlined)`
  18. `if (_selectedRole == AppConstants.roleArtisan) ...` → `[const SizedBox(height: 16), CustomTextField(label: 'Bio', hint: 'Tell buyers about yourself and your craft', controller: _bioController, maxLines: 3, textCapitalization: TextCapitalization.sentences)]`
  19. `const SizedBox(height: 24)`
  20. `Consumer<AuthProvider>` — reads `authProvider.errorMessage` — if non-null renders: `Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(authProvider.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)))`
  21. `Consumer<AuthProvider>` — reads `authProvider.isLoading` — renders: `CustomButton(label: 'Create Account', onPressed: authProvider.isLoading ? null : _handleSignUp, isLoading: authProvider.isLoading)`
  22. `const SizedBox(height: 16)`
  23. `Center` child: `TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Log In'))`
  24. `const SizedBox(height: 24)`

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `lib/screens/auth/login_screen.dart` | Full `LoginScreen` shell — email/password fields, password toggle, `AuthProvider` wiring, navigation to `RegistrationScreen` |
| 2 | `lib/screens/auth/registration_screen.dart` | Full `RegistrationScreen` shell — all fields, animated role selector cards with bio field visibility toggle, `AuthProvider` wiring |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR12 is merged to main**

Open your GitHub repository and confirm the `pr12-role-router` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR13 branch**
```
git checkout -b pr13-auth-shells
```

**Step 4 — Confirm `login_screen.dart` is the PR12 minimal stub**
```
cat lib/screens/auth/login_screen.dart
```
Must show the PR12 stub — `StatelessWidget` with `Text('LoginScreen — implemented in PR13')`.

**Step 5 — Confirm `registration_screen.dart` is the PR01 placeholder**
```
cat lib/screens/auth/registration_screen.dart
```
Must show: `// RegistrationScreen — implemented in PR13`

**Step 6 — Confirm `CustomTextField` and `CustomButton` are implemented**
```
grep 'class CustomTextField' lib/widgets/custom_text_field.dart
grep 'class CustomButton' lib/widgets/custom_button.dart
```
Both must return their class declaration lines. If either still shows a placeholder comment, do not proceed.

---

Manual setup for this PR is now complete.
Open `docs/PR13_LoginScreen_RegistrationScreen_Shells.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must implement exactly two files.

---

**File 1: `lib/screens/auth/login_screen.dart`**

Replace the PR12 stub entirely. Write the complete file as specified in Section 6:

1. All import statements.
2. `LoginScreen extends StatefulWidget` with `const` constructor.
3. `_LoginScreenState` with:
   - Four fields: `_formKey`, `_emailController`, `_passwordController`, `_obscurePassword`.
   - `dispose()` disposing both controllers.
   - `_handleSignIn()` calling `context.read<AuthProvider>().signIn()`.
   - `build()` returning the full `Scaffold` with `SingleChildScrollView` > `Padding` > `Form` > `Column` with all 16 children in the exact order specified.

**Critical implementation rules for `LoginScreen`:**
- The `Form` widget wraps the entire `Column` — its `key` is `_formKey`. This is required even though validation is not wired in this PR — the `Form` must be in place for PR14 to add validators without restructuring the tree.
- Both `Consumer<AuthProvider>` widgets — for `errorMessage` and for `isLoading` — must be present as specified. The error `Consumer` renders nothing when `errorMessage` is null. The loading `Consumer` always renders the `CustomButton`.
- The password visibility `suffixIcon` uses `setState(() => _obscurePassword = !_obscurePassword)`. This is local state — it does not touch `AuthProvider`.
- `_handleSignIn()` uses `context.read<AuthProvider>()` not `context.watch` — it is called from a button tap, not from `build`.
- Navigation to `RegistrationScreen` uses `Navigator.push` — not `pushReplacement` — so the user can navigate back to `LoginScreen`.

---

**File 2: `lib/screens/auth/registration_screen.dart`**

Replace the PR01 placeholder entirely. Write the complete file as specified in Section 6:

1. All import statements — note: `RegistrationScreen` does NOT import `login_screen.dart` because navigation back uses `Navigator.pop(context)`.
2. `RegistrationScreen extends StatefulWidget` with `const` constructor.
3. `_RegistrationScreenState` with:
   - Nine fields: `_formKey`, five controllers, two obscure booleans, `_selectedRole` defaulting to `AppConstants.roleBuyer`.
   - `dispose()` disposing all five controllers.
   - `_handleSignUp()` calling `context.read<AuthProvider>().signUp()` with all named parameters.
   - `_buildRoleCard()` helper method with the `AnimatedContainer` card layout exactly as specified.
   - `build()` returning the full `Scaffold` with transparent `AppBar`, `SingleChildScrollView` > `Padding` > `Form` > `Column` with all 24 children in the exact order specified.

**Critical implementation rules for `RegistrationScreen`:**
- `_selectedRole` defaults to `AppConstants.roleBuyer` — buyer is the pre-selected role on load.
- The bio field uses a Dart collection `if` inside the `children` list: `if (_selectedRole == AppConstants.roleArtisan) ...[const SizedBox(height: 16), CustomTextField(...)]`. This is a spread of a list guarded by a conditional — the bio field and its preceding `SizedBox` both appear and disappear together.
- The `AppBar` has `backgroundColor: Colors.transparent` and `elevation: 0` so it blends with the screen background. `foregroundColor` is set to `onSurface` so the default back arrow is visible.
- `_buildRoleCard` uses `AnimatedContainer` with `duration: const Duration(milliseconds: 200)` — the selection state change animates smoothly.
- Back navigation uses `Navigator.pop(context)` — not `Navigator.push(LoginScreen)` — to return to `LoginScreen` correctly.
- The `Form` widget wraps the entire `Column` — its `key` is `_formKey`. Present for PR14 to wire validators.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: `AnimatedContainer` decoration with both `color` and `decoration` set simultaneously (use only `decoration` with `BoxDecoration`), `withOpacity` deprecation in newer Flutter versions (use `withValues(alpha:)` if analyzer flags it), missing `Form` widget wrapping the `Column`.

2. **Verify `Form` widget is present in both screens**
   ```
   grep -c 'GlobalKey<FormState>' lib/screens/auth/login_screen.dart
   grep -c 'GlobalKey<FormState>' lib/screens/auth/registration_screen.dart
   ```
   Both must return `1`.

3. **Verify role selector uses `AppConstants`**
   ```
   grep 'AppConstants.role' lib/screens/auth/registration_screen.dart
   ```
   Must return at least three lines — `roleBuyer` default, `roleArtisan` card call, `roleBuyer` card call.

4. **Verify bio field conditional rendering**
   ```
   grep 'roleArtisan' lib/screens/auth/registration_screen.dart
   ```
   Must return lines confirming the conditional `if (_selectedRole == AppConstants.roleArtisan)` is present.

5. **Verify both `Consumer<AuthProvider>` widgets are present in `LoginScreen`**
   ```
   grep -c 'Consumer<AuthProvider>' lib/screens/auth/login_screen.dart
   ```
   Must return `2` — one for `errorMessage`, one for `isLoading`.

6. **Verify both `Consumer<AuthProvider>` widgets are present in `RegistrationScreen`**
   ```
   grep -c 'Consumer<AuthProvider>' lib/screens/auth/registration_screen.dart
   ```
   Must return `2`.

7. **Verify controller disposal**
   ```
   grep -c 'dispose()' lib/screens/auth/login_screen.dart
   grep -c 'dispose()' lib/screens/auth/registration_screen.dart
   ```
   `LoginScreen` must return at least `3` (two controller `.dispose()` calls + override). `RegistrationScreen` must return at least `6` (five controller `.dispose()` calls + override).

8. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - App launches, splash screen appears, then `LoginScreen` is shown.
   - `LoginScreen` renders: shopping bag icon, "CraftBridge" heading, "Welcome back" subtitle, email field, password field with visibility toggle, "Log In" button, "Don't have an account? Register" text button.
   - Tapping the visibility icon toggles the password field between obscured and visible.
   - Tapping "Don't have an account? Register" navigates to `RegistrationScreen`.
   - `RegistrationScreen` renders: transparent app bar with back button, "Join CraftBridge" heading, all four input fields, role selector with two cards (Buyer pre-selected), "Create Account" button, "Already have an account? Log In" text button.
   - Tapping the Artisan role card shows the bio field; tapping Buyer hides it.
   - Tapping the back button or "Already have an account?" returns to `LoginScreen`.
   - No errors in debug console.
   Press `q` to quit.

9. **Verify only the correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/screens/auth/login_screen.dart` and `lib/screens/auth/registration_screen.dart` should appear.

10. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 13
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
git commit -m "PR13: Widget Tree + Reactive UI — LoginScreen + RegistrationScreen Shells"
git push origin pr13-auth-shells
```

---

## Section 9 – Acceptance Criteria

- [ ] `LoginScreen` is a `StatefulWidget` with `_emailController`, `_passwordController`, `_formKey`, and `_obscurePassword` field.
- [ ] `LoginScreen` renders: app icon, app name, "Welcome back" subtitle, email `CustomTextField`, password `CustomTextField` with visibility toggle, "Log In" `CustomButton`, error text consumer, and "Don't have an account?" `TextButton`.
- [ ] `LoginScreen._handleSignIn()` calls `context.read<AuthProvider>().signIn()` with email and password controller text.
- [ ] `RegistrationScreen` is a `StatefulWidget` with five `TextEditingController` fields, `_selectedRole` defaulting to `AppConstants.roleBuyer`, and two obscure password booleans.
- [ ] `RegistrationScreen` renders: display name, email, password, confirm password `CustomTextField` widgets, animated role selector with Artisan and Buyer cards, bio `CustomTextField` visible only when `_selectedRole == AppConstants.roleArtisan`.
- [ ] `_buildRoleCard()` uses `AnimatedContainer` with 200ms duration, border and background color change on selection, and a checkmark icon when selected.
- [ ] `RegistrationScreen._handleSignUp()` calls `context.read<AuthProvider>().signUp()` with all five named parameters.
- [ ] Both screens wrap their column in a `Form` widget with a `GlobalKey<FormState>` — ready for PR14 validators.
- [ ] Both screens dispose all `TextEditingController` instances in `dispose()`.
- [ ] Both screens show `AuthProvider.errorMessage` via `Consumer<AuthProvider>` and pass `AuthProvider.isLoading` to `CustomButton`.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR13 for CraftBridge. I implemented the `LoginScreen` and `RegistrationScreen` shells — the complete widget trees, all form fields, the animated role selector, and full `AuthProvider` wiring — as non-validating shells that PR14 will complete with input validation."

2. **Why shells first, validation second:** "Building the widget tree and the Provider wiring first — before validation — is a deliberate sequencing choice. It means PR13 can be verified visually on the emulator: every element renders, every navigation works, every role card animates. PR14 then adds validators to an already-correct widget tree without restructuring it. Splitting the work this way makes each PR's diff smaller and each verification step more focused."

3. **`Form` widget placement strategy:** "Both screens wrap their `Column` in a `Form` widget with a `GlobalKey<FormState>`. The form does nothing in PR13 — there are no validators yet. But the `Form` must be structurally in place now so that PR14 can add `validator` callbacks to each `CustomTextField` without moving widgets. The `_formKey.currentState!.validate()` call in PR14 requires this exact structure."

4. **`LoginScreen` `StatefulWidget` justification:** "`LoginScreen` is a `StatefulWidget` because it owns `_obscurePassword` — the toggle state for the password visibility icon. `AuthProvider` state is observed via `Consumer`, not stored locally. The three controllers are also owned here because `TextEditingController` is a lifecycle object that must be disposed."

5. **`Consumer<AuthProvider>` vs `context.watch`:** "Both screens use `Consumer<AuthProvider>` for `errorMessage` and `isLoading` rather than calling `context.watch<AuthProvider>()` at the top of `build`. The `Consumer` pattern limits rebuilds to exactly the widgets that need to react — the error text and the button. Using `context.watch` at the top of `build` would rebuild the entire screen — all the `TextFormField` widgets, the role cards, the whole column — every time `isLoading` toggles."

6. **`_buildRoleCard` with `AnimatedContainer`:** "The role selector is built with `AnimatedContainer` rather than a plain `Container`. When `_selectedRole` changes via `setState`, Flutter automatically interpolates between the unselected and selected visual states — the border color, the border width, the background tint — over 200 milliseconds. This gives the selection a polished feel with zero animation code beyond the `duration` parameter."

7. **Bio field conditional rendering:** "The bio `CustomTextField` and its preceding `SizedBox` are conditionally included in the `Column` children using Dart's collection `if` with a spread operator: `if (_selectedRole == AppConstants.roleArtisan) ...[SizedBox, CustomTextField]`. This is idiomatic Flutter for conditional children — the list is rebuilt on every `setState` call, so the bio field appears and disappears as the role selection changes."

8. **Navigation pattern — `push` vs `pop`:** "`LoginScreen` uses `Navigator.push` to go to `RegistrationScreen` — because the user should be able to go back. `RegistrationScreen` uses `Navigator.pop` to go back to `LoginScreen` — not `Navigator.push(LoginScreen)`. Pushing `LoginScreen` again would create a new instance on the stack, which means tapping 'back' from the new login screen would return to registration. `pop` returns to the existing instance correctly."

9. **Emulator demonstration:** "On the emulator, `LoginScreen` shows the full form layout. Tapping the eye icon toggles the password field. Tapping 'Register' slides to `RegistrationScreen`. Tapping the Artisan card animates it to the selected state and reveals the bio field below. Tapping Buyer hides the bio field. At this point, tapping 'Log In' or 'Create Account' will call `AuthProvider` — it won't validate fields yet, but if valid credentials were entered, it would actually sign in."

10. **What's Next:** "PR14 will add full form validation to both screens — email format checking, password length enforcement, confirm password matching, display name requirement — and wire the `_formKey.currentState!.validate()` call to the button handlers."