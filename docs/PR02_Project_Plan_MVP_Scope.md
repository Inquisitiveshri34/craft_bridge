# PR02 – Project Plan + MVP Scope Definition

**Project:** CraftBridge
**PR Number:** 02 of 51
**Assigned To:** Member 1
**Type:** TYPE A – Hybrid PR (Manual + Agent)

---

## Section 1 – PR Title

Project plan, MVP scope definition, sprint timeline, GitHub repo setup, and branching strategy document for CraftBridge.

---

## Section 2 – Assignments Covered

- Assignment 3.2 — Project Plan + MVP Scope Definition

---

## Section 3 – Objective

This PR produces the formal project plan document for CraftBridge, defining the MVP scope across all three roles, establishing the sprint timeline for all 51 PRs, and documenting the GitHub branching strategy the team will follow for the entire project. No new Dart files are created or modified. This document becomes the canonical reference for scope decisions throughout the build and is committed to `docs/` so all teammates can access it on GitHub at any time.

---

## Section 4 – Architecture Context

```
docs/
  PR02_Project_Plan_MVP_Scope.md   ← produced by this PR

No Dart files touched.
No Firebase interactions.
No folder structure changes.

GitHub Repository (already created in PR01)
    │
    ▼
Branching Strategy Documented
    │
    ├── main          ← stable, merged PRs only
    ├── pr01-scaffold ← merged
    └── pr02-plan     ← this PR's branch
```

This PR sits between the project scaffold (PR01) and the first code implementation (PR03). It exists to ensure the team has an agreed, written scope before any logic is written — preventing scope creep and giving Member 2 and Member 3 a clear contract for what they are building.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- `docs/PR02_Project_Plan_MVP_Scope.md`

**Allowed file modification:**
- None.

**Not allowed:**
- Do NOT create any new folders.
- Do NOT create any new `.dart` files.
- Do NOT modify any existing `.dart` files.
- Do NOT modify `pubspec.yaml`.
- Do NOT modify `README.md`.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart`.

---

## Section 6 – Technical Requirements

### `docs/PR02_Project_Plan_MVP_Scope.md`

This is a Markdown document. It must contain all of the following sections, written in full prose and structured tables where specified.

---

#### 1. Project Overview

- App name: CraftBridge
- Platform: Flutter (Android primary, iOS secondary)
- Backend: Firebase (Auth, Firestore, Storage)
- Team size: 3 members
- Total PRs: 51
- Submission deadline: end of sprint 17 (PR51)

One paragraph describing what CraftBridge does and why it exists.

---

#### 2. Three Roles — MVP Scope Per Role

A table with columns: **Role**, **MVP Features**, **Out of Scope for MVP**.

**Admin:**
- MVP: Approve or reject artisan accounts, view all registered users, view all orders across the platform.
- Out of scope: Analytics dashboard, bulk actions, admin notifications.

**Artisan:**
- MVP: Register with role selection, wait for admin approval, add/edit/delete own products (title, description, price, category, stock, image), view incoming orders for their products, update order status (confirmed, shipped, delivered, cancelled).
- Out of scope: Artisan analytics, promotional tools, multiple images per product, subscription tiers.

**Buyer:**
- MVP: Browse all active products from approved artisans, view product detail with artisan location on map, add to cart, place orders, view own order history, submit product reviews.
- Out of scope: Wishlist, saved addresses, buyer notifications, payment gateway integration (orders are placed without real payment).

---

#### 3. Firestore Collections — MVP Data Model Summary

A table with columns: **Collection**, **Key Fields**, **Who Writes**, **Who Reads**.

Rows:
- `users` — uid, email, displayName, role, isApproved — AuthProvider on signup — All roles (own doc), Admin (all)
- `products` — id, artisanId, title, price, imageUrl, isActive, stock — Artisan (own) — Buyer (all active), Artisan (own), Admin (all)
- `orders` — id, buyerId, artisanId, productId, status, totalPrice — Buyer on checkout — Buyer (own), Artisan (own), Admin (all)
- `reviews` — id, productId, buyerId, rating, comment — Buyer (own) — All roles

---

#### 4. Sprint Timeline

A table with columns: **Sprint**, **PRs**, **Focus**, **Assigned To**.

| Sprint | PRs | Focus | Assigned To |
|--------|-----|-------|-------------|
| 1 | PR01–PR04 | Project scaffold, plan, fundamentals, Firebase setup | Member 1 |
| 2 | PR05–PR07 | Design thinking, HLD, LLD + models | Member 1 |
| 3 | PR08–PR10 | main.dart, widgets, AuthProvider | Member 1 |
| 4 | PR11–PR13 | Splash, RoleRouter, Auth screen shells | Member 1 |
| 5 | PR14–PR16 | Auth wired, session persistence, navigation | Member 1 |
| 6 | PR17–PR19 | Responsive layout, ManageProducts, AppTheme | Member 1 + Member 2 handoff |
| 7 | PR20–PR22 | Forms, local state, reusable widgets | Member 2 |
| 8 | PR23–PR25 | Responsive grid, Storage upload, animations | Member 2 |
| 9 | PR26–PR28 | ProductProvider, StorageService, Artisan registration | Member 2 |
| 10 | PR29–PR31 | Auth flows tested, ArtisanOrders, product CRUD | Member 2 |
| 11 | PR32–PR34 | BuyerHome live, order placement, real-time sync | Member 2 |
| 12 | PR35–PR37 | Search/filter, image management, order status | Member 3 |
| 13 | PR38–PR40 | FCM setup, security rules, Google Maps | Member 3 |
| 14 | PR41–PR43 | User location, CartProvider, OrderProvider | Member 3 |
| 15 | PR44–PR46 | Review form, buyer nav shell, dark mode | Member 3 |
| 16 | PR47–PR49 | Error handling, admin screens, release APK | Member 3 |
| 17 | PR50–PR51 | Play Store deployment, final submission | Member 3 |

---

#### 5. GitHub Branching Strategy

Written in full prose with the following points covered:

- **Main branch:** `main` is always stable. Only merged, verified PRs land on `main`. No one commits directly to `main`.
- **PR branches:** Every PR is developed on its own branch named `pr[nn]-[slug]` — for example `pr01-scaffold`, `pr10-auth-provider`, `pr33-order-placement`. The slug is a short kebab-case description of the PR's primary deliverable.
- **Branch lifecycle:** Branch is created from the latest `main`, all work for that PR is committed to the branch, the agent runs full verification, and only if all checks pass does it push and open a pull request targeting `main`. After merge, the branch is deleted.
- **No long-lived feature branches:** There are no `develop`, `staging`, or `feature` branches. All branches are PR-scoped and short-lived.
- **Commit message convention:** Every commit uses the format `PR[NN]: [Title]` — for example `PR01: Technology Orientation + Project Scaffold`.
- **Conflict prevention:** Because PRs are sequential and each PR assumes the previous is merged, branch conflicts are structurally avoided. No two PRs ever modify the same file at the same time.

---

#### 6. Team Responsibilities

A table with columns: **Member**, **PRs**, **Role in Project**.

| Member | PRs | Role in Project |
|--------|-----|-----------------|
| Member 1 | PR01–PR17 | Project lead. Infrastructure, Firebase setup, auth layer, navigation skeleton, responsive layout foundation. |
| Member 2 | PR18–PR34 | Core feature build. All artisan flows, product CRUD, buyer product browsing, order placement, real-time sync. |
| Member 3 | PR35–PR51 | Feature completion and release. Search, maps, cart, reviews, dark mode, error handling, admin screens, APK, deployment. |

---

#### 7. Out of Scope — Full List

Bullet list of everything explicitly excluded from the MVP:

- Real payment gateway (Stripe, Razorpay, etc.)
- In-app messaging between buyer and artisan
- Artisan analytics or sales dashboard
- Promotional codes or discount system
- Multiple images per product
- Wishlist or saved items
- Buyer delivery address management
- Push notifications (FCM setup is documented in PR38 but not fully implemented)
- Web or desktop platform builds (Android is primary target)
- Subscription or premium tiers for artisans
- Automated order fulfillment or shipping integration

---

#### 8. Risks and Mitigations

A table with columns: **Risk**, **Likelihood**, **Mitigation**.

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Firebase quota exceeded during development | Low | Use Firestore emulator locally for PRs 07–17; switch to live project for PRs 18+ |
| Agent produces code that breaks a previous PR | Medium | Every PR runs `flutter analyze` before pushing; sequential branching catches regressions |
| Scope creep from assignment requirements | Medium | This document is the locked scope reference; any additions go in a separate post-MVP doc |
| Teammate unavailability during sprint | Low | All PR specs are committed to `docs/` and self-contained; any member can execute any PR |
| Google Maps API key misconfiguration | Medium | PR40 includes explicit key setup steps; Maps is isolated to `product_detail_screen.dart` only |

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `docs/PR02_Project_Plan_MVP_Scope.md` | Complete project plan document with all 8 sections as specified above |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

Complete the following steps before handing off to the agent.

**Step 1 — Confirm PR01 is merged to main**

Open your GitHub repository and confirm the `pr01-scaffold` pull request has been merged to `main`.

**Step 2 — Pull latest main**
```
cd ~/Developer/craft_bridge
git checkout main
git pull origin main
```

**Step 3 — Create and check out the PR02 branch**
```
git checkout -b pr02-plan
```

**Step 4 — Confirm `docs/` directory exists**
```
ls docs/
```
You should see `PR01_Technology_Orientation_Project_Scaffold.md` already present from PR01.

---

Manual setup for this PR is now complete.
Open `docs/PR02_Project_Plan_MVP_Scope.md` in your repository.
Paste the prompt into your agentic tool.
The agent will handle all remaining code tasks and verification for this PR.

---

### Part 2 – Agent Implementation Instructions

The agent must perform exactly one task: write the file `docs/PR02_Project_Plan_MVP_Scope.md`.

The file is a Markdown document. It must contain all 8 sections specified in Section 6 of this PR document, in order, with no sections omitted. The agent must write each section as follows:

**Section 1 — Project Overview:** Write a 3–4 sentence paragraph describing CraftBridge as a digital storefront platform for local artisans, Flutter + Firebase stack, three-role model (Admin, Artisan, Buyer), and the goal of enabling artisans to sell directly to buyers through a mobile-first app.

**Section 2 — Three Roles — MVP Scope Per Role:** Produce a Markdown table with columns Role, MVP Features, Out of Scope for MVP. Populate exactly as specified in Section 6 above. Each cell must be complete — no empty cells.

**Section 3 — Firestore Collections — MVP Data Model Summary:** Produce a Markdown table with columns Collection, Key Fields, Who Writes, Who Reads. Populate all four collections exactly as specified in Section 6 above.

**Section 4 — Sprint Timeline:** Produce a Markdown table with columns Sprint, PRs, Focus, Assigned To. All 17 sprints must be present exactly as specified in Section 6 above.

**Section 5 — GitHub Branching Strategy:** Write full prose paragraphs covering all six points specified in Section 6: main branch policy, branch naming convention, branch lifecycle, no long-lived branches, commit message convention, and conflict prevention strategy.

**Section 6 — Team Responsibilities:** Produce a Markdown table with columns Member, PRs, Role in Project. All three members must be present exactly as specified in Section 6 above.

**Section 7 — Out of Scope — Full List:** Write a bullet list containing all 11 items specified in Section 6 above. No items may be omitted.

**Section 8 — Risks and Mitigations:** Produce a Markdown table with columns Risk, Likelihood, Mitigation. All 5 rows must be present exactly as specified in Section 6 above.

The agent must not create any `.dart` files. The agent must not modify any existing files. The only file written in this PR is `docs/PR02_Project_Plan_MVP_Scope.md`.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!` — zero errors, zero warnings. No Dart files were modified in this PR so this should pass identically to PR01. If it does not, diagnose and fix before continuing.

2. **Verify the document exists**
   ```
   ls docs/
   ```
   Confirm `PR02_Project_Plan_MVP_Scope.md` is present alongside `PR01_Technology_Orientation_Project_Scaffold.md`.

3. **Verify document structure**
   ```
   cat docs/PR02_Project_Plan_MVP_Scope.md
   ```
   Confirm all 8 sections are present in order. Confirm all four tables (Sections 2, 3, 4, 6, 8) are present and populated. Confirm Section 5 is written in prose. Confirm Section 7 contains all 11 bullet points.

4. **Verify no Dart files were modified**
   ```
   git diff --name-only
   ```
   The only file that should appear in the diff is `docs/PR02_Project_Plan_MVP_Scope.md`. If any `.dart` files appear, the agent has violated scope — do not push and output a VERIFICATION FAILED report.

5. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 02
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
git commit -m "PR02: Project Plan + MVP Scope Definition"
git push origin pr02-plan
```

---

## Section 9 – Acceptance Criteria

- [ ] `docs/PR02_Project_Plan_MVP_Scope.md` exists at the correct path.
- [ ] The document contains all 8 sections in the correct order with no sections omitted.
- [ ] Section 2 contains a complete three-row table covering Admin, Artisan, and Buyer MVP features and out-of-scope items.
- [ ] Section 3 contains a complete four-row table covering all Firestore collections with Who Writes and Who Reads populated.
- [ ] Section 4 contains a complete 17-row sprint timeline table with all PRs, focus areas, and member assignments.
- [ ] Section 5 covers all six branching strategy points in full prose.
- [ ] Section 7 contains all 11 out-of-scope bullet points.
- [ ] Section 8 contains a complete five-row risks and mitigations table.
- [ ] No `.dart` files were created or modified by this PR.
- [ ] `git diff --name-only` shows only `docs/PR02_Project_Plan_MVP_Scope.md` as changed.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR02 for CraftBridge. I produced the formal project plan and MVP scope document — the canonical written contract that defines exactly what we are building across all 51 PRs for all three teammates."

2. **Why a scope document matters:** "In a three-member, 51-PR project, scope creep is the biggest risk. Having this document committed to `docs/` on GitHub means every teammate can open it at any time and know exactly what is in scope, what is out of scope, and why."

3. **Three-role MVP scope:** "Section 2 defines the MVP per role. Admin gets approval and oversight. Artisan gets product management and order tracking. Buyer gets browsing, cart, orders, and reviews. Everything else — payment gateways, wishlists, analytics — is explicitly out of scope and documented in Section 7."

4. **Firestore data model summary:** "Section 3 maps all four Firestore collections — users, products, orders, reviews — to who writes them and who reads them. This is the earliest version of the data contract that gets fully locked in PR07 with the LLD."

5. **Sprint timeline:** "Section 4 shows all 17 sprints. Member 1 owns PRs 01–17, which is the infrastructure and auth layer. Member 2 owns PRs 18–34, the core feature build. Member 3 owns PRs 35–51, feature completion and release. The timeline is designed so Member 2 and Member 3 can work in parallel after PR17 is merged."

6. **Branching strategy:** "Section 5 documents the branching convention used for all 51 PRs. Every PR gets its own `pr[nn]-[slug]` branch, commits use the `PR[NN]: [Title]` format, and nothing lands on `main` without passing verification. There are no long-lived branches."

7. **No Dart files in this PR:** "PR02 is intentionally code-free. It sits between the scaffold and the first implementation PR. The only file produced is the Markdown document in `docs/`. Running `flutter analyze` confirms the project is still in a zero-issue state."

8. **Out of scope list:** "Section 7 lists 11 items explicitly excluded from the MVP — including real payment, in-app messaging, multiple product images, and analytics. Writing these down prevents any teammate from accidentally building something that wasn't agreed on."

9. **Risks and mitigations:** "Section 8 documents five project risks — Firebase quota, agent regressions, scope creep, teammate availability, and Maps misconfiguration — each with a likelihood rating and a concrete mitigation. These aren't hypothetical; they're based on known failure modes in Flutter + Firebase student projects."

10. **What's Next:** "PR03 will implement `app_theme.dart` and `app_constants.dart`, demonstrating Flutter and Dart fundamentals through the widget tree and theme system."