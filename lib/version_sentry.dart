library version_sentry;

import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import 'package:version_sentry/play_store_search_api.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'itunes_search_api.dart';

class VersionSentry {
  static Future<VersionSentryInfo> versionSentryInfo({
    String? countryCode,String? language,
  }) async {
    try {
      // Validate platform
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw Exception('Unsupported platform - Only Android/iOS supported');
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'Android' : 'iOS';

      // Initialize default values
      String storeVersion = '0.0.0';
      String releaseNotes = '';
      String appStoreLink = '';
      bool needsUpdate = false;
      bool isMajorUpdate = false;
      bool isMinorUpdate = false;
      bool isPatchUpdate = false;

      // Platform-specific handling
      if (Platform.isAndroid) {
        final playStoreResult = await PlayStoreSearchAPI().lookupById(
          packageInfo.packageName,
          country: countryCode,
          language: language
        );

        if (playStoreResult != null) {
          storeVersion = PlayStoreSearchAPI().version(playStoreResult) ?? '0.0.0';
          releaseNotes = PlayStoreSearchAPI().releaseNotes(playStoreResult)??"";
          appStoreLink = 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
        }
      } else {
        final iTunesResult = await ITunesSearchAPI().lookupByBundleId(
           packageInfo.packageName,
          country: countryCode,
          language: language
        );

        if (iTunesResult != null) {
          storeVersion = ITunesSearchAPI().version(iTunesResult) ?? '0.0.0';
          releaseNotes = ITunesSearchAPI().releaseNotes(iTunesResult)??"";
          appStoreLink = ITunesSearchAPI().appStoreLink(iTunesResult);
        }
      }

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
        packageName: packageInfo.packageName,
        appUpdateLink: appStoreLink,
      );
    } catch (e) {
      throw Exception('VersionSentry Error: ${e.toString()}');
    }
  }
}