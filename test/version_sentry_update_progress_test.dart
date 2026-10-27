import 'package:flutter_test/flutter_test.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';

void main() {
  group('VersionSentryUpdateStatus', () {
    test('maps every Play InstallStatus code', () {
      expect(VersionSentryUpdateStatus.fromCode(0), VersionSentryUpdateStatus.unknown);
      expect(VersionSentryUpdateStatus.fromCode(1), VersionSentryUpdateStatus.pending);
      expect(VersionSentryUpdateStatus.fromCode(2), VersionSentryUpdateStatus.downloading);
      expect(VersionSentryUpdateStatus.fromCode(3), VersionSentryUpdateStatus.installing);
      expect(VersionSentryUpdateStatus.fromCode(4), VersionSentryUpdateStatus.installed);
      expect(VersionSentryUpdateStatus.fromCode(5), VersionSentryUpdateStatus.failed);
      expect(VersionSentryUpdateStatus.fromCode(6), VersionSentryUpdateStatus.canceled);

      /// DOWNLOADED is 11, not 7 — the one non-sequential Play constant.
      expect(VersionSentryUpdateStatus.fromCode(11), VersionSentryUpdateStatus.downloaded);
    });

    test('falls back to unknown for codes it does not recognise', () {
      expect(VersionSentryUpdateStatus.fromCode(99), VersionSentryUpdateStatus.unknown);
      expect(VersionSentryUpdateStatus.fromCode(null), VersionSentryUpdateStatus.unknown);
    });

    test('flags the terminal and install-ready states', () {
      expect(VersionSentryUpdateStatus.installed.isFinished, isTrue);
      expect(VersionSentryUpdateStatus.failed.isFinished, isTrue);
      expect(VersionSentryUpdateStatus.canceled.isFinished, isTrue);
      expect(VersionSentryUpdateStatus.downloading.isFinished, isFalse);

      expect(VersionSentryUpdateStatus.downloaded.isReadyToInstall, isTrue);
      expect(VersionSentryUpdateStatus.installing.isReadyToInstall, isFalse);
    });
  });

  group('VersionSentryUpdateProgress', () {
    test('computes the percentage from the byte counters', () {
      const progress = VersionSentryUpdateProgress(
        status: VersionSentryUpdateStatus.downloading,
        bytesDownloaded: 4200,
        totalBytesToDownload: 10000,
      );

      expect(progress.fraction, 0.42);
      expect(progress.percent, 42);
      expect(progress.label, 'Downloading… 42%');
    });

    test('is indeterminate when Play has not reported a total', () {
      /// totalBytesToDownload is only defined while the status is DOWNLOADING,
      /// so the UI must handle its absence rather than drawing a 0% bar.
      const progress = VersionSentryUpdateProgress(
        status: VersionSentryUpdateStatus.pending,
      );

      expect(progress.fraction, isNull);
      expect(progress.percent, isNull);
      expect(progress.label, 'Starting download…');
    });

    test('clamps a total that undercounts the downloaded bytes', () {
      const progress = VersionSentryUpdateProgress(
        status: VersionSentryUpdateStatus.downloading,
        bytesDownloaded: 500,
        totalBytesToDownload: 100,
      );

      expect(progress.fraction, 1.0);
      expect(progress.percent, 100);
    });

    test('parses a platform event map', () {
      final progress = VersionSentryUpdateProgress.fromEvent(<dynamic, dynamic>{
        'status': 11,
        'bytesDownloaded': 2048,
        'totalBytesToDownload': 2048,
      });

      expect(progress.status, VersionSentryUpdateStatus.downloaded);
      expect(progress.percent, 100);
      expect(progress.label, 'Ready to install');
    });

    test('survives an event map with missing keys', () {
      final progress = VersionSentryUpdateProgress.fromEvent(<dynamic, dynamic>{});

      expect(progress.status, VersionSentryUpdateStatus.unknown);
      expect(progress.bytesDownloaded, 0);
      expect(progress.percent, isNull);
    });
  });
}
