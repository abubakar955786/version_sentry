Version Sentry
================

A Flutter package to help apps stay up-to-date by fetching the latest version from the Play Store
(Android) or App Store (iOS) — and, on Android, downloading and installing the update inside your app
with live progress.

## 📱 Screenshots

| Patch & Minor Update                                                                                              | Major Update                                                                                                       |
|-------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| ![patch_update](https://raw.githubusercontent.com/abubakar955786/version_sentry/main/screenshots/patch_update.png) | ![major_update](https://raw.githubusercontent.com/abubakar955786/version_sentry/main/screenshots/major_update.png) |

-----

## Understanding the version numbers

Version Sentry reads your version as **semantic versioning**, the `major.minor.patch` scheme Flutter
uses in `pubspec.yaml`. Take version **`1.2.3`**:

```
    1   .   2   .   3
    │       │       │
    │       │       └── patch  → bug fixes only, nothing new to learn
    │       └────────── minor  → new features, still backwards compatible
    └────────────────── major  → breaking or mandatory changes
```

Version Sentry compares your installed version against the store version and tells you **which of the
three numbers moved**:

| Installed | Store   | Moved | Flag             | Meaning                                       |
|-----------|---------|-------|------------------|-----------------------------------------------|
| `1.2.3`   | `2.0.0` | major | `isMajorUpdate`  | Breaking change — the user must update        |
| `1.2.3`   | `1.3.0` | minor | `isMinorUpdate`  | New features — worth telling the user         |
| `1.2.3`   | `1.2.4` | patch | `isPatchUpdate`  | Bug fixes — usually not worth interrupting    |

### One release can move more than one number

This catches people out. The three flags are **independent comparisons**, not a single category.
Going from `1.0.0` to `2.1.1` moves *all three* numbers, so all three flags are `true`:

```dart
info.isMajorUpdate; // true  (1 → 2)
info.isMinorUpdate; // true  (0 → 1)
info.isPatchUpdate; // true  (0 → 1)
```

So **always check `isMajorUpdate` first**. `VersionSentryWidget` already does: the largest moved
number wins, and you get one prompt, never three.

-----

## What each update type shows

`VersionSentryWidget` picks the prompt from the update type:

| Update type | Default prompt                            | Flag              | Default |
|-------------|-------------------------------------------|-------------------|---------|
| **major**   | Blocking full-screen, cannot be dismissed | `showMajorUpdate` | `true`  |
| **minor**   | Dismissible bottom sheet                  | `showMinorUpdate` | `true`  |
| **patch**   | Compact bottom sheet, off by default      | `showPatchUpdate` | `false` |

Patch updates are silent by default — a bug-fix release rarely justifies interrupting someone. Turn
`showPatchUpdate: true` on to get the patch sheet, which is a deliberately lighter prompt than the
minor one: the title and version pair sit on a single row, and dismissing is a plain `Later` button.

Setting a flag to `false` means **no prompt for that update type**, not "fall back to a smaller one".
A major update with `showMajorUpdate: false` shows nothing.

These flags gate the built-in prompts. To show your own UI instead, pass `onMajorUpdate`,
`onMinorUpdate` or `onPatchUpdate` — see [Your own UI](#your-own-ui).

> **Upgrading from 1.x:** `showPatchAndMinorUpdate` controlled minor and patch together. It is
> replaced by `showMinorUpdate` and `showPatchUpdate`; the old flag was removed in 2.0.0.

-----

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_widget.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return VersionSentryWidget(
      autoUpdate: true,

      showMajorUpdate: true,
      showMinorUpdate: true,
      showPatchUpdate: false,

      minorUpdateReminder: const Duration(hours: 12),

      child: Scaffold(
        appBar: AppBar(title: const Text('Version Sentry')),
        body: const Text('Your Widget'),
      ),
    );
  }
}
```

That's the whole widget API. Every parameter is optional except `child`:

| Parameter                 | Default    | Purpose                                                  |
|---------------------------|------------|----------------------------------------------------------|
| `child`                   | required   | Your app. Rendered unchanged, with prompts over it       |
| `autoUpdate`              | `true`     | Download in-app instead of opening the store (Android)   |
| `showMajorUpdate`         | `true`     | Blocking full-screen prompt                              |
| `showMinorUpdate`         | `true`     | Dismissible bottom sheet                                 |
| `showPatchUpdate`         | `false`    | Same sheet, for patch releases                           |
| `minorUpdateReminder`     | `12 hours` | Throttle for minor and patch prompts only                |
| `majorReleaseNote`        | built-in   | Message on the major-update screen                       |
| `minorReleaseNote`        | built-in   | Message on the minor-update sheet                        |
| `patchReleaseNote`        | built-in   | Message on the patch-update sheet                        |
| `onMajorUpdate`           | `null`     | Your own major prompt, instead of the built-in screen    |
| `onMinorUpdate`           | `null`     | Your own minor prompt, instead of the built-in sheet     |
| `onPatchUpdate`           | `null`     | Your own patch prompt, instead of the built-in sheet     |

### Release notes

Each prompt ships with a sensible default message, so you don't have to pass anything. Override any
of the three to match your tone:

```dart
VersionSentryWidget(
  majorReleaseNote: 'This version is required to keep using the app.',
  minorReleaseNote: 'New features are waiting — update when you get a moment.',
  patchReleaseNote: 'A few fixes are ready. This one is quick.',
  child: const MyApp(),
)
```

One note per update type: major, minor and patch each have their own. The prompts show these fixed
messages rather than the store's own release notes, which keeps the wording under your control; the
store's notes are still available from `VersionSentryInfo.releaseNotes` if you want them.

The built-in screens take their colours, fonts and icon from your app's `Theme`, so they match
without any configuration.

### Your own UI

**If `onMajorUpdate`, `onMinorUpdate` or `onPatchUpdate` is not null, the built-in UI for that type is
never shown.** The callback is yours to handle however you want, and it does **not** depend on
`showMajorUpdate`, `showMinorUpdate` or `showPatchUpdate` — those three flags only control the
built-in screens that ship with the package.

So `showPatchUpdate: false` with an `onPatchUpdate` handler still calls your handler: the flag
switched off *our* patch sheet, not your code.

Each handler hands you a `BuildContext` and a `VersionSentryUpdateRequest`, and you present it however
you like — push a route, open a bottom sheet, show a dialog:

```dart
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

VersionSentryWidget(
  /// A blocking route of your own.
  onMajorUpdate: (context, request) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => MyForcedUpdateScreen(request: request)),
  ),

  /// Your own sheet.
  onMinorUpdate: (context, request) => showModalBottomSheet(
    context: context,
    builder: (_) => MyUpdateSheet(request: request),
  ),

  /// Patch updates are silent by default — a handler still reaches you.
  onPatchUpdate: (context, request) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Version ${request.info.storeVersion} is available')),
  ),

  child: const MyApp(),
)
```

The request carries everything the built-in screens use:

| On the request        | What it is                                                          |
|-----------------------|---------------------------------------------------------------------|
| `info`                | The full `VersionSentryInfo`: both versions, flags, store URL        |
| `releaseNote`         | The major, minor or patch release note, picked for this type         |
| `onUpdate()`          | Starts the in-app download, or opens the store page                  |
| `onInstall()`         | Applies a finished download and restarts the app (Android)           |
| `onDismiss()`         | Closes the prompt. A no-op for major updates, which are mandatory    |
| `progress`            | Latest download tick, or `null` when nothing is running              |
| `isBusy`              | A download or install is running, so your button should be disabled  |
| `isReadyToInstall`    | The download finished — call `onInstall()` instead of `onUpdate()`   |
| `percent`             | Download percentage, or `null` when indeterminate                    |

`progress` on the request you're handed is a snapshot. To follow a download live, wrap your widget in
`VersionSentryProgressBuilder` and it is rebuilt on every tick:

```dart
onMinorUpdate: (context, request) => showModalBottomSheet(
  context: context,
  builder: (_) => VersionSentryProgressBuilder(
    request: request,
    builder: (context, request) => MyUpdateSheet(request: request),
  ),
),
```

The full matrix, per update type:

| Handler  | Flag    | Result                            |
|----------|---------|-----------------------------------|
| set      | `true`  | Your UI                           |
| set      | `false` | Your UI                           |
| `null`   | `true`  | The built-in screen               |
| `null`   | `false` | Nothing is shown                  |

Two rules carry over unchanged: the largest moved number still wins, so a 1.0.0 -> 2.1.1 release
calls `onMajorUpdate` only; and `minorUpdateReminder` still throttles minor and patch handlers, so
yours fires at most once per interval. Pass `Duration.zero` to be called on every launch. Major
handlers are never throttled.

-----

## Auto update (Android)

With `autoUpdate: true` — the default — tapping **Update** downloads the new version **inside your
app** instead of sending the user to the store. The built-in screens show a progress bar and a
percentage, and the button becomes **Install** when the download finishes.

It uses Google Play's official in-app update API, so it stays within Play policy.

**Requirements and limits, please read:**

- **Android only.** iOS provides no API for an app to install its own update, and App Store guideline
  2.5.2 forbids it. On iOS `autoUpdate` is ignored and the App Store page opens instead.
- **The app must be installed from Google Play.** Play compares against the version live on Play, so a
  local `flutter run` build always reports no update available. Test through
  [internal app sharing](https://play.google.com/console/internal-app-sharing/) or an internal
  testing track.
- **Android 5.0 (API 21) or higher.**
- **Play shows its own confirmation dialog** before downloading. A completely silent update is not
  possible, by design.
- If the in-app flow can't start for any reason, Version Sentry falls back to opening the store page,
  so the Update button always does something.

Set `autoUpdate: false` to keep the 1.x behaviour of opening the store page.

### Driving it yourself

You don't need the widget. `VersionSentryAutoUpdate` is a standalone API that reports the status and
percentage, and installs on demand:

```dart
import 'package:version_sentry/auto_update/version_sentry_auto_update.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';
import 'package:version_sentry/version_sentry.dart';

/// Subscribe BEFORE starting, or you'll miss the first ticks.
VersionSentryAutoUpdate.progress.listen((progress) {
  print(progress.status.name); // pending, downloading, downloaded, installing, installed…
  print(progress.percent);     // 0–100, or null while indeterminate
  print(progress.label);        // 'Downloading… 42%'

  if (progress.status.isReadyToInstall) {
    VersionSentryAutoUpdate.completeInstall(); // installs and restarts the app
  }
});

final info = await VersionSentry.versionSentryInfo();

if (info?.needsUpdate ?? false) {
  await VersionSentryAutoUpdate.start();
}
```

**The status flow**

```
pending → downloading → downloaded → installing → installed
             │              │
             └──────────────┴────→ failed / canceled
```

| Status            | What it means                                                       |
|-------------------|---------------------------------------------------------------------|
| `pending`         | Play accepted the request and is about to download                  |
| `downloading`     | Bytes arriving — the only status with a real `percent`              |
| `downloaded`      | Finished, waiting for `completeInstall()`                           |
| `installing`      | `completeInstall()` was called, Play is applying the update         |
| `installed`       | Applied; the app restarts into the new version                      |
| `failed`          | Play could not complete the update                                  |
| `canceled`        | The user dismissed Play's dialog                                    |

`percent` is `null` whenever the total size isn't known — Play only reports a total while the status
is `downloading`. Show an indeterminate spinner in that case rather than a 0% bar; `progress.fraction`
is `null` for exactly the same reason and feeds straight into `LinearProgressIndicator(value: …)`.

| Member                        | Purpose                                                        |
|-------------------------------|----------------------------------------------------------------|
| `isSupported`                 | `true` only on Android                                         |
| `isUpdateAvailable()`         | Whether Play has an update for this app                        |
| `check()`                     | Raw Play details: version code, staleness days, priority       |
| `progress`                    | Broadcast stream of status + percentage                        |
| `start()`                     | Background download, keeps the app usable                      |
| `startImmediate()`            | Play's own blocking full-screen flow, no custom progress       |
| `completeInstall()`           | Installs a finished download and restarts                      |

> Play's availability check is its own answer and is **independent** of the store version Version
> Sentry scrapes. The two can disagree briefly while a release rolls out.

-----

-----

## Check for App Updates Programmatically

You can also get version details and use them according to your requirement:

```dart
import 'package:version_sentry/version_sentry.dart';
import 'package:version_sentry/version_sentry_info.dart';

void main() async {
  VersionSentryInfo? versionSentryInfo = await VersionSentry.versionSentryInfo();

  print(versionSentryInfo?.currentVersion); // 1.0.0
  print(versionSentryInfo?.storeVersion);   // 1.4.20
  print(versionSentryInfo?.needsUpdate);    // true
  print(versionSentryInfo?.isMajorUpdate);  // false
  print(versionSentryInfo?.isMinorUpdate);  // true
  print(versionSentryInfo?.isPatchUpdate);  // true
  print(versionSentryInfo?.releaseNotes);   // Improve Design
  print(versionSentryInfo?.packageName);    // com.example.example
  print(versionSentryInfo?.platform);       // iOS
  print(versionSentryInfo?.storeUrl);       // https://apps.apple.com/app/id123456789
}
```

`versionSentryInfo()` never throws on a network or parsing failure — it returns an object with
`storeVersion: '0.0.0'` and every flag `false`, so a store outage can't crash your app.

-----

## The reminder interval

`minorUpdateReminder` (default 12 hours) throttles **minor and patch prompts only**, using a single
`SharedPreferences` timestamp. Major updates are mandatory, so they prompt on every launch regardless.

It applies to `onMinorUpdate` and `onPatchUpdate` handlers as well, so a custom prompt is throttled
the same way the built-in sheet is. Pass `Duration.zero` if you want to be called on every launch and
handle the cadence yourself.

-----

Features
--------
1. Fetches the latest version from the Play Store (Android) or App Store (iOS)
2. Provides information about the current version, store version, and update requirements
3. Looks the app up in the device's own storefront and language, taken from the OS locale
4. Separate prompts for major, minor and patch updates, each individually switchable
5. In-app download and install on Android, with live status and download percentage
6. Built-in screens that follow your app's `Theme`, with overridable release notes
