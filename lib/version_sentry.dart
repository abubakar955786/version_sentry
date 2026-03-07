library version_sentry;

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:version_sentry/network_manager/network_manager.dart';
import 'package:version_sentry/version_sentry_info.dart';

class VersionSentry {
  static Future<VersionSentryInfo?> versionSentryInfo({
    String? packageName, bundleId, iOSAppStoreCountry, androidPlayStoreCountry,
    bool androidHtmlReleaseNotes = false,
  }) async {
    // Validate platform
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw Exception('Unsupported platform - Only Android/iOS supported');
    }

    final packageInfo = await PackageInfo.fromPlatform();

    final platform = Platform.isAndroid ? 'Android' : 'iOS';
    final package = packageName ?? packageInfo.packageName;
    final bundle = bundleId ?? packageInfo.packageName;
    final appUpdateUrl = Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=$package'
        : 'https://apps.apple.com/in/app/return-to-dark-castle/id$bundle';


    // Initialize default values
    String storeVersion = '0.0.0';
    String releaseNotes = '';
    bool needsUpdate = false;
    bool isMajorUpdate = false;
    bool isMinorUpdate = false;
    bool isPatchUpdate = false;

    try {

      final Map<String, dynamic>? storeResult = await NetworkManager.getAppInfo(
          packageName: package,
          bundleId: bundle,
          androidHtmlReleaseNotes: androidHtmlReleaseNotes,
          iOSAppStoreCountry: iOSAppStoreCountry,
          androidPlayStoreCountry: androidPlayStoreCountry,
      );

      storeVersion = storeResult?['storeVersion'] ?? '0.0.0';
      releaseNotes = storeResult?['releaseNotes'] ?? '0.0.0';


      // Version comparison
      final current = Version.parse(packageInfo.version);
      final store = Version.parse(storeVersion);

      if (store > current) {
        needsUpdate = true;
        isMajorUpdate = store.major > current.major;
        isMinorUpdate = store.minor > current.minor;
        isPatchUpdate = store.patch > current.patch;
      }

      return VersionSentryInfo(
        platform: platform,
        currentVersion: packageInfo.version,
        storeVersion: storeVersion,
        needsUpdate: needsUpdate,
        isMajorUpdate: isMajorUpdate,
        isMinorUpdate: isMinorUpdate,
        isPatchUpdate: isPatchUpdate,
        releaseNotes: releaseNotes,
        packageName: package,
        appUpdateLink: appUpdateUrl,
        bundleId: bundle
      );

    } catch (e) {
      debugPrint('VersionSentry Error: ${e.toString()}');
      return VersionSentryInfo(
          platform: platform,
          currentVersion: packageInfo.version,
          storeVersion: storeVersion,
          needsUpdate: needsUpdate,
          isMajorUpdate: isMajorUpdate,
          isMinorUpdate: isMinorUpdate,
          isPatchUpdate: isPatchUpdate,
          releaseNotes: releaseNotes,
          packageName: package,
          appUpdateLink: appUpdateUrl,
          bundleId: bundleId
      );
     // throw Exception('VersionSentry Error: ${e.toString()}');
    }
  }
}