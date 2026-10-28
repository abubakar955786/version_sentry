# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`version_sentry` is a published pub.dev Flutter **plugin** (not an app). It checks the live store
version of the host app against its installed version, prompts the user to update, and on Android can
download and install the update in-app via Play's in-app update API. Current version: see
`pubspec.yaml` / `CHANGELOG.md`.

It became a plugin (from a pure-Dart package) in 2.0.0 — `pubspec.yaml` declares an `android`
platform only. There is deliberately **no iOS platform code**: Apple provides no API for an app to
install its own update, and guideline 2.5.2 forbids it, so iOS always falls back to opening the store
page.

## Commands

Run from the repo root for the plugin, and from `example/` for the demo app.

```bash
flutter pub get                      # deps (run in both . and example/)
flutter analyze                      # lint (flutter_lints via analysis_options.yaml)
flutter test                         # Dart/widget tests
flutter test test/version_sentry_test.dart --plain-name 'test name'   # single test
flutter pub publish --dry-run        # pre-publish validation

cd example && flutter build apk --debug   # the only thing that compiles the Kotlin
cd example && flutter run                 # drive the plugin on a real device
```

`flutter analyze` and `flutter test` never touch `android/`. **The Kotlin only compiles during an
Android build**, so run `flutter build apk --debug` in `example/` after touching
`android/src/main/kotlin/`. That build needs network access for the Gradle distribution, the Android
Gradle Plugin and the Play library.

Store lookups only work on Android/iOS — `VersionSentry.versionSentryInfo` throws on other platforms,
and `VersionSentryWidget` checks `defaultTargetPlatform` before doing anything. Use a device or
emulator, not Chrome/desktop.

## Architecture

Four layers, each usable on its own:

1. **`lib/network_manager/network_manager.dart`** — platform-branching store lookup. iOS uses the
   iTunes Lookup API (`itunes.apple.com/lookup`, JSON). Android **scrapes the HTML of the Play Store
   listing page** and extracts version + release notes with the regexes at the top of the class. Both
   return a plain `Map` with `storeUrl` / `storeVersion` / `releaseNotes`, and return `null` (after
   `debugPrint`) on any failure rather than throwing. A cache-busting `timestamp` query param is sent
   on every request.
2. **`lib/version_sentry.dart`** — `VersionSentry.versionSentryInfo()`: reads the installed version via
   `package_info_plus`, calls `NetworkManager`, compares with `Version.parse` from the `version`
   package, and returns an immutable `VersionSentryInfo` (`lib/version_sentry_info.dart`). It never
   throws past the platform check — on error it returns an info object full of defaults
   (`storeVersion: '0.0.0'`, all flags false).
3. **`lib/auto_update/`** — the Android in-app update path, independent of layers 1–2.
   `VersionSentryAutoUpdate` wraps a method channel (`version_sentry/auto_update`: check / start /
   startImmediate / completeInstall) and an event channel
   (`version_sentry/auto_update_progress`), backed by
   `android/src/main/kotlin/com/versionsentry/VersionSentryPlugin.kt`. Platform events become
   `VersionSentryUpdateProgress` (status + byte counters + derived percentage).
4. **`lib/version_sentry_widget/`** — the drop-in UI. `VersionSentryWidget` renders `child` unchanged
   and, in a post-frame callback, runs the check and picks one prompt:
   - **major** → a pushed route holding the blocking `VersionSentryMajorUpdateScreen`
   - **minor** → `showModalBottomSheet` holding `VersionSentryUpdateSheet`
   - **patch** → the same sheet opener holding the lighter `VersionSentryPatchUpdateSheet`
   - Both screens sit inside `VersionSentryProgressBuilder`, a `StreamBuilder` over
     `request.progressStream` that re-runs the build with `request.copyWith(progress: …)`.
   - `VersionSentryWidget` has no styling hooks — the screens read the host app's `Theme`, and the
     two release-note strings are the only text knobs. Resist re-adding per-colour/per-style
     parameters; that was tried and cut back on purpose. Customisation goes through
     `onMajorUpdate` / `onMinorUpdate` / `onPatchUpdate` instead: a handler is handed the
     `VersionSentryUpdateRequest` and replaces that type's built-in screen outright, so the
     `show*` flag for it no longer applies — the flags gate only the built-in screens. The
     largest-bump rule and `minorUpdateReminder` still apply to handlers (major excepted).

### Things worth knowing before editing

- **Play Store scraping is the fragile part.** The `_versionRegex` / `_releaseRegex` patterns in
  `NetworkManager` match Google's obfuscated inline JSON and break whenever Google changes the page.
  Most pre-2.0 CHANGELOG entries are fixes here. Changes need a real Android device check — there is no
  test coverage for them.
- **Two independent sources of truth.** Layers 1–2 scrape the store version; Play's in-app update API
  (layer 3) decides availability itself and ignores the scraped value. They can disagree while a
  release rolls out. `VersionSentryWidget` uses the scrape to decide *which prompt* to show and Play to
  perform the download.
- **The in-app update flow cannot be tested from this repo.** Play only serves updates to builds
  installed from Google Play, compared against the version live on Play. A local `flutter run` build
  always reports no update available; it needs internal app sharing or an internal testing track. If
  the flow can't start, `_startUpdate` falls back to opening the store page.
- **`totalBytesToDownload` is only defined while the status is `downloading`.** So
  `VersionSentryUpdateProgress.fraction` and `.percent` are nullable by design, and null means
  "indeterminate", not zero. Don't "fix" this by defaulting to 0.
- **Update flags are not mutually exclusive.** `isMajorUpdate` / `isMinorUpdate` / `isPatchUpdate` are
  each a direct component comparison, so a 1.0.0 → 2.1.1 bump sets all three. `_resolveType()` in the
  widget takes the largest and returns, so exactly one prompt shows; a disabled flag means no prompt
  rather than falling through to a smaller type.
- **Reminder throttling** lives in `VersionSentryWidget`, not in `VersionSentry`: a single
  `SharedPreferences` int key `version_sentry_current_date_time` holds the last-shown timestamp, gated
  by `minorUpdateReminder`. Major updates deliberately ignore this gate.
- **The library file exports nothing.** `lib/version_sentry.dart` declares `library version_sentry` and
  only defines the `VersionSentry` class, so consumers import deep paths
  (`package:version_sentry/version_sentry_info.dart`,
  `package:version_sentry/auto_update/version_sentry_auto_update.dart`,
  `package:version_sentry/version_sentry_widget/version_sentry_widget.dart`) — see
  `example/lib/main.dart`. Adding exports is a public-API change; keep the deep paths working.
- **`VersionSentryUpdateRequest` is internal plumbing**, not a public extension point: it bundles
  what the two built-in screens need. It carries a `progress` snapshot plus the `progressStream`
  behind it, and `copyWith` exists only to refresh that snapshot.
- **The widget never shows the store's release notes.** It shows `majorReleaseNote`,
  `minorReleaseNote` or `patchReleaseNote` — one per update type.
  `VersionSentryInfo.releaseNotes` still carries the scraped notes for programmatic use.
- **Tests cover only what runs without a device:** `VersionSentryInfo` serialization and update-type
  precedence, the status/percentage model, `VersionSentryButtonWidget` and
  `VersionSentryPatchUpdateSheet`. The widget's own handler/flag routing isn't covered — it sits
  behind `VersionSentry.versionSentryInfo()`, which throws on the host VM.
  `VersionSentry.versionSentryInfo()` throws on the host VM (neither Android nor iOS) and the method
  channels aren't registered there, so neither can be unit-tested as written — verify on a device.
- **Build artifacts are committed** (14 files under `build/ios/XCBuildData/` and `.dart_tool/`) and
  there is no root `.gitignore`, so builds leave untracked noise. Stage files explicitly.

## Publishing

Bump `version:` in `pubspec.yaml` and add a `CHANGELOG.md` entry in the same change — pub.dev scoring
depends on both. README screenshots are served from raw GitHub URLs on `main`, so images must be
committed before a release.
