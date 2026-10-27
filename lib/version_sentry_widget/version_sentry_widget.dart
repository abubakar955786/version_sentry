import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version_sentry/auto_update/version_sentry_auto_update.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';
import 'package:version_sentry/version_sentry.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'package:version_sentry/version_sentry_widget/bottom_sheet.dart';
import 'package:version_sentry/version_sentry_widget/major_update_screen.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_progress_builder.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

/// Wraps [child] and prompts for an update when the store has a newer version.
///
/// Which prompt appears depends on which number of `major.minor.patch` moved:
///
/// | Bump  | Prompt                           | Flag               | Default |
/// |-------|----------------------------------|--------------------|---------|
/// | major | blocking full-screen             | [showMajorUpdate]  | `true`  |
/// | minor | dismissible bottom sheet         | [showMinorUpdate]  | `true`  |
/// | patch | same bottom sheet                | [showPatchUpdate]  | `false` |
///
/// A release can move more than one number at once, in which case the largest
/// wins: 1.0.0 -> 2.1.1 is one major update, not three prompts.
///
/// ```dart
/// VersionSentryWidget(
///   autoUpdate: true,
///   showMajorUpdate: true,
///   showMinorUpdate: true,
///   showPatchUpdate: false,
///   reminderEvery: const Duration(hours: 12),
///   child: const MyApp(),
/// )
/// ```
class VersionSentryWidget extends StatefulWidget {
  /// The app this widget wraps. Rendered unchanged, with prompts shown over it.
  final Widget child;

  /// Download the update inside the app instead of opening the store page.
  ///
  /// Android only: it needs Play's in-app update API, so on iOS — and for
  /// builds not installed from Play — it falls back to opening the store page.
  final bool autoUpdate;

  /// Show the blocking full-screen prompt when the major number moves.
  final bool showMajorUpdate;

  /// Show the bottom sheet when the minor number moves.
  final bool showMinorUpdate;

  /// Show the bottom sheet when only the patch number moves.
  ///
  /// Off by default: bug-fix releases rarely justify interrupting the user.
  final bool showPatchUpdate;

  /// How long to wait before prompting again for a minor or patch update.
  ///
  /// Never applies to major updates, which prompt on every launch.
  final Duration reminderEvery;

  /// The message shown on the major-update screen.
  final String majorReleaseNote;

  /// The message shown on the minor-update sheet, and on the patch sheet when
  /// [showPatchUpdate] is on.
  final String minorReleaseNote;

  /// Two-letter App Store country, when the app is published in one store only.
  final String? iOSAppStoreCountry;

  /// Play Store language/country code, e.g. `en_IN`.
  final String? androidPlayStoreCountry;

  const VersionSentryWidget({
    super.key,
    required this.child,
    this.autoUpdate = true,
    this.showMajorUpdate = true,
    this.showMinorUpdate = true,
    this.showPatchUpdate = false,
    this.reminderEvery = const Duration(hours: 12),
    this.majorReleaseNote =
        'This update is required to keep using the app. Please update to the '
        'latest version to continue.',
    this.minorReleaseNote =
        'A new version is available with improvements and new features. Update '
        'now for the best experience.',
    this.iOSAppStoreCountry,
    this.androidPlayStoreCountry,
  });

  @override
  State<VersionSentryWidget> createState() => _VersionSentryWidgetState();
}

class _VersionSentryWidgetState extends State<VersionSentryWidget> {
  static const String _lastShownKey = 'version_sentry_current_date_time';

  @override
  void initState() {
    super.initState();

    if (_isSupportedPlatform) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _check() async {
    final info = await VersionSentry.versionSentryInfo(
      iOSAppStoreCountry: widget.iOSAppStoreCountry,
      androidPlayStoreCountry: widget.androidPlayStoreCountry,
    );

    if (!mounted || info == null || !info.needsUpdate) return;

    final type = _resolveType(info);
    if (type == null) return;

    if (type == VersionSentryUpdateType.major) {
      _showMajorScreen(_requestFor(info, type));
      return;
    }

    /// Only minor and patch prompts are throttled; major nags every launch.
    if (!await _readyToShow()) return;
    if (!mounted) return;

    await _rememberShown();
    if (!mounted) return;

    _showSheet(_requestFor(info, type));
  }

  /// The largest moved number wins, and a disabled flag means no prompt rather
  /// than falling through to a smaller one.
  VersionSentryUpdateType? _resolveType(VersionSentryInfo info) {
    if (info.isMajorUpdate) {
      return widget.showMajorUpdate ? VersionSentryUpdateType.major : null;
    }
    if (info.isMinorUpdate) {
      return widget.showMinorUpdate ? VersionSentryUpdateType.minor : null;
    }
    if (info.isPatchUpdate) {
      return widget.showPatchUpdate ? VersionSentryUpdateType.patch : null;
    }
    return null;
  }

  VersionSentryUpdateRequest _requestFor(
    VersionSentryInfo info,
    VersionSentryUpdateType type,
  ) {
    final isMajor = type == VersionSentryUpdateType.major;

    return VersionSentryUpdateRequest(
      type: type,
      info: info,
      releaseNote: isMajor ? widget.majorReleaseNote : widget.minorReleaseNote,
      progress: null,
      progressStream: widget.autoUpdate
          ? VersionSentryAutoUpdate.progress
          : const Stream<VersionSentryUpdateProgress>.empty(),
      onUpdate: () => _startUpdate(info),
      onInstall: VersionSentryAutoUpdate.completeInstall,
      onDismiss: isMajor ? () {} : _dismiss,
    );
  }

  void _dismiss() {
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  void _showMajorScreen(VersionSentryUpdateRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VersionSentryProgressBuilder(
          request: request,
          builder: (context, request) =>
              VersionSentryMajorUpdateScreen(request: request),
        ),
      ),
    );
  }

  void _showSheet(VersionSentryUpdateRequest request) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      builder: (_) => VersionSentryProgressBuilder(
        request: request,
        builder: (context, request) => VersionSentryUpdateSheet(request: request),
      ),
    );
  }

  /// Downloads in-app where possible, otherwise hands off to the store.
  Future<void> _startUpdate(VersionSentryInfo info) async {
    if (widget.autoUpdate && VersionSentryAutoUpdate.isSupported) {
      final started = await VersionSentryAutoUpdate.start();
      if (started) return;

      /// Play declined — most often the build wasn't installed from Play — so
      /// fall back to the store page rather than leaving the button dead.
      debugPrint('VersionSentry: in-app update unavailable, opening the store');
    }

    await _openStore(info);
  }

  Future<void> _openStore(VersionSentryInfo info) async {
    final uri = Uri.tryParse(info.storeUrl);

    if (info.storeUrl.isEmpty || uri == null) {
      debugPrint('VersionSentry: no usable store URL for ${info.packageName}');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) debugPrint('VersionSentry: could not open $uri');
    } catch (e) {
      debugPrint('VersionSentry: could not open $uri — $e');
    }
  }

  Future<void> _rememberShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _readyToShow() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_lastShownKey) ?? 0;
    final nextAllowed =
        DateTime.fromMillisecondsSinceEpoch(last).add(widget.reminderEvery);

    return !nextAllowed.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
