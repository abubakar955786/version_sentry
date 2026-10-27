import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';

/// Drives Play's in-app update flow, and reports where it has got to.
///
/// Android only. Every method is safe to call on other platforms — they report
/// "no update available" rather than throwing, so callers don't need their own
/// platform checks.
///
/// Play only serves updates to builds installed from Google Play, and compares
/// against the version live on Play. A local `flutter run` build always reports
/// no update available; test through internal app sharing or an internal
/// testing track.
class VersionSentryAutoUpdate {
  VersionSentryAutoUpdate._();

  static const MethodChannel _methods =
      MethodChannel('version_sentry/auto_update');
  static const EventChannel _events =
      EventChannel('version_sentry/auto_update_progress');

  static Stream<VersionSentryUpdateProgress>? _progress;

  /// Whether this platform can run an in-app update at all.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Status ticks for the running update, including the download percentage.
  ///
  /// This is a broadcast stream, so listening late means missing earlier ticks.
  /// Subscribe before calling [start]. On unsupported platforms it is empty.
  ///
  /// ```dart
  /// VersionSentryAutoUpdate.progress.listen((p) {
  ///   print('${p.status.name} ${p.percent ?? '-'}%');
  ///   if (p.status.isReadyToInstall) VersionSentryAutoUpdate.completeInstall();
  /// });
  /// ```
  static Stream<VersionSentryUpdateProgress> get progress {
    if (!isSupported) return const Stream<VersionSentryUpdateProgress>.empty();

    return _progress ??= _events.receiveBroadcastStream().map((dynamic event) {
      return VersionSentryUpdateProgress.fromEvent(event as Map<dynamic, dynamic>);
    }).handleError((Object error) {
      debugPrint('VersionSentry auto update stream error: $error');
    });
  }

  /// Whether Play has an update ready for this app.
  ///
  /// This is Play's own answer and is independent of the store version
  /// `VersionSentry.versionSentryInfo()` scrapes — the two can disagree while a
  /// release is still rolling out.
  static Future<bool> isUpdateAvailable() async {
    final details = await check();
    return details?['available'] == true;
  }

  /// The raw Play update details, or null if they can't be read.
  ///
  /// Includes `available`, `flexibleAllowed`, `immediateAllowed`,
  /// `availableVersionCode`, `installStatus`, `stalenessDays` and `priority`.
  static Future<Map<String, dynamic>?> check() async {
    if (!isSupported) return null;

    try {
      final result = await _methods.invokeMapMethod<String, dynamic>('checkForUpdate');
      return result;
    } on PlatformException catch (e) {
      /// Thrown when the build wasn't installed from Play, which is the normal
      /// case during local development.
      debugPrint('VersionSentry: in-app update check failed (${e.code}) ${e.message}');
      return null;
    } on MissingPluginException {
      debugPrint('VersionSentry: in-app update is not available on this platform');
      return null;
    }
  }

  /// Starts a background download, keeping the app usable.
  ///
  /// Play shows its own confirmation dialog first. Returns true once the user
  /// accepts, false if they dismiss it or no update is available. Watch
  /// [progress] for the percentage, then call [completeInstall] when the status
  /// reaches [VersionSentryUpdateStatus.downloaded].
  static Future<bool> start() => _start('startFlexibleUpdate');

  /// Hands the whole flow to Play's own blocking full-screen UI.
  ///
  /// Play downloads, installs and restarts the app itself, so [progress]
  /// reports nothing useful here. Use [start] if you want to render the
  /// percentage yourself.
  static Future<bool> startImmediate() => _start('startImmediateUpdate');

  /// Installs a finished download and restarts the app.
  ///
  /// Only meaningful once [progress] has reported
  /// [VersionSentryUpdateStatus.downloaded]. Called in the foreground it shows
  /// Play's install UI; called while backgrounded it installs silently.
  static Future<void> completeInstall() async {
    if (!isSupported) return;

    try {
      await _methods.invokeMethod<void>('completeInstall');
    } on PlatformException catch (e) {
      debugPrint('VersionSentry: completeInstall failed (${e.code}) ${e.message}');
    } on MissingPluginException {
      debugPrint('VersionSentry: in-app update is not available on this platform');
    }
  }

  static Future<bool> _start(String method) async {
    if (!isSupported) return false;

    try {
      return await _methods.invokeMethod<bool>(method) ?? false;
    } on PlatformException catch (e) {
      debugPrint('VersionSentry: $method failed (${e.code}) ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('VersionSentry: in-app update is not available on this platform');
      return false;
    }
  }
}
