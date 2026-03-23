# CraftBridge — Project Plan & MVP Scope

## 1. Project Overview

CraftBridge is a digital storefront platform that enables local artisans to sell handmade products directly to buyers through a mobile-first Flutter application. The platform operates on a three-role model — Admin, Artisan, and Buyer — providing specialized workflows for each stakeholder. Built on the Flutter framework with Firebase as backend (Authentication, Firestore, and Cloud Storage), CraftBridge aims to democratize direct-to-consumer sales for traditional craftspeople while creating curated product discovery for conscious consumers. The MVP targets Android as the primary platform with iOS as a secondary build, launching across 51 pull requests over 17 sprints with a three-member development team.

---

## 2. Three Roles — MVP Scope Per Role

| Role | MVP Features | Out of Scope for MVP |
|------|--------------|---------------------|
| Admin | Approve or reject artisan account applications; view all registered users (Admin, Artisan, Buyer); view all orders placed on the platform across all artisans and buyers. | Analytics dashboard; bulk user actions; admin notifications; reporting tools; user suspension or deletion workflows. |
| Artisan | Register with role selection during signup; await admin approval before products go live; add, edit, and delete own products (title, description, price, category, stock level, and image); view all incoming orders for own products; update order status through workflow (confirmed → shipped → delivered or cancelled). | Artisan analytics or sales dashboard; promotional tools or coupons; multiple images per product; subscription tiers or premium features; automatic inventory synchronization; artisan notifications. |
| Buyer | Browse all active products from approved artisans; view product detail with artisan location displayed on map; add products to shopping cart; place orders with automatic order confirmation; view full personal order history and order status updates; submit and read product reviews. | Wishlist or saved items; saved delivery addresses; buyer push notifications; coupon codes or promotional discounts; real payment gateway integration (orders placed but not charged); subscription or membership features; chat with artisans. |

---

## 3. Firestore Collections — MVP Data Model Summary

| Collection | Key Fields | Who Writes | Who Reads |
|------------|-----------|-----------|----------|
| users | uid, email, displayName, role (Admin/Artisan/Buyer), isApproved, createdAt | AuthProvider on signup; Admin on approval | All roles (own document); Admin (all user documents) |
| products | id, artisanId, title, description, price, category, imageUrl, isActive, stock, createdAt, updatedAt | Artisan (own products only) | Buyer (all active products); Artisan (own products); Admin (all products) |
| orders | id, buyerId, artisanId, productId, quantity, status (pending/confirmed/shipped/delivered/cancelled), totalPrice, createdAt, updatedAt | Buyer at checkout | Buyer (own orders); Artisan (own incoming orders); Admin (all orders) |
| reviews | id, productId, buyerId, rating (1–5), comment, createdAt | Buyer (own reviews only) | All roles (all reviews) |

---

## 4. Sprint Timeline

| Sprint | PRs | Focus | Assigned To |
|--------|-----|-------|-------------|
| 1 | PR01–PR04 | Project scaffold, plan, Dart fundamentals, Firebase setup | Member 1 |
| 2 | PR05–PR07 | Design thinking, high-level design, low-level design + models | Member 1 |
| 3 | PR08–PR10 | main.dart upgrade, custom widgets, AuthProvider | Member 1 |
| 4 | PR11–PR13 | SplashScreen, RoleRouterScreen, Auth screen shells | Member 1 |
| 5 | PR14–PR16 | Auth screens wired, session persistence, navigation routes | Member 1 |
| 6 | PR17–PR19 | Responsive layout foundation, ManageProductsScreen, AppTheme global | Member 1 + Member 2 handoff |
| 7 | PR20–PR22 | AddEditProductScreen forms, local state, reusable widgets | Member 2 |
| 8 | PR23–PR25 | Responsive ProductCard grid, Firebase Storage upload, animations | Member 2 |
| 9 | PR26–PR28 | ProductProvider, StorageService, Artisan registration flow | Member 2 |
| 10 | PR29–PR31 | Auth flows integration tests, ArtisanOrdersScreen, product CRUD | Member 2 |
| 11 | PR32–PR34 | BuyerHomeScreen live data, order placement, real-time Firestore sync | Member 2 |
| 12 | PR35–PR37 | Product search and filter, image management, order status triggers | Member 3 |
| 13 | PR38–PR40 | FCM setup, Firestore security rules, Google Maps integration | Member 3 |
| 14 | PR41–PR43 | User location services, CartProvider, OrderProvider | Member 3 |
| 15 | PR44–PR46 | Review form widget, buyer navigation shell, dark mode theme | Member 3 |
| 16 | PR47–PR49 | Error handling and validation, admin screens, release APK build | Member 3 |
| 17 | PR50–PR51 | Google Play Store deployment, final submission and documentation | Member 3 |

---

## 5. GitHub Branching Strategy

### Main Branch Policy
The `main` branch is the single source of truth for the project and must always be in a stable, deployable state. Only verified, mergeable pull requests are ever merged to `main`. No developer commits directly to `main` under any circumstances. All work is performed on feature branches that are created from the latest `main` and deleted after merge.

### Branch Naming Convention
Every pull request for this project is developed on its own branch using the strict naming convention `pr[nn]-[slug]`, where `[nn]` is the zero-padded PR number and `[slug]` is a short kebab-case description of the PR's primary deliverable. Examples: `pr01-scaffold`, `pr10-auth-provider`, `pr33-order-placement`, `pr51-final-submission`. This convention makes the branch list immediately scannable and ensures no naming collisions.

### Branch Lifecycle
The lifecycle of a branch follows a fixed sequence: (1) Developer creates the branch from the latest `main` with `git checkout -b pr[nn]-[slug]`. (2) All commits for that PR are made to the branch, using the commit message format `PR[NN]: [Title]`. (3) Before pushing, the agent runs the complete verification suite including `flutter analyze` and compilation checks. (4) Only if all verification passes does the agent push the branch and create a pull request targeting `main`. (5) After the pull request is merged, the branch is deleted and cannot be resurrected — each PR is strictly one-way.

### No Long-Lived Feature Branches
This project does not use `develop`, `staging`, `feature/*`, or `hotfix/*` branches. All branches are strictly PR-scoped with lifespans measured in hours or days, not weeks. This approach eliminates branch management overhead, prevents merge conflicts from diverged branches, and ensures every piece of work flows directly and continuously to the stable main line.

### Commit Message Convention
Every commit in this project uses the strict format `PR[NN]: [Title]`, where `[NN]` is the zero-padded PR number. Examples: `PR01: Technology Orientation + Project Scaffold`, `PR10: AuthProvider Implementation`, `PR33: Order Placement Workflow`. This convention makes the git log instantly searchable by PR number and provides automatic cross-referencing between commits and documentation.

### Conflict Prevention Through Sequential Structure
Branch conflicts are structurally avoided in this project because every PR depends on the previous PR being merged to `main` before the next branch is created. Since each PR targets distinct folders or distinct methods within a single class, and no two PRs ever modify the same file at the same time, merge conflicts are virtually impossible. The sequential execution and locked folder structure (each PR-scoped to its own paths) guarantee that team members can work independently on their assigned PR ranges without disrupting each other.

---

## 6. Team Responsibilities

| Member | PRs | Role in Project |
|--------|-----|-----------------|
| Member 1 | PR01–PR17 | Project Lead and Infrastructure Owner. Responsible for project scaffold, Firebase configuration, authentication layer, navigation architecture, responsive layout foundation, and all infrastructure decisions. Establishes patterns and conventions that subsequent members follow. |
| Member 2 | PR18–PR34 | Core Feature Developer. Builds all artisan-facing workflows (product management, order tracking), product discovery and browsing for buyers, order placement system, and real-time data synchronization. Executes the largest feature set and transitions project knowledge to Member 3. |
| Member 3 | PR35–PR51 | Feature Completion and Release Owner. Implements advanced features (search, maps, cart optimization), admin dashboard, dark mode, comprehensive error handling, Google Play release, and final submission. Ensures production readiness and deployment reliability. |

---

## 7. Out of Scope — Full List

- Real payment gateway integration (Stripe, Razorpay, Square, or other payment processors) — orders are recorded but not charged.
- In-app direct messaging between buyer and artisan — no real-time chat.
- Artisan analytics or sales dashboard — no revenue metrics, sales graphs, or performance tracking.
- Promotional code system or discount codes — all pricing is fixed per product.
- Multiple images per product — one primary image per product only.
- Wishlist or saved items — buyers cannot bookmark products for later.
- Buyer delivery address management — no saved addresses, no address book.
- Push notifications (FCM setup documented in PR38 but not fully implemented) — users receive no mobile alerts.
- Web or desktop platform builds — only Android and iOS builds; no web version.
- Artisan subscription or premium tiers — all artisans have identical feature access.
- Automated order fulfillment or third-party shipping integration — shipping is manual per artisan.

---

## 8. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Firebase quota or cost limit exceeded during development | Low | Use Firebase Firestore emulator locally for PRs 07–17; switch to live Firebase project only for cloud storage testing in PRs 18+. Monitor quotas throughout sprints. |
| Agent produces code that breaks functionality from a previous PR | Medium | Every PR runs `flutter analyze` and full build verification before pushing. Sequential branch structure ensures each PR is tested on the latest main. Regression tests exist for auth and order flows. |
| Scope creep from new requirements mid-project | Medium | This document is the locked, canonical scope reference. Any new requirements beyond the MVP must be documented in a separate post-MVP backlog. Scope changes require explicit team consensus before implementation. |
| Team member unavailability during assigned sprints | Low | All PR specifications are committed to `docs/` and written to be self-contained. Any team member can execute any PR by reading its spec. No knowledge silo exists; each PR carries its own full context. |
| Google Maps API key misconfiguration or quota issues in PR40 | Medium | PR40 includes explicit setup steps for API key creation and quota configuration. Maps functionality is isolated to `product_detail_screen.dart` only, minimizing blast radius if key fails. Fallback is static artisan location display. |

---

## End of Project Plan

This document is the authoritative reference for CraftBridge's MVP scope, timeline, and team structure throughout the 51-PR development cycle. Any deviation from this document requires explicit documentation and team consensus.

Last Updated: PR02 Implementation
