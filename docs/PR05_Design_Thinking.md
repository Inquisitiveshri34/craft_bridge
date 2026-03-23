# PR05 – Design Thinking — UI/UX Planning + Figma Reference

**Project:** CraftBridge
**PR Number:** 05 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Design thinking document covering user personas, user journeys, wireframe descriptions, and finalized color palette, with `app_theme.dart` updated to the final color scheme.

---

## Section 2 – Assignments Covered

- Assignment 3.5 — Design Thinking — UI/UX Planning + Figma Reference

---

## Section 3 – Objective

This PR produces the formal design thinking document for CraftBridge — defining the three user personas, mapping their end-to-end journeys through the app, describing wireframe layouts for every major screen, and establishing the finalized color palette that will govern the entire visual identity of the app. `app_theme.dart` is updated to replace the provisional PR03 color with the finalized seed color and surface overrides. This document becomes the visual and UX contract for all screen implementations in PRs 11 through 48, ensuring every teammate builds toward a consistent, intentional design.

---

## Section 4 – Architecture Context

```
docs/
  PR05_Design_Thinking.md         ← produced this PR

lib/
  core/
    theme/
      app_theme.dart              ← updated this PR (finalized color scheme)

No new screens. No Firebase interactions. No new dependencies.

Design system established this PR:
  Seed color:    #5C4033  (deep espresso brown)
  Surface:       #FFF8F5  (warm off-white)
  On-surface:    #1C1B1F  (near-black)
  Accent:        #A0522D  (sienna — artisan warmth)
  Error:         #BA1A1A  (Material 3 default error red)
```

This PR sits between Firebase setup (PR04) and High-Level Design (PR06). The design thinking work done here directly informs the HLD module layout in PR06 and the LLD widget decisions in PR07. `app_theme.dart` updated here is the final version of the light theme color scheme — PR19 completes the remaining theme tokens (typography scale, spacing), and PR46 adds the dark theme.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None. All files already exist as placeholders or implementations from previous PRs.

**Allowed file modification:**
- `lib/core/theme/app_theme.dart` — finalized color scheme replaces provisional PR03 colors
- `docs/Design_Thinking.md` — new document written to existing `docs/` directory

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new `.dart` files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify `app_constants.dart`.
- Do NOT modify `pubspec.yaml`.
- Do NOT modify any screen or widget placeholder files.

---

## Section 6 – Technical Requirements

### `lib/core/theme/app_theme.dart`

Update the `lightTheme` getter to replace the provisional `#6B4226` seed color with the finalized design system colors. The class structure does not change — only color values are updated.

**Updated `lightTheme` configuration:**

- `useMaterial3: true`
- `colorScheme`: `ColorScheme.fromSeed` with:
  - `seedColor: const Color(0xFF5C4033)`
  - `surface: const Color(0xFFFFF8F5)`
- `fontFamily: 'Roboto'`
- `appBarTheme`: `AppBarTheme` with:
  - `centerTitle: true`
  - `elevation: 0`
  - `backgroundColor: const Color(0xFF5C4033)`
  - `foregroundColor: Colors.white`
  - `titleTextStyle`: `TextStyle` with `fontSize: 20`, `fontWeight: FontWeight.w600`, `color: Colors.white`
- `elevatedButtonTheme`: `ElevatedButtonThemeData` with `style` set to `ElevatedButton.styleFrom` with:
  - `backgroundColor: const Color(0xFF5C4033)`
  - `foregroundColor: Colors.white`
  - `minimumSize: const Size(double.infinity, 48)`
  - `shape`: `RoundedRectangleBorder` with `borderRadius: BorderRadius.circular(8)`
  - `textStyle`: `const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)`
- `outlinedButtonTheme`: `OutlinedButtonThemeData` with `style` set to `OutlinedButton.styleFrom` with:
  - `foregroundColor: const Color(0xFF5C4033)`
  - `side`: `const BorderSide(color: Color(0xFF5C4033), width: 1.5)`
  - `minimumSize: const Size(double.infinity, 48)`
  - `shape`: `RoundedRectangleBorder` with `borderRadius: BorderRadius.circular(8)`
- `inputDecorationTheme`: `InputDecorationTheme` with:
  - `border`: `OutlineInputBorder` with `borderRadius: BorderRadius.circular(8)`
  - `enabledBorder`: `OutlineInputBorder` with `borderRadius: BorderRadius.circular(8)` and `borderSide: const BorderSide(color: Color(0xFFCAC4C0))`
  - `focusedBorder`: `OutlineInputBorder` with `borderRadius: BorderRadius.circular(8)` and `borderSide: const BorderSide(color: Color(0xFF5C4033), width: 2)`
  - `errorBorder`: `OutlineInputBorder` with `borderRadius: BorderRadius.circular(8)` and `borderSide: const BorderSide(color: Color(0xFFBA1A1A))`
  - `contentPadding`: `const EdgeInsets.symmetric(horizontal: 16, vertical: 12)`
  - `filled: true`
  - `fillColor: const Color(0xFFFFF8F5)`
- `cardTheme`: `CardTheme` with:
  - `elevation: 2`
  - `color: Colors.white`
  - `shape`: `RoundedRectangleBorder` with `borderRadius: BorderRadius.circular(12)`
  - `margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)`
- `floatingActionButtonTheme`: `FloatingActionButtonThemeData` with:
  - `backgroundColor: const Color(0xFF5C4033)`
  - `foregroundColor: Colors.white`
- `chipTheme`: `ChipThemeData` with:
  - `backgroundColor: const Color(0xFFF0E6E0)`
  - `selectedColor: const Color(0xFF5C4033)`
  - `labelStyle`: `const TextStyle(fontSize: 13)`
  - `padding`: `const EdgeInsets.symmetric(horizontal: 12, vertical: 4)`
- `dividerTheme`: `DividerThemeData` with `color: const Color(0xFFE0D6D0)`, `thickness: 1`

No other structural changes to the class. `darkTheme` is not added in this PR — that is PR46.

---

### `docs/Design_Thinking.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Design Philosophy

A 3–4 sentence paragraph establishing the design intent for CraftBridge. Key points to cover: the app serves artisans who may not be tech-savvy, so the UI must be simple and warm; buyers are mobile-first shoppers who expect a clean browsing experience; the visual language draws from craft and earth tones — warm browns, off-whites, natural textures; Material 3 is the design system baseline, adapted with a handcrafted-goods aesthetic.

---

#### 2. Color Palette

A table with columns: **Token**, **Hex Value**, **Usage**.

| Token | Hex Value | Usage |
|-------|-----------|-------|
| Primary (seed) | `#5C4033` | App bar, buttons, FAB, active states |
| Surface | `#FFF8F5` | Screen backgrounds, input fill |
| Accent / Sienna | `#A0522D` | Secondary highlights, category chips selected |
| On-surface | `#1C1B1F` | Body text, icons |
| Muted border | `#CAC4C0` | Input field borders (unfocused) |
| Divider | `#E0D6D0` | List dividers, card separators |
| Chip background | `#F0E6E0` | Unselected category filter chips |
| Error | `#BA1A1A` | Form validation errors, destructive actions |
| White | `#FFFFFF` | Card backgrounds, app bar text |

Followed by one paragraph explaining: all colors were chosen to evoke warmth, craft, and natural materials while remaining WCAG AA compliant for text contrast on their respective backgrounds.

---

#### 3. Typography

A table with columns: **Style**, **Size**, **Weight**, **Usage in CraftBridge**.

| Style | Size | Weight | Usage in CraftBridge |
|-------|------|--------|----------------------|
| headlineLarge | 32sp | 700 | Welcome screens, empty state headings |
| headlineMedium | 28sp | 600 | Screen titles (non-AppBar), section headers |
| headlineSmall | 24sp | 600 | Card section headings |
| titleLarge | 22sp | 600 | AppBar title |
| titleMedium | 16sp | 600 | Product card title, list item primary text |
| bodyLarge | 16sp | 400 | Product descriptions, form labels |
| bodyMedium | 14sp | 400 | Supporting text, artisan name on card |
| bodySmall | 12sp | 400 | Timestamps, metadata, status chips |
| labelLarge | 14sp | 600 | Button labels |
| labelSmall | 11sp | 500 | Badge counts, micro labels |

---

#### 4. User Personas

Three persona cards. Each contains: **Name**, **Role**, **Age**, **Location**, **Tech Comfort**, **Goal**, **Pain Point**, **What CraftBridge solves for them**.

**Persona 1 — Artisan:**
- Name: Meera Devi
- Role: Artisan
- Age: 38
- Location: Jaipur, Rajasthan
- Tech Comfort: Low — uses WhatsApp and basic smartphone apps
- Goal: Sell her handmade block-print textiles beyond her local market without needing a middleman
- Pain Point: No digital storefront, relies on physical exhibitions, loses orders due to no order tracking
- What CraftBridge solves: A simple product listing flow (title, photo, price, stock), automatic admin approval that gives her legitimacy, and an order tracking screen that shows her exactly what buyers have ordered

**Persona 2 — Buyer:**
- Name: Arjun Mehta
- Role: Buyer
- Age: 27
- Location: Bengaluru, Karnataka
- Tech Comfort: High — daily e-commerce user, expects app-store-quality UX
- Goal: Discover and buy authentic handcrafted goods directly from artisans, not factory-made imitations
- Pain Point: Mainstream e-commerce platforms mix handmade and mass-produced goods with no clear distinction
- What CraftBridge solves: A curated feed of only approved artisans' products, artisan context on the product detail screen including location on map, and a simple cart-to-order flow with order history

**Persona 3 — Admin:**
- Name: Priya Nair
- Role: Admin
- Age: 34
- Location: Chennai, Tamil Nadu
- Tech Comfort: Medium — comfortable with web dashboards and basic mobile apps
- Goal: Maintain platform quality by ensuring only legitimate artisans are approved and all orders are visible for dispute resolution
- Pain Point: No central tool to review artisan registrations or monitor platform-wide order status
- What CraftBridge solves: A ManageUsersScreen that surfaces pending artisan registrations with approve/reject actions, and a ManageAllOrdersScreen that shows every order across the platform

---

#### 5. User Journey Maps

Three journey maps — one per role. Each is a table with columns: **Step**, **Screen**, **User Action**, **System Response**, **Emotion**.

**Journey 1 — Artisan: From Registration to First Sale**

| Step | Screen | User Action | System Response | Emotion |
|------|--------|-------------|-----------------|---------|
| 1 | RegistrationScreen | Selects "I am an Artisan", fills name, email, password, bio | Creates Firestore user doc with `isApproved: false` | Hopeful |
| 2 | RoleRouterScreen | App reads role and approval status | Redirects to pending approval screen | Anxious |
| 3 | (email/phone) | Waits for admin contact | Admin approves in ManageUsersScreen | Relieved |
| 4 | ArtisanHomeScreen | Logs in after approval | RoleRouter now routes to ArtisanHomeScreen | Excited |
| 5 | AddEditProductScreen | Adds product: photo, title, price, category, stock | Product saved to Firestore with `isActive: true` | Proud |
| 6 | ArtisanOrdersScreen | Buyer places an order | New order appears in artisan's orders list | Surprised, happy |
| 7 | ArtisanOrdersScreen | Taps order, updates status to "Confirmed" | Order status updates in Firestore in real time | Confident |

**Journey 2 — Buyer: From Browse to Order**

| Step | Screen | User Action | System Response | Emotion |
|------|--------|-------------|-----------------|---------|
| 1 | RegistrationScreen | Selects "I am a Buyer", fills details | Creates Firestore user doc with role `buyer` | Curious |
| 2 | BuyerHomeScreen | Browses product grid | Loads all active products from approved artisans | Engaged |
| 3 | BuyerHomeScreen | Taps category chip to filter by "Textiles" | Grid filters to Textiles products only | Focused |
| 4 | ProductDetailScreen | Taps a product card | Sees full description, price, artisan name, map location | Interested |
| 5 | CartScreen | Taps "Add to Cart" | Item added to local CartProvider | Satisfied |
| 6 | CartScreen | Reviews cart, taps "Place Order" | Order written to Firestore orders collection | Excited |
| 7 | BuyerOrdersScreen | Views order history | Order shows status "Pending" | Patient |
| 8 | BuyerOrdersScreen | Checks back later | Status updated to "Confirmed" by artisan | Pleased |

**Journey 3 — Admin: Approve Artisan + Monitor Orders**

| Step | Screen | User Action | System Response | Emotion |
|------|--------|-------------|-----------------|---------|
| 1 | LoginScreen | Logs in with admin credentials | RoleRouter reads `role: admin`, routes to AdminHomeScreen | In control |
| 2 | AdminHomeScreen | Taps "Manage Users" | Navigates to ManageUsersScreen | Focused |
| 3 | ManageUsersScreen | Sees list of pending artisan registrations | Firestore query for `isApproved: false` | Attentive |
| 4 | ManageUsersScreen | Taps "Approve" on Meera Devi's account | Sets `isApproved: true` in Firestore | Satisfied |
| 5 | AdminHomeScreen | Taps "All Orders" | Navigates to ManageAllOrdersScreen | Thorough |
| 6 | ManageAllOrdersScreen | Scrolls through all platform orders | Sees orders by all buyers across all artisans | Informed |

---

#### 6. Wireframe Descriptions

One sub-section per screen. Each sub-section names the screen, lists the layout elements top to bottom, and describes the key interaction.

**SplashScreen:** Full-screen centered layout. Top: app logo placeholder (circular icon, 80×80). Middle: app name in `headlineMedium`. Bottom: tagline in `bodyLarge`. No app bar. Transitions automatically to RoleRouterScreen after auth check.

**LoginScreen:** Single-column scrollable layout. Top: app logo (48×48) + app name. Below: "Welcome back" in `headlineSmall`. Two `CustomTextField` widgets — email and password (with visibility toggle). `CustomButton` — "Log In" (full width, primary color). Text button — "Don't have an account? Register". Error text in red below button if auth fails.

**RegistrationScreen:** Single-column scrollable layout. Top: "Create Account" in `headlineSmall`. Fields: Display Name, Email, Password, Confirm Password. Role selector — two tappable cards: "I am an Artisan" and "I am a Buyer" with icons. Artisan card reveals a Bio text field when selected. `CustomButton` — "Create Account". Text button — "Already have an account? Log In".

**ArtisanHomeScreen:** Scaffold with `AppBar` titled "My Shop". Body: `Column` with a welcome `Text` (artisan name), followed by two large navigation cards — "My Products" (navigates to ManageProductsScreen) and "My Orders" (navigates to ArtisanOrdersScreen). Cards use icon + label layout.

**ManageProductsScreen:** Scaffold with `AppBar` titled "My Products". Body: `GridView` (2 columns) of `ProductCard` widgets. FAB (+ icon) navigates to AddEditProductScreen. Empty state: centered illustration + "No products yet. Tap + to add your first product." Swipe left on a card to reveal delete action.

**AddEditProductScreen:** Scaffold with `AppBar` titled "Add Product" or "Edit Product". Scrollable single-column form. Fields: Title, Description, Price, Category (dropdown from `AppConstants.productCategories`), Stock (numeric). Image section: tappable image placeholder → opens image picker → shows preview. `CustomButton` — "Save Product" at bottom.

**ArtisanOrdersScreen:** Scaffold with `AppBar` titled "My Orders". Body: `ListView` of `OrderCard` widgets. Each card shows: product image (60×60), product title, buyer name, quantity, total price, status chip. Tapping a card opens a bottom sheet with status update options.

**BuyerHomeScreen:** Scaffold with `AppBar` titled "Discover". Body: `Column` — horizontal scrollable row of category filter chips, then `GridView` (2 columns, responsive) of `ProductCard` widgets. Search bar below the app bar. `BottomNavigationBar` with three tabs: Home, Cart, My Orders.

**ProductDetailScreen:** Scaffold with `AppBar` (transparent, back button). Hero image (full width, aspect ratio 4:3). Below: product title in `titleLarge`, price in `headlineSmall` (primary color), artisan name + avatar row, description in `bodyLarge`, Google Map widget (250px height, artisan location marker), "Add to Cart" `CustomButton` fixed at bottom.

**CartScreen:** Scaffold with `AppBar` titled "My Cart". Body: `ListView` of `CartItemTile` widgets. Each tile: product image (56×56), title, quantity stepper (− qty +), item total. Bottom: order summary card (subtotal, item count), "Place Order" `CustomButton`.

**BuyerOrdersScreen:** Scaffold with `AppBar` titled "My Orders". Body: `ListView` of `OrderCard` widgets. Each card: product image, title, artisan name, status chip (color-coded), order date, total price.

**AdminHomeScreen:** Scaffold with `AppBar` titled "Admin Dashboard". Body: `Column` of two large navigation cards — "Manage Users" and "All Orders" — with subtitle counts (pending approvals, total orders).

**ManageUsersScreen:** Scaffold with `AppBar` titled "Manage Users". Body: `ListView` of user tiles. Each tile: avatar, display name, email, role chip. Artisan tiles show an approval status chip and Approve / Reject action buttons if `isApproved: false`.

**ManageAllOrdersScreen:** Scaffold with `AppBar` titled "All Orders". Body: `ListView` of `OrderCard` widgets showing all orders across all artisans and buyers with status chips.

---

#### 7. Accessibility Notes

Bullet list covering:
- Minimum touch target size: 48×48dp for all interactive elements, per Material 3 guidelines
- Color contrast: all primary text on surface backgrounds meets WCAG AA (4.5:1 for normal text, 3:1 for large text)
- All images must include semantic labels for screen readers via `semanticLabel` parameter on `Image` widgets
- Form fields must use `labelText` and `hintText` so screen readers can identify field purpose
- Status chips must not rely on color alone — always include a text label alongside the color indicator
- `CustomButton` must never be disabled without also providing a visible explanation of why it is disabled

---

#### 8. Figma Reference Note

One paragraph stating: a Figma reference file was used to plan the wireframe layouts described in Section 6. The Figma file is not committed to the repository — the wireframe descriptions in this document serve as the written specification for all screen implementations. Any teammate implementing a screen should treat Section 6 of this document as the authoritative layout spec, supplemented by the Technical Requirements in the relevant PR document.

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `docs/Design_Thinking.md` | Complete design thinking document with all 8 sections — personas, journeys, wireframes, color palette, typography, accessibility |
| 2 | `lib/core/theme/app_theme.dart` | Updated with finalized color scheme, `outlinedButtonTheme`, `floatingActionButtonTheme`, `chipTheme`, `dividerTheme`, and enhanced `inputDecorationTheme` |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR04 is merged to main**

Open your GitHub repository and confirm the `pr04-firebase-setup` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR05 branch**
```
git checkout -b pr05-design-thinking
```

**Step 4 — Confirm `app_theme.dart` is the PR03 version**
```
cat lib/core/theme/app_theme.dart
```
Confirm it contains the `AppTheme` class with the provisional `#6B4226` seed color from PR03. If it shows the PR01 placeholder comment, do not proceed — diagnose the PR03 implementation first.

---

Manual setup for this PR is now complete.
Open `docs/PR05_Design_Thinking.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must perform two tasks: update `app_theme.dart` and write `docs/Design_Thinking.md`.

---

**Task 1 — Update `lib/core/theme/app_theme.dart`**

Replace the entire file content with an updated implementation. The class name `AppTheme` and the static getter name `lightTheme` do not change. The following changes must be made to `lightTheme`:

- Replace seed color from `const Color(0xFF6B4226)` to `const Color(0xFF5C4033)`.
- Add `surface: const Color(0xFFFFF8F5)` to `ColorScheme.fromSeed`.
- Add `titleTextStyle` to `appBarTheme` as specified in Section 6.
- Add `textStyle` to `elevatedButtonTheme` as specified in Section 6.
- Add `outlinedButtonTheme` as a new sub-theme as specified in Section 6.
- Replace `inputDecorationTheme` with the expanded version including `enabledBorder`, `focusedBorder`, `errorBorder`, `filled`, and `fillColor` as specified in Section 6.
- Update `cardTheme` to add `color: Colors.white` and `margin` as specified in Section 6.
- Add `floatingActionButtonTheme` as a new sub-theme as specified in Section 6.
- Add `chipTheme` as a new sub-theme as specified in Section 6.
- Add `dividerTheme` as a new sub-theme as specified in Section 6.

All values must match Section 6 exactly. No values from Section 6 may be omitted. Retain `fontFamily: 'Roboto'` and `useMaterial3: true`. Ensure all `const` constructors are used wherever valid. No unused imports.

---

**Task 2 — Write `docs/Design_Thinking.md`**

Write a complete Markdown document to `docs/Design_Thinking.md` containing all 8 sections specified in Section 6 of this PR document, in order. The agent must write each section as follows:

- **Section 1 — Design Philosophy:** 3–4 sentences covering the four key points specified in Section 6.
- **Section 2 — Color Palette:** The complete 9-row table exactly as specified, followed by the WCAG contrast paragraph.
- **Section 3 — Typography:** The complete 10-row table exactly as specified.
- **Section 4 — User Personas:** Three complete persona cards for Meera Devi, Arjun Mehta, and Priya Nair, each with all 8 fields as specified.
- **Section 5 — User Journey Maps:** Three complete journey tables — Artisan (7 steps), Buyer (8 steps), Admin (6 steps) — all exactly as specified.
- **Section 6 — Wireframe Descriptions:** All 14 screen wireframe descriptions exactly as specified, each with the screen name as a sub-heading, layout elements listed top to bottom, and the key interaction described.
- **Section 7 — Accessibility Notes:** All 6 bullet points exactly as specified.
- **Section 8 — Figma Reference Note:** One paragraph as specified.

No sections may be omitted. No tables may be abbreviated. All persona names, journey steps, and wireframe details must match Section 6 exactly.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings, zero hints. Common issues to watch for: missing `const` on new theme constructors, type errors in `ChipThemeData` or `DividerThemeData` parameters, incorrect `BorderSide` usage inside `OutlineInputBorder`.

2. **Hot reload on emulator**
   ```
   flutter run
   ```
   Confirm:
   - The app bar background is now the updated deep espresso brown (`#5C4033`) — slightly darker than PR03.
   - The body still shows "CraftBridge", the tagline, and "Firebase connected ✓" in green.
   - No overflow errors, no red error widgets, no debug banner.
   Press `q` to quit.

3. **Verify `app_theme.dart` sub-themes**
   ```
   cat lib/core/theme/app_theme.dart
   ```
   Confirm the file contains: `outlinedButtonTheme`, `floatingActionButtonTheme`, `chipTheme`, `dividerTheme`, updated `inputDecorationTheme` with `enabledBorder`/`focusedBorder`/`errorBorder`, and `cardTheme` with `color` and `margin`. If any sub-theme is missing, fix and re-run verification.

4. **Verify `docs/Design_Thinking.md` exists and is complete**
   ```
   cat docs/Design_Thinking.md
   ```
   Confirm all 8 sections are present. Confirm the three persona cards are present. Confirm all three journey tables are present with correct step counts (7, 8, 6). Confirm all 14 wireframe descriptions are present.

5. **Verify only the correct files were modified**
   ```
   git diff --name-only
   ```
   Only `lib/core/theme/app_theme.dart` and `docs/Design_Thinking.md` should appear. If any other files appear, diagnose before pushing.

6. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 05
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
git commit -m "PR05: Design Thinking — UI/UX Planning + Figma Reference"
git push origin pr05-design-thinking
```

---

## Section 9 – Acceptance Criteria

- [ ] `docs/Design_Thinking.md` exists and contains all 8 sections in the correct order.
- [ ] Section 4 contains three complete persona cards for Meera Devi (Artisan), Arjun Mehta (Buyer), and Priya Nair (Admin).
- [ ] Section 5 contains three journey maps with 7 steps (Artisan), 8 steps (Buyer), and 6 steps (Admin) respectively.
- [ ] Section 6 contains wireframe descriptions for all 14 screens in the locked screen set.
- [ ] Section 2 color palette table contains all 9 color tokens with hex values and usage descriptions.
- [ ] `lib/core/theme/app_theme.dart` seed color is updated to `#5C4033`.
- [ ] `app_theme.dart` `lightTheme` contains all sub-themes: `appBarTheme`, `elevatedButtonTheme`, `outlinedButtonTheme`, `inputDecorationTheme`, `cardTheme`, `floatingActionButtonTheme`, `chipTheme`, `dividerTheme`.
- [ ] `inputDecorationTheme` contains `enabledBorder`, `focusedBorder`, `errorBorder`, `filled`, and `fillColor`.
- [ ] No new `.dart` files were created and no files outside the two modified files were changed.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR05 for CraftBridge. I produced the design thinking document — three user personas, three user journey maps, wireframe descriptions for all 14 screens, a finalized color palette, and a typography scale — and updated `app_theme.dart` to the final color scheme that will govern the entire app."

2. **Design philosophy:** "CraftBridge serves two very different users — artisans who may be using a smartphone app for the first time, and buyers who are experienced e-commerce shoppers. The design had to be warm and approachable for artisans while being clean and fast for buyers. Material 3 gives us the accessibility and layout foundation; the earthy color palette gives it the craft-market identity."

3. **Color palette finalization:** "The provisional brown from PR03 was `#6B4226`. After applying design thinking, I landed on `#5C4033` — a deeper espresso brown that photographs better against the warm off-white surface `#FFF8F5`. I verified WCAG AA contrast ratios for all text-on-background combinations before committing these values."

4. **User personas:** "The three personas — Meera Devi the artisan in Jaipur, Arjun Mehta the buyer in Bengaluru, and Priya Nair the admin in Chennai — are grounded in the real demographic of Indian craft commerce. They're not abstract role descriptions. They have ages, tech comfort levels, specific pain points, and specific things CraftBridge solves for them. Every screen decision traces back to one of these three people."

5. **User journey maps:** "The journey maps trace each persona's path through the app from first action to goal completion. The artisan journey ends when she sees her first order. The buyer journey ends when she checks back and sees her order confirmed. The admin journey ends when she's approved an artisan and reviewed all orders. These aren't happy-path fantasies — they include the waiting state, the approval gate, and the status-check loop."

6. **Wireframe descriptions:** "All 14 screens are described layout-element by layout-element from top to bottom. I didn't produce image wireframes because the written spec is more useful for an agent implementing the screens — a PNG wireframe can't be parsed by code. These descriptions are the layout contract for every screen PR from PR11 through PR48."

7. **`app_theme.dart` expansion:** "The theme now has eight sub-themes instead of four. I added `outlinedButtonTheme` for secondary actions, `floatingActionButtonTheme` so the FAB on ManageProductsScreen inherits the brand color, `chipTheme` for the category filter chips on BuyerHomeScreen, and `dividerTheme` for consistent list separators. These additions mean zero per-widget color code in any screen implementation."

8. **`inputDecorationTheme` enhancement:** "The input decoration theme now has separate border specs for enabled, focused, and error states. The focused border uses a 2px stroke in the primary color — this is a Material 3 best practice that gives the user clear visual feedback about which field is active. The fill color matches the surface color so inputs feel integrated into the screen rather than floating."

9. **`flutter analyze` result:** "Eight new sub-theme configurations with `const` constructors, `BorderSide` instances, `EdgeInsets`, and `TextStyle` — all pass the analyzer with zero issues. The `ChipThemeData` in particular requires careful typing because its `labelStyle` is a `TextStyle`, not a `TextTheme`."

10. **What's Next:** "PR06 will produce the High-Level Design document — the system architecture diagram, module interaction map, Firebase service layer description, and deployment architecture — establishing the technical blueprint that the LLD in PR07 will decompose into individual files and method signatures."