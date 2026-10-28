import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';
import 'package:version_sentry/version_sentry_widget/button_widget.dart';
import 'package:version_sentry/version_sentry_widget/patch_bottom_sheet.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

VersionSentryInfo buildInfo({
  bool needsUpdate = true,
  bool isMajorUpdate = false,
  bool isMinorUpdate = false,
  bool isPatchUpdate = false,
  String? releaseNotes = 'Improve Design',
}) {
  return VersionSentryInfo(
    platform: 'Android',
    currentVersion: '1.0.0',
    storeVersion: '2.1.1',
    needsUpdate: needsUpdate,
    isMajorUpdate: isMajorUpdate,
    isMinorUpdate: isMinorUpdate,
    isPatchUpdate: isPatchUpdate,
    releaseNotes: releaseNotes,
    packageName: 'com.example.example',
    bundleId: 'com.example.example',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.example.example',
  );
}

VersionSentryUpdateRequest buildPatchRequest({
  VersionSentryUpdateProgress? progress,
  VoidCallback? onDismiss,
  Future<void> Function()? onUpdate,
  Future<void> Function()? onInstall,
}) {
  return VersionSentryUpdateRequest(
    type: VersionSentryUpdateType.patch,
    info: buildInfo(isPatchUpdate: true),
    releaseNote: 'A few fixes are ready.',
    progress: progress,
    onUpdate: onUpdate ?? () async {},
    onInstall: onInstall ?? () async {},
    onDismiss: onDismiss ?? () {},
  );
}

void main() {
  group('VersionSentryInfo', () {
    test('survives a toJson/fromJson round trip', () {
      final original = buildInfo(isMinorUpdate: true, isPatchUpdate: true);
      final restored = VersionSentryInfo.fromJson(original.toJson());

      expect(restored.platform, original.platform);
      expect(restored.currentVersion, original.currentVersion);
      expect(restored.storeVersion, original.storeVersion);
      expect(restored.needsUpdate, original.needsUpdate);
      expect(restored.isMajorUpdate, original.isMajorUpdate);
      expect(restored.isMinorUpdate, original.isMinorUpdate);
      expect(restored.isPatchUpdate, original.isPatchUpdate);
      expect(restored.releaseNotes, original.releaseNotes);
      expect(restored.packageName, original.packageName);
      expect(restored.bundleId, original.bundleId);
      expect(restored.storeUrl, original.storeUrl);
    });

    test('keeps a null releaseNotes through fromJson', () {
      final restored = VersionSentryInfo.fromJson(buildInfo(releaseNotes: null).toJson());
      expect(restored.releaseNotes, isNull);
    });

    test('reports Major when several update flags are set at once', () {
      /// 2.1.1 over 1.0.0 bumps every component, so major has to win.
      final info = buildInfo(isMajorUpdate: true, isMinorUpdate: true, isPatchUpdate: true);
      expect(info.toString(), contains('Update Type: Major'));
    });

    test('reports Minor ahead of Patch', () {
      final info = buildInfo(isMinorUpdate: true, isPatchUpdate: true);
      expect(info.toString(), contains('Update Type: Minor'));
    });

    test('reports None when no update is needed', () {
      expect(buildInfo(needsUpdate: false).toString(), contains('Update Type: None'));
    });
  });

  group('VersionSentryButtonWidget', () {
    testWidgets('renders its label and reports taps', (WidgetTester tester) async {
      var tapped = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: VersionSentryButtonWidget(
            onTap: () => tapped++,
            buttonText: 'Update',
          ),
        ),
      ));

      expect(find.text('Update'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(tapped, 1);
    });

    testWidgets('renders disabled when onTap is null', (WidgetTester tester) async {
      /// The default UI passes null while a download is running.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: VersionSentryButtonWidget(onTap: null, buttonText: 'Update'),
        ),
      ));

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(button.enabled, isFalse);
    });
  });

  group('VersionSentryPatchUpdateSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester,
      VersionSentryUpdateRequest request,
    ) {
      return tester.pumpWidget(MaterialApp(
        home: Scaffold(body: VersionSentryPatchUpdateSheet(request: request)),
      ));
    }

    testWidgets('shows the version pair, the note and both actions',
        (WidgetTester tester) async {
      await pumpSheet(tester, buildPatchRequest());

      expect(find.text('Small Update Available'), findsOneWidget);
      expect(find.text('1.0.0  →  2.1.1'), findsOneWidget);
      expect(find.text('A few fixes are ready.'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('Later reports a dismiss', (WidgetTester tester) async {
      var dismissed = 0;
      await pumpSheet(tester, buildPatchRequest(onDismiss: () => dismissed++));

      await tester.tap(find.text('Later'));
      await tester.pump();

      expect(dismissed, 1);
    });

    testWidgets('hides the progress view until a tick arrives',
        (WidgetTester tester) async {
      await pumpSheet(tester, buildPatchRequest());
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await pumpSheet(
        tester,
        buildPatchRequest(
          progress: const VersionSentryUpdateProgress(
            status: VersionSentryUpdateStatus.downloading,
            bytesDownloaded: 50,
            totalBytesToDownload: 100,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('disables the button while a download runs',
        (WidgetTester tester) async {
      await pumpSheet(
        tester,
        buildPatchRequest(
          progress: const VersionSentryUpdateProgress(
            status: VersionSentryUpdateStatus.downloading,
          ),
        ),
      );

      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
          isFalse);
    });

    testWidgets('offers Install once the download finished',
        (WidgetTester tester) async {
      var installed = 0;

      await pumpSheet(
        tester,
        buildPatchRequest(
          progress: const VersionSentryUpdateProgress(
            status: VersionSentryUpdateStatus.downloaded,
          ),
          onInstall: () async => installed++,
        ),
      );

      expect(find.text('Install'), findsOneWidget);
      expect(find.text('Update'), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(installed, 1);
    });
  });
}
