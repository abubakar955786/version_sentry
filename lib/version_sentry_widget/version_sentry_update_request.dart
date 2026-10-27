import 'package:flutter/widgets.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';
import 'package:version_sentry/version_sentry_info.dart';

/// Which part of the semantic version moved.
///
/// For `1.2.3`: `1` is the major, `2` the minor, `3` the patch. A single
/// release can move more than one of them, in which case the largest wins —
/// 1.0.0 -> 2.1.1 is a [major] update, not three separate ones.
enum VersionSentryUpdateType {
  /// Left number moved. Breaking or mandatory; shown full-screen and blocking.
  major,

  /// Middle number moved. New features; shown as a dismissible bottom sheet.
  minor,

  /// Right number moved. Bug fixes; silent by default.
  patch,
}

/// Internal plumbing: what the built-in screens need in order to render.
typedef VersionSentryUpdateBuilder = Widget Function(
  BuildContext context,
  VersionSentryUpdateRequest request,
);

/// The state of one update prompt, handed to the built-in screens.
class VersionSentryUpdateRequest {
  /// Which number in the version moved.
  final VersionSentryUpdateType type;

  /// Installed vs store version, and the store URL.
  final VersionSentryInfo info;

  /// The note to show, from `majorReleaseNote` or `minorReleaseNote`.
  final String releaseNote;

  /// Latest tick from the in-app update flow, or null if nothing is running.
  final VersionSentryUpdateProgress? progress;

  /// Starts the in-app download, or opens the store page.
  final Future<void> Function() onUpdate;

  /// Installs a finished download and restarts the app.
  final Future<void> Function() onInstall;

  /// Closes the prompt. A no-op for [VersionSentryUpdateType.major].
  final VoidCallback onDismiss;

  /// Live status ticks, empty when auto update is off.
  final Stream<VersionSentryUpdateProgress> progressStream;

  const VersionSentryUpdateRequest({
    required this.type,
    required this.info,
    required this.releaseNote,
    required this.progress,
    required this.onUpdate,
    required this.onInstall,
    required this.onDismiss,
    this.progressStream = const Stream<VersionSentryUpdateProgress>.empty(),
  });

  /// The same request carrying a newer progress tick.
  VersionSentryUpdateRequest copyWith({VersionSentryUpdateProgress? progress}) {
    return VersionSentryUpdateRequest(
      type: type,
      info: info,
      releaseNote: releaseNote,
      progress: progress ?? this.progress,
      onUpdate: onUpdate,
      onInstall: onInstall,
      onDismiss: onDismiss,
      progressStream: progressStream,
    );
  }

  /// Whether a download or install is running, so the button should be dead.
  bool get isBusy {
    final status = progress?.status;
    return status == VersionSentryUpdateStatus.pending ||
        status == VersionSentryUpdateStatus.downloading ||
        status == VersionSentryUpdateStatus.installing;
  }

  /// Whether the download finished and [onInstall] is the next step.
  bool get isReadyToInstall => progress?.status.isReadyToInstall ?? false;

  /// Download percentage, or null when indeterminate.
  int? get percent => progress?.percent;
}
