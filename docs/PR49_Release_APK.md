# PR49 – Release APK — Build Configuration + Signed APK

**Project:** CraftBridge
**PR Number:** 49 of 51
**Assigned To:** Member 3
**Type:** TYPE B – Fully Agent-Executable PR

---

## Section 1 – PR Title

Configure Android release signing, generate a keystore, update `build.gradle` with signing config, build a signed release APK, and produce the release build documentation.

---

## Section 2 – Assignments Covered

- Assignment 3.49 — Release APK — Build Configuration + Signed APK

---

## Section 3 – Objective

This PR produces a signed release APK for CraftBridge — the distributable Android binary that can be uploaded to the Google Play Store in PR50. It covers keystore generation, `build.gradle` signing configuration, ProGuard/R8 minification settings, and the `flutter build apk --release` command. A `docs/PR49_Release_APK.md` document is produced recording all build steps, the signing configuration, and the APK output details. No Dart files are modified — this is a build configuration PR.

---

## Section 4 – Architecture Context

```
Release build pipeline:

keytool (Java)
  └── generates craft_bridge_keystore.jks
        ├── alias: craft_bridge_key
        ├── validity: 10000 days
        └── stored: android/app/craft_bridge_keystore.jks

android/key.properties (NEW — gitignored)
  └── storeFile=craft_bridge_keystore.jks
  └── storePassword=<password>
  └── keyAlias=craft_bridge_key
  └── keyPassword=<password>

android/app/build.gradle (updated)
  └── signingConfigs.release
        └── reads from key.properties
  └── buildTypes.release
        └── signingConfig = signingConfigs.release
        └── minifyEnabled = true
        └── shrinkResources = true

flutter build apk --release
  └── output: build/app/outputs/flutter-apk/app-release.apk
  └── size: typically 20–40MB for this project

docs/PR49_Release_APK.md ← produced this PR
```

This PR sits after admin screens (PR48) and before Play Store deployment (PR50). The signed APK produced here is the artifact submitted in PR50.

---

## Section 5 – Folder Constraints

**Allowed file creation:**
- None beyond build artifacts. No new Dart files.

**Allowed file modification:**
- `android/app/build.gradle` — signing config added
- `android/.gitignore` — `key.properties` added to gitignore
- `docs/PR49_Release_APK.md` — new document in existing `docs/` directory

**Not allowed:**
- Do NOT create any new Dart files.
- Do NOT modify any model files.
- Do NOT modify `firestore_service.dart` or `storage_service.dart`.
- Do NOT modify `app_theme.dart` or `app_constants.dart`.
- Do NOT modify `main.dart`.
- Do NOT modify any provider files.
- Do NOT modify any widget or screen files.
- Do NOT modify `pubspec.yaml`.

**Files created during build (not committed to git):**
- `android/app/craft_bridge_keystore.jks` — binary keystore, gitignored
- `android/key.properties` — contains passwords, gitignored
- `build/app/outputs/flutter-apk/app-release.apk` — build output, gitignored

---

## Section 6 – Technical Requirements

---

### Keystore generation

Run the following command in the project root to generate the keystore:

```bash
keytool -genkey -v \
  -keystore android/app/craft_bridge_keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias craft_bridge_key \
  -dname "CN=CraftBridge, OU=Dev, O=CraftBridge, L=Mumbai, S=Maharashtra, C=IN"
```

When prompted for passwords, use a secure password and note it — it is needed for `key.properties`.

**Note:** `keytool` is part of the Java Development Kit (JDK). It is available if `flutter doctor` passes, as Flutter requires the JDK. If not found: `brew install --cask temurin` on macOS.

---

### `android/key.properties`

Create this file (do NOT commit to git — it contains secrets):

```
storePassword=<your_keystore_password>
keyPassword=<your_key_password>
keyAlias=craft_bridge_key
storeFile=craft_bridge_keystore.jks
```

**Note on `storeFile` path:** The path in `key.properties` is relative to `android/app/` — so `craft_bridge_keystore.jks` resolves to `android/app/craft_bridge_keystore.jks`.

---

### `android/.gitignore`

Add to `android/.gitignore` (create if it does not exist, or append if it does):

```
key.properties
**/*.jks
**/*.keystore
```

This ensures the keystore binary and key.properties are never committed to git.

---

### `android/app/build.gradle`

Add signing configuration. Locate the existing `build.gradle` file and make the following additions:

**Addition 1 — Load `key.properties` at the top of the file, before `android {`:**

```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**Addition 2 — Add `signingConfigs` block inside `android {`:**

```groovy
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

**Addition 3 — Update `buildTypes.release` to use the signing config:**

Find the existing `buildTypes` block. The `release` build type should be updated to:

```groovy
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

**Note on `minifyEnabled` and `shrinkResources`:** These enable R8 code shrinking and resource shrinking respectively. For Flutter release builds, R8 is already applied by Flutter's build system — `minifyEnabled true` in Gradle additionally applies ProGuard rules to the Java/Kotlin layer. `shrinkResources true` removes unused Android resources from the APK.

---

### Build command

After the signing configuration is in place:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The release APK is output to:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

### `docs/PR49_Release_APK.md`

A Markdown document containing all of the following sections in order.

---

#### 1. Overview

A 3–4 sentence paragraph covering: the release APK is the distributable Android binary produced by `flutter build apk --release`. It is signed with a keystore that uniquely identifies CraftBridge on the Play Store — the same key must be used for all future updates. This document records the build steps, signing configuration, and APK output details for reproducibility.

---

#### 2. Prerequisites

A bullet list covering:

- Flutter 3.19+ installed and `flutter doctor` passing with no errors.
- JDK installed (`keytool` available in PATH) — verify with `keytool -help`.
- Firebase project configured (PR04) — `google-services.json` in `android/app/`.
- Google Maps API key added to `AndroidManifest.xml` (PR40).
- All 48 previous PRs merged to `main`.
- A secure password chosen for the keystore — stored safely outside the repository (password manager recommended).

---

#### 3. Keystore Generation

A prose section covering:

- The keystore is a binary file containing the private key used to sign the APK.
- Location: `android/app/craft_bridge_keystore.jks` — gitignored.
- Alias: `craft_bridge_key`.
- Validity: 10,000 days (~27 years) — Google Play requires keys valid until at least October 2033.
- Algorithm: RSA 2048-bit.
- The `keytool` command with all parameters is shown.
- **Critical warning:** If the keystore is lost, the app can never be updated on the Play Store under the same package name. Back up the keystore file and passwords to a secure location outside the repository.

---

#### 4. Signing Configuration

A prose section covering:

- `key.properties` stores the keystore path and passwords — gitignored, never committed.
- `android/app/build.gradle` reads `key.properties` at build time to configure `signingConfigs.release`.
- The `storeFile` path in `key.properties` is relative to `android/app/` — `craft_bridge_keystore.jks` resolves correctly.
- `minifyEnabled true` enables R8 code shrinking — reduces APK size by removing unused code.
- `shrinkResources true` removes unused Android resources from the APK.
- The conditional `keystoreProperties['storeFile'] ? file(...) : null` prevents a build crash when `key.properties` is absent (e.g. on a CI server without secrets).

---

#### 5. Build Steps

A numbered list:

1. Ensure all PR48 changes are merged to `main` and the branch is up to date.
2. Generate the keystore (one-time step, skip if already exists).
3. Create `android/key.properties` with keystore credentials.
4. Verify `android/.gitignore` contains `key.properties` and `**/*.jks`.
5. Run `flutter clean` to clear cached build artifacts.
6. Run `flutter pub get` to ensure all dependencies are resolved.
7. Run `flutter build apk --release`.
8. Verify the output at `build/app/outputs/flutter-apk/app-release.apk`.
9. Verify APK is signed: `keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk`.
10. Copy the APK to a safe location for Play Store upload in PR50.

---

#### 6. APK Output Details

A table with columns: **Property**, **Value**.

| Property | Value |
|----------|-------|
| Package name | `com.craftbridge.craft_bridge` |
| Version name | `1.0.0` (from `pubspec.yaml`) |
| Version code | `1` (from `pubspec.yaml`) |
| Min SDK | 21 (Android 5.0) |
| Target SDK | 34 (Android 14) |
| Signing key alias | `craft_bridge_key` |
| Key algorithm | RSA 2048 |
| Build type | release |
| Output path | `build/app/outputs/flutter-apk/app-release.apk` |
| Approximate size | 25–40 MB |

---

#### 7. Troubleshooting

A table with columns: **Error**, **Cause**, **Fix**.

| Error | Cause | Fix |
|-------|-------|-----|
| `keytool: command not found` | JDK not installed or not in PATH | Install JDK: `brew install --cask temurin` |
| `key.properties not found` | File not created or wrong path | Ensure `key.properties` is in `android/` (not `android/app/`) |
| `Keystore file not found` | `storeFile` path incorrect in `key.properties` | Use filename only (`craft_bridge_keystore.jks`) — path is relative to `android/app/` |
| `Signing failed — wrong password` | Incorrect `storePassword` or `keyPassword` | Verify passwords match what was used during `keytool -genkey` |
| `Build failed: resource shrinking requires minification` | `shrinkResources true` without `minifyEnabled true` | Ensure both are set in `buildTypes.release` |
| `DexException` or multidex error | Too many methods for single dex | Add `multiDexEnabled true` to `defaultConfig` in `build.gradle` |

---

## Section 7 – Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | `android/app/build.gradle` | Signing config with `key.properties` loader, `signingConfigs.release`, `minifyEnabled`, `shrinkResources` |
| 2 | `android/.gitignore` | `key.properties` and `*.jks` patterns added |
| 3 | `docs/PR49_Release_APK.md` | Complete release build documentation with all 7 sections |
| 4 | `build/app/outputs/flutter-apk/app-release.apk` | Signed release APK (not committed to git — build artifact) |

---

## Section 8 – Setup and Implementation Instructions

### Part 1 – Manual Setup

> No manual setup required for this PR. Proceed to Part 2.

---

### Part 2 – Agent Implementation Instructions

The agent must complete all build configuration steps and produce the documentation.

---

**Step 1: Generate the keystore**

Run:
```bash
keytool -genkey -v \
  -keystore android/app/craft_bridge_keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias craft_bridge_key \
  -dname "CN=CraftBridge, OU=Dev, O=CraftBridge, L=Mumbai, S=Maharashtra, C=IN" \
  -storepass craftbridge2024 \
  -keypass craftbridge2024
```

**Note:** The passwords `craftbridge2024` are used here for the student project demo. In a real deployment, use a strong unique password and store it in a password manager.

---

**Step 2: Create `android/key.properties`**

Write the file with content:
```
storePassword=craftbridge2024
keyPassword=craftbridge2024
keyAlias=craft_bridge_key
storeFile=craft_bridge_keystore.jks
```

---

**Step 3: Update `android/.gitignore`**

Append to `android/.gitignore`:
```
key.properties
**/*.jks
**/*.keystore
```

---

**Step 4: Update `android/app/build.gradle`**

Make three targeted additions as specified in Section 6:
1. Add `keystoreProperties` loader block before `android {`.
2. Add `signingConfigs.release` block inside `android {`.
3. Update `buildTypes.release` to use signing config with `minifyEnabled true` and `shrinkResources true`.

---

**Step 5: Build the release APK**

```bash
flutter clean
flutter pub get
flutter build apk --release
```

Confirm the build completes successfully. If it fails:
- Check that `key.properties` is in `android/` and `craft_bridge_keystore.jks` is in `android/app/`.
- Check for ProGuard/R8 errors — if any Flutter plugin causes issues, add `-keep` rules to `android/app/proguard-rules.pro`.
- If multidex errors occur, add `multiDexEnabled true` to `defaultConfig`.

---

**Step 6: Verify the APK is signed**

```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

Confirm the output shows `craft_bridge_key` alias and the certificate details.

---

**Step 7: Write `docs/PR49_Release_APK.md`**

Write the complete Markdown document with all 7 sections as specified in Section 6.

---

### Part 3 – Verification and Quality Gate

1. **Run `flutter analyze`**
   ```
   flutter analyze
   ```
   Required result: `No issues found!`. No Dart files were modified — this must pass identically to PR48.

2. **Verify keystore exists**
   ```
   ls -la android/app/craft_bridge_keystore.jks
   ```
   Must exist and be non-empty (typically 2–3KB).

3. **Verify `key.properties` exists**
   ```
   ls android/key.properties
   ```
   Must exist.

4. **Verify `key.properties` is gitignored**
   ```
   git check-ignore -v android/key.properties
   ```
   Must return a line confirming the file is ignored.

5. **Verify `*.jks` is gitignored**
   ```
   git check-ignore -v android/app/craft_bridge_keystore.jks
   ```
   Must return a line confirming the file is ignored.

6. **Verify `build.gradle` has signing config**
   ```
   grep 'signingConfigs\|keystoreProperties\|minifyEnabled' android/app/build.gradle
   ```
   Must return at least three lines.

7. **Verify APK exists and is reasonable size**
   ```
   ls -lh build/app/outputs/flutter-apk/app-release.apk
   ```
   Must exist with size > 10MB (a valid Flutter release APK is typically 15–50MB).

8. **Verify APK is signed**
   ```
   keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
   ```
   Output must contain the certificate details with `craft_bridge_key` alias.

9. **Verify document has 7 sections**
   ```
   cat docs/PR49_Release_APK.md
   ```
   Confirm all 7 sections are present. Confirm Section 6 has the APK output details table. Confirm Section 7 has the troubleshooting table.

10. **Verify gitignored files are not staged**
    ```
    git status
    ```
    Confirm `android/key.properties` and `android/app/craft_bridge_keystore.jks` do NOT appear in the staged or unstaged changes — they must be gitignored.

11. **Verify only correct files are staged**
    ```
    git diff --name-only
    ```
    Expected: `android/app/build.gradle`, `android/.gitignore`, `docs/PR49_Release_APK.md`. The keystore, `key.properties`, and APK binary must NOT appear.

12. **Confirm all Section 9 acceptance criteria pass as binary checks** before pushing.

**If any check fails:**
- Attempt to fix and re-run once.
- If still failing, output:

  ```
  VERIFICATION FAILED — DO NOT MERGE
  PR: 49
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
git commit -m "PR49: Release APK — Build Configuration + Signed APK"
git push origin pr49-release-apk
```

---

## Section 9 – Acceptance Criteria

- [ ] `android/app/craft_bridge_keystore.jks` exists and is non-empty.
- [ ] `android/key.properties` exists with correct keystore credentials.
- [ ] Both `key.properties` and `**/*.jks` are listed in `android/.gitignore` — neither file appears in `git status`.
- [ ] `android/app/build.gradle` contains `keystoreProperties` loader, `signingConfigs.release` block, and `buildTypes.release` with `signingConfig`, `minifyEnabled true`, `shrinkResources true`.
- [ ] `flutter build apk --release` completes without errors.
- [ ] `build/app/outputs/flutter-apk/app-release.apk` exists and is greater than 10MB.
- [ ] `keytool -printcert -jarfile app-release.apk` confirms the APK is signed with `craft_bridge_key`.
- [ ] `docs/PR49_Release_APK.md` exists with all 7 sections including keystore warning, troubleshooting table, and APK output details table.
- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] The app compiles and runs without errors on the emulator.

---

## Section 10 – Video Explanation Talking Points

1. **Introduction:** "This is PR49 for CraftBridge. I configured the Android release signing pipeline — generating a keystore, updating `build.gradle` with the signing configuration, enabling R8 code shrinking, and building a signed release APK that is ready for Play Store submission."

2. **Why APK signing is required:** "Google Play requires every APK to be signed with a developer key. The signature proves the APK came from the same developer as the original upload — it's how Android ensures app updates come from legitimate sources. An unsigned APK cannot be installed from the Play Store and will trigger a security warning on device sideloading."

3. **Keystore as the developer's identity:** "The keystore file contains the private key used to sign the APK. Once an app is published on the Play Store with a particular key, all future updates must be signed with the same key — it's how Google knows they're from the same developer. If the keystore is lost, the app can never be updated on the Play Store under the same package name. The critical warning in Section 3 of the documentation emphasises: back up the keystore outside the repository."

4. **`key.properties` gitignore pattern:** "`key.properties` contains the keystore password in plaintext — committing it to a public repository would expose the signing key to anyone who can read the repository. Adding it to `.gitignore` ensures it never appears in `git status` or `git add`. The `**/*.jks` pattern ignores the binary keystore file itself. This separation of secrets from code is fundamental security hygiene."

5. **`keystoreProperties` conditional in `build.gradle`:** "The `keystoreProperties['storeFile'] ? file(...) : null` conditional prevents a NullPointerException when `key.properties` doesn't exist — for example, on a CI server that hasn't been configured with the keystore secret. Without this conditional, any developer cloning the repository and running a release build without `key.properties` would get a Gradle build error instead of a clear 'signing not configured' message."

6. **`minifyEnabled true` and `shrinkResources true`:** "`minifyEnabled true` enables R8 code shrinking — the Dart code is already compiled to native by Flutter, but the Java/Kotlin layer (Firebase SDKs, Google Maps, Geolocator) benefits from unused class removal. `shrinkResources true` removes unused Android resources — images, strings, layouts that come from SDKs but aren't used by the app. Together they typically reduce APK size by 20–40%."

7. **`flutter build apk --release` vs `flutter build appbundle`:** "This PR produces an APK — a single file that can be sideloaded or uploaded to the Play Store. Google now prefers Android App Bundles (`.aab`) for Play Store submissions — they allow Google to serve device-optimised splits. For a student project, an APK is simpler and demonstrates the same signing and build concepts. PR50 discusses the `.aab` option."

8. **Verifying the signed APK:** "`keytool -printcert -jarfile app-release.apk` reads the signing certificate from the APK's manifest and prints the issuer, validity, and fingerprint. Confirming the `craft_bridge_key` alias appears in the output proves the APK was signed with the correct key — not an accidentally unsigned debug build or a differently-keyed CI build."

9. **R8 and Firebase compatibility:** "Firebase SDKs are tested with R8 and ship ProGuard keep rules in their AARs — Firebase Auth, Firestore, Storage, and Messaging all work with `minifyEnabled true` without additional ProGuard configuration. Google Maps and Geolocator similarly ship their own keep rules. The troubleshooting section covers the rare case where a plugin causes R8 issues."

10. **What's Next:** "PR50 will produce the Play Store deployment reflection document — covering the store listing steps, screenshots, content rating, and a project reflection on what was built across all 51 PRs."