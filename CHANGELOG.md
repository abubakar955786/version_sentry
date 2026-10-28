## 2.0.0

### Added
- **Auto update on Android.** `autoUpdate` on `VersionSentryWidget` (default `true`) downloads the
  update inside the app via Google Play's in-app update API instead of opening the store page.
- **`VersionSentryAutoUpdate`**, a standalone API reporting the install status
  (`pending` / `downloading` / `downloaded` / `installing` / `installed` / `failed` / `canceled`) and
  the download percentage, plus `completeInstall()` to apply a finished download.
- `showMinorUpdate` and `showPatchUpdate`, replacing the combined flag. Patch updates are now silent
  by default; minor updates still show the bottom sheet.
- `majorReleaseNote`, `minorReleaseNote` and `patchReleaseNote`, one per update type, each with a
  built-in default message.
- **A dedicated patch sheet**, `VersionSentryPatchUpdateSheet`. Patch releases no longer reuse the
  minor sheet: the new one is compact — title and version pair on one row, a plain `Later` button —
  since a bug-fix release rarely earns a full-width interruption. Still off by default
  (`showPatchUpdate: false`), and it drives the same update flow.
- The built-in screens now show a download progress bar and the current version pair.
- **`onMajorUpdate`, `onMinorUpdate` and `onPatchUpdate`** on `VersionSentryWidget`, for showing your
  own prompt instead of a built-in screen. Each is handed a `BuildContext` and the same
  `VersionSentryUpdateRequest` the built-in screens use, so a custom screen drives the same flow.
  A handler replaces the built-in screen outright and the matching `show*` flag no longer applies —
  the flags only gate the built-in screens. `minorUpdateReminder` still throttles minor and patch
  handlers; major handlers fire on every launch.

### Fixed
- `showMajorUpdate` and `showPatchAndMinorUpdate` were accepted but never read, so both prompts
  always showed.
- A bump moving several version numbers at once (1.0.0 -> 2.1.1) pushed the blocking major screen and
  then stacked the bottom sheet on top of it. The largest moved number now wins outright.
- The update prompts could be shown after the host widget was disposed, crashing the app.
- `showStaticReleaseNotes: false` left the release notes empty instead of showing the store's notes.
- `releaseNotes` fell back to the string `'0.0.0'` when a store lookup failed.
- Failing to open a store URL threw a raw `String`; it now logs and returns.
- The major-update screen no longer replaces the host route, and blocks the back button instead.

### Breaking
- **This package is now a Flutter plugin with Android platform code.** It requires
  Android `minSdk 21`, Dart `3.6.0` and Flutter `3.27.0`.
- `autoUpdate` defaults to `true`, so on Android the Update button now downloads in-app rather than
  opening the store page. Pass `autoUpdate: false` for the 1.x behaviour.
- **`VersionSentryWidget` was cut back to twelve parameters.** It now takes `child`, `autoUpdate`,
  `showMajorUpdate`, `showMinorUpdate`, `showPatchUpdate`, `minorUpdateReminder`, `majorReleaseNote`,
  `minorReleaseNote`, `patchReleaseNote`, `onMajorUpdate`, `onMinorUpdate` and `onPatchUpdate` —
  nothing else. All the styling parameters are gone; custom UI goes through the three handlers.
- **`reminderEvery` is renamed `minorUpdateReminder`**, and is no longer nullable — it defaults to
  12 hours. The name now says which prompts it throttles: minor and patch, never major.
- `showPatchAndMinorUpdate` is replaced by `showMinorUpdate` / `showPatchUpdate`. **Patch updates no
  longer prompt by default** — set `showPatchUpdate: true` to restore that.
- All styling parameters were removed: `titleStyle`, `releaseNotesTextStyle`, `backgroundColor`,
  `appBarColor`, `primacyColor`, `iconWidget`, `updateButtonStyle`, `cancelButtonStyle`,
  `updateButtonText`, `cancelButtonText`. The built-in screens follow the app's `Theme` instead.
- The `releaseNotes` widget parameter, `sowStaticReleaseNotes` and `showStaticReleaseNotes` were
  removed in favour of the `majorReleaseNote` / `minorReleaseNote` strings.
- `packageName`, `bundleId` and `androidHtmlReleaseNotes` were removed from the widget. They remain
  on `VersionSentry.versionSentryInfo()`.
- **`iOSAppStoreCountry` and `androidPlayStoreCountry` were removed**, from both the widget and
  `VersionSentry.versionSentryInfo()`. The storefront and page language now come from the device's
  own locale (`Platform.localeName`): the region subtag becomes the App Store `country`, and the full
  locale becomes the Play Store `hl`. A device reporting no region keeps Apple's default storefront,
  and an unreadable locale falls back to `en_US` on Play.
- `VersionSentryWidget` no longer wraps `child` in its own `Scaffold`, which previously nested a
  second one inside your app.
- `VersionSentryMajorUpdateScreen` and the bottom sheet now take a single
  `VersionSentryUpdateRequest` instead of a long parameter list.

## 1.4.0
- Fix Apple Store or Play Store Url

## 1.3.0
- Improved Play Store scraping
- Fixed update check issues

## 0.0.1

* TODO: Describe initial release.
