/// Where an in-app update has got to.
///
/// These mirror Play's `InstallStatus` constants. A flexible update walks
/// [pending] -> [downloading] -> [downloaded] -> [installing] -> [installed],
/// and can drop out to [failed] or [canceled] at any point.
enum VersionSentryUpdateStatus {
  /// No flow has started, or Play reported a status this package doesn't know.
  unknown(0),

  /// Play accepted the request and is about to start downloading.
  pending(1),

  /// Bytes are arriving. Only this status carries a meaningful total, so it is
  /// the only one where [VersionSentryUpdateProgress.percent] is non-null.
  downloading(2),

  /// The download finished. Nothing installs until you call
  /// `VersionSentryAutoUpdate.completeInstall()`.
  downloaded(11),

  /// `completeInstall()` was called and Play is applying the update.
  installing(3),

  /// Applied. The app restarts into the new version.
  installed(4),

  /// Play could not complete the update.
  failed(5),

  /// The user dismissed Play's confirmation dialog, or the flow was aborted.
  canceled(6);

  const VersionSentryUpdateStatus(this.code);

  /// The raw Play `InstallStatus` value.
  final int code;

  static VersionSentryUpdateStatus fromCode(int? code) {
    for (final status in VersionSentryUpdateStatus.values) {
      if (status.code == code) return status;
    }
    return VersionSentryUpdateStatus.unknown;
  }

  /// Whether the flow has stopped, for better or worse.
  bool get isFinished =>
      this == installed || this == failed || this == canceled;

  /// Whether the update is waiting on a `completeInstall()` call.
  bool get isReadyToInstall => this == downloaded;
}

/// A single status tick from the in-app update flow.
class VersionSentryUpdateProgress {
  final VersionSentryUpdateStatus status;
  final int bytesDownloaded;
  final int totalBytesToDownload;

  const VersionSentryUpdateProgress({
    required this.status,
    this.bytesDownloaded = 0,
    this.totalBytesToDownload = 0,
  });

  factory VersionSentryUpdateProgress.fromEvent(Map<dynamic, dynamic> event) {
    return VersionSentryUpdateProgress(
      status: VersionSentryUpdateStatus.fromCode(event['status'] as int?),
      bytesDownloaded: (event['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytesToDownload: (event['totalBytesToDownload'] as num?)?.toInt() ?? 0,
    );
  }

  /// Download progress from 0.0 to 1.0.
  ///
  /// Null whenever the total is not known. Play only defines the total while
  /// the status is [VersionSentryUpdateStatus.downloading], so treat null as
  /// "indeterminate" and show a spinner rather than a 0% bar.
  double? get fraction {
    if (totalBytesToDownload <= 0) return null;
    return (bytesDownloaded / totalBytesToDownload).clamp(0.0, 1.0);
  }

  /// Download progress as a whole percentage, or null if indeterminate.
  int? get percent {
    final value = fraction;
    return value == null ? null : (value * 100).round();
  }

  /// A ready-made line for the default UI, e.g. `Downloading… 42%`.
  String get label {
    switch (status) {
      case VersionSentryUpdateStatus.pending:
        return 'Starting download…';
      case VersionSentryUpdateStatus.downloading:
        final value = percent;
        return value == null ? 'Downloading…' : 'Downloading… $value%';
      case VersionSentryUpdateStatus.downloaded:
        return 'Ready to install';
      case VersionSentryUpdateStatus.installing:
        return 'Installing…';
      case VersionSentryUpdateStatus.installed:
        return 'Installed';
      case VersionSentryUpdateStatus.failed:
        return 'Update failed';
      case VersionSentryUpdateStatus.canceled:
        return 'Update canceled';
      case VersionSentryUpdateStatus.unknown:
        return '';
    }
  }

  @override
  String toString() =>
      'VersionSentryUpdateProgress(${status.name}, $bytesDownloaded/$totalBytesToDownload)';
}
