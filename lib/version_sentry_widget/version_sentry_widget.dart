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
import 'package:version_sentry/version_sentry_widget/patch_bottom_sheet.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_progress_builder.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

/// Wraps [child] and prompts for an update when the store has a newer version.
///
/// Which prompt appears depends on which number of `major.minor.patch` moved:
///
/// | Bump  | Prompt                   | Flag              | Default | Override         |
/// |-------|--------------------------|-------------------|---------|------------------|
/// | major | blocking full-screen     | [showMajorUpdate] | `true`  | [onMajorUpdate]  |
/// | minor | dismissible bottom sheet | [showMinorUpdate] | `true`  | [onMinorUpdate]  |
/// | patch | compact bottom sheet     | [showPatchUpdate] | `false` | [onPatchUpdate]  |
///
/// A release can move more than one number at once, in which case the largest
/// wins: 1.0.0 -> 2.1.1 is one major update, not three prompts.
///
/// Pass a handler to show your own UI for that type. A handler takes over
/// outright — the built-in screen isn't shown, and the `show*` flag for that
/// type no longer applies, since the flags only gate the built-in screens.
///
/// ```dart
/// VersionSentryWidget(
///   autoUpdate: true,
///   showMajorUpdate: true,
///   showMinorUpdate: true,
///   showPatchUpdate: false,
///   minorUpdateReminder: const Duration(hours: 12),
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

  /// Show the compact bottom sheet when only the patch number moves.
  ///
  /// Off by default: bug-fix releases rarely justify interrupting the user.
  final bool showPatchUpdate;

  /// How long to wait before prompting again for a minor or patch update.
  ///
  /// Never applies to major updates, which prompt on every launch.
  final Duration minorUpdateReminder;

  /// The message shown on the major-update screen.
  final String majorReleaseNote;

  /// The message shown on the minor-update sheet.
  final String minorReleaseNote;

  /// The message shown on the patch-update sheet.
  ///
  /// Only ever seen when [showPatchUpdate] is on, or when [onPatchUpdate] reads
  /// `request.releaseNote`.
  final String patchReleaseNote;

  /// Shows your own major-update UI instead of the built-in blocking screen.
  ///
  /// When set it is called on every launch that finds a major update, and
  /// [showMajorUpdate] is not consulted — the flag only gates the built-in
  /// screen. Major updates are never throttled by [minorUpdateReminder].
  ///
  /// Nothing is dismissed for you: a major update is meant to be mandatory, so
  /// `request.onDismiss` is a no-op for this type.
  final VersionSentryUpdateHandler? onMajorUpdate;

  /// Shows your own minor-update UI instead of the built-in bottom sheet.
  ///
  /// When set it is called instead of the sheet, and [showMinorUpdate] is not
  /// consulted. [minorUpdateReminder] still applies, so the handler fires at
  /// most once per interval — pass `Duration.zero` to be called every launch.
  final VersionSentryUpdateHandler? onMinorUpdate;

  /// Shows your own patch-update UI instead of the built-in bottom sheet.
  ///
  /// When set it is called instead of the sheet, and [showPatchUpdate] is not
  /// consulted — so a handler reaches you even though patch prompts are off by
  /// default. Throttled by [minorUpdateReminder], like minor updates.
  final VersionSentryUpdateHandler? onPatchUpdate;

  const VersionSentryWidget({
    super.key,
    required this.child,
    this.autoUpdate = true,
    this.showMajorUpdate = true,
    this.showMinorUpdate = true,
    this.showPatchUpdate = false,
    this.minorUpdateReminder = const Duration(hours: 12),
    this.majorReleaseNote =
        'This update is required to keep using the app. Please update to the '
        'latest version to continue.',
    this.minorReleaseNote =
        'A new version is available with improvements and new features. Update '
        'now for the best experience.',
    this.patchReleaseNote =
        'This release fixes a few bugs and improves stability. Updating only '
        'takes a moment.',
    this.onMajorUpdate,
    this.onMinorUpdate,
    this.onPatchUpdate,
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
    final info = await VersionSentry.versionSentryInfo();

    if (!mounted || info == null || !info.needsUpdate) return;

    final type = _resolveType(info);
    if (type == null) return;

    /// A handler owns its prompt outright, so the show* flags only decide
    /// whether the built-in screen appears.
    if (_handlerFor(type) == null && !_builtInEnabled(type)) return;

    if (type == VersionSentryUpdateType.major) {
      _present(_requestFor(info, type));
      return;
    }

    /// Only minor and patch prompts are throttled; major nags every launch.
    if (!await _readyToShow()) return;
    if (!mounted) return;

    await _rememberShown();
    if (!mounted) return;

    _present(_requestFor(info, type));
  }

  /// The largest moved number wins. A smaller bump never shows in its place —
  /// a 1.0.0 -> 2.1.1 release is one major update, not three prompts.
  VersionSentryUpdateType? _resolveType(VersionSentryInfo info) {
    if (info.isMajorUpdate) return VersionSentryUpdateType.major;
    if (info.isMinorUpdate) return VersionSentryUpdateType.minor;
    if (info.isPatchUpdate) return VersionSentryUpdateType.patch;
    return null;
  }

  /// The host app's handler for this type, if it passed one.
  VersionSentryUpdateHandler? _handlerFor(VersionSentryUpdateType type) {
    return switch (type) {
      VersionSentryUpdateType.major => widget.onMajorUpdate,
      VersionSentryUpdateType.minor => widget.onMinorUpdate,
      VersionSentryUpdateType.patch => widget.onPatchUpdate,
    };
  }

  /// Whether the built-in screen for this type is switched on.
  bool _builtInEnabled(VersionSentryUpdateType type) {
    return switch (type) {
      VersionSentryUpdateType.major => widget.showMajorUpdate,
      VersionSentryUpdateType.minor => widget.showMinorUpdate,
      VersionSentryUpdateType.patch => widget.showPatchUpdate,
    };
  }

  /// Hands the prompt to the host app's handler, or shows the built-in screen.
  void _present(VersionSentryUpdateRequest request) {
    final handler = _handlerFor(request.type);

    if (handler != null) {
      handler(context, request);
      return;
    }

    switch (request.type) {
      case VersionSentryUpdateType.major:
        _showMajorScreen(request);
      case VersionSentryUpdateType.minor:
        _showSheet(
          request,
          (context, request) => VersionSentryUpdateSheet(request: request),
        );
      case VersionSentryUpdateType.patch:
        _showSheet(
          request,
          (context, request) => VersionSentryPatchUpdateSheet(request: request),
        );
    }
  }

  VersionSentryUpdateRequest _requestFor(
    VersionSentryInfo info,
    VersionSentryUpdateType type,
  ) {
    final isMajor = type == VersionSentryUpdateType.major;

    return VersionSentryUpdateRequest(
      type: type,
      info: info,
      releaseNote: switch (type) {
        VersionSentryUpdateType.major => widget.majorReleaseNote,
        VersionSentryUpdateType.minor => widget.minorReleaseNote,
        VersionSentryUpdateType.patch => widget.patchReleaseNote,
      },
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

  /// Opens [body] as the modal sheet, kept current by the progress stream.
  void _showSheet(
    VersionSentryUpdateRequest request,
    VersionSentryUpdateBuilder body,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
      builder: (_) => VersionSentryProgressBuilder(
        request: request,
        builder: body,
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
        DateTime.fromMillisecondsSinceEpoch(last).add(widget.minorUpdateReminder);

    return !nextAllowed.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
