# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`version_sentry` is a published pub.dev Flutter **package** (not an app). It checks the live store version of the host app against its installed version and prompts the user to update. Current version: see `pubspec.yaml` / `CHANGELOG.md`.

## Commands

Run from the repo root for the package, and from `example/` for the demo app.

```bash
flutter pub get                      # deps (run in both . and example/)
flutter analyze                      # lint (flutter_lints via analysis_options.yaml)
flutter test                         # package tests
flutter test test/version_sentry_test.dart --plain-name 'test name'   # single test
flutter pub publish --dry-run        # pre-publish validation

cd example && flutter run            # drive the package on a real device
```

Store lookups only work on Android/iOS — `VersionSentry.versionSentryInfo` throws on other platforms, and `VersionSentryWidget` no-ops under `kIsWeb`. Use a device or emulator, not Chrome/desktop.

## Architecture

Three layers, each usable on its own:

1. **`lib/network_manager/network_manager.dart`** — platform-branching store lookup. iOS uses the iTunes Lookup API (`itunes.apple.com/lookup`, JSON). Android **scrapes the HTML of the Play Store listing page** and extracts version + release notes with the regexes at the top of the class. Both return a plain `Map` with `storeUrl` / `storeVersion` / `releaseNotes`, and return `null` (after `debugPrint`) on any failure rather than throwing. A cache-busting `timestamp` query param is sent on every request.
2. **`lib/version_sentry.dart`** — `VersionSentry.versionSentryInfo()`: reads the installed version via `package_info_plus`, calls `NetworkManager`, compares with `Version.parse` from the `version` package, and returns an immutable `VersionSentryInfo` (`lib/version_sentry_info.dart`). It never throws past the platform check — on error it returns an info object full of defaults (`storeVersion: '0.0.0'`, all flags false).
3. **`lib/version_sentry_widget/`** — the drop-in UI. `VersionSentryWidget` wraps the host's `child` in a `Scaffold`, and in a post-frame callback kicks off the check, then branches:
   - **major update** → `Navigator.pushReplacement` to the full-screen, non-dismissible `VersionSentryMajorUpdateScreen` (`major_update_screen.dart`)
   - **minor or patch** → `patchOrMinorUpdateBottomSheet` (`bottom_sheet.dart`), a dismissible modal sheet
   - Both use `VersionSentryButtonWidget` (`button_widget.dart`) and open `storeUrl` with `url_launcher`.

### Things worth knowing before editing

- **Play Store scraping is the fragile part.** The `_versionRegex` / `_releaseRegex` patterns in `NetworkManager` match Google's obfuscated inline JSON and break whenever Google changes the page. Most CHANGELOG entries are fixes here. Changes need a real Android device check — there is no test coverage for them.
- **Both `showMajorUpdate` and `showPatchAndMinorUpdate` gate their own prompt only.** A major update with `showMajorUpdate: false` shows nothing, rather than falling back to the bottom sheet.
- **Reminder throttling** lives in `VersionSentryWidget`, not in `VersionSentry`: a single `SharedPreferences` int key `version_sentry_current_date_time` holds the last-shown timestamp, gated by `reminderEvery`. The major-update screen deliberately ignores this gate.
- **The library file exports nothing.** `lib/version_sentry.dart` declares `library version_sentry` and only defines the `VersionSentry` class, so consumers import deep paths (`package:version_sentry/version_sentry_info.dart`, `package:version_sentry/version_sentry_widget/version_sentry_widget.dart`) — see `example/lib/main.dart`. Adding exports is a public-API change; keep the deep paths working.
- **Update flags are not mutually exclusive.** `isMajorUpdate` / `isMinorUpdate` / `isPatchUpdate` are each a direct component comparison, so a 1.0.0 → 2.1.1 bump sets all three. Downstream code must check major first; `init()` in the widget returns after the major branch so the sheet never stacks on top of it.
- **`sowStaticReleaseNotes` is a misspelling kept for compatibility.** `showStaticReleaseNotes` is the real parameter; the old one is `@Deprecated` and still honoured via `useStaticReleaseNotes` in the widget state (`showStaticReleaseNotes ?? sowStaticReleaseNotes ?? true`). Don't remove it outside a major version bump.
- **Tests cover only what runs without a device:** `VersionSentryInfo` serialization/update-type precedence and `VersionSentryButtonWidget`. `VersionSentry.versionSentryInfo()` throws on the host VM (neither Android nor iOS), so it can't be unit-tested as written — verify it on a device.

## Publishing

Bump `version:` in `pubspec.yaml` and add a `CHANGELOG.md` entry in the same change — pub.dev scoring depends on both. README screenshots are served from raw GitHub URLs on `main`, so images must be committed before a release.
