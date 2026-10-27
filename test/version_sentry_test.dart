import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'package:version_sentry/version_sentry_widget/button_widget.dart';

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
  });
}
