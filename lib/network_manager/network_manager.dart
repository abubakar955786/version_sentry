import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class NetworkManager {
  NetworkManager._();
  static final NetworkManager _instance = NetworkManager._();
  factory NetworkManager() => _instance;

  static final RegExp _versionRegex = RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
  static final RegExp _releaseRegex = RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
  static final RegExp _removeHtmlRegex = RegExp(r"\\u003c[A-Za-z]{1,10}\\u003e");
  static final RegExp _removeQuoteRegex = RegExp(r"\\u0026quot;");

  /// Language and region subtags of the OS locale.
  ///
  /// [Platform.localeName] arrives in several shapes — `en_IN`, `en-IN`,
  /// `en_US.UTF-8` or a bare `en` — so either separator is accepted and the
  /// encoding tail is ignored.
  static final RegExp _localeRegex = RegExp(r'^([A-Za-z]{2,3})(?:[_-]([A-Za-z]{2}))?');

  /// The App Store storefront to look the app up in, taken from the device.
  ///
  /// `null` when the OS reports no region, which leaves the lookup on Apple's
  /// default (US) storefront.
  static String? get _storeCountry =>
      _localeRegex.firstMatch(Platform.localeName)?.group(2)?.toLowerCase();

  /// The Play Store `hl` value for the device.
  ///
  /// Falls back to `en_US` when the locale can't be read, since the scraping
  /// patterns below are matched against Google's rendered page.
  static String get _playStoreLanguage {
    final match = _localeRegex.firstMatch(Platform.localeName);
    if (match == null) return 'en_US';

    final language = match.group(1)!.toLowerCase();
    final region = match.group(2);

    return region == null ? language : '${language}_${region.toUpperCase()}';
  }


  static Future<Map<String, dynamic>?> getAppInfo({
    required String bundleId,
    required String packageName,
    bool androidHtmlReleaseNotes = false,
  }) async {

    if (Platform.isIOS) {
      return _appStoreVersion(bundleId: bundleId);
    }

    if (Platform.isAndroid) {
      return _payStoreVersion(
        packageName: packageName,
        androidHtmlReleaseNotes: androidHtmlReleaseNotes,
      );
    }

    debugPrint('Unsupported platform: ${Platform.operatingSystem}');
    return null;
  }



  /// Fetches iOS App Store version info using the iTunes Lookup API.
  static Future<Map<String, dynamic>?> _appStoreVersion({
    required String bundleId,
  }) async {
    try {
      final country = _storeCountry;

      final params = <String, String>{
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        if (bundleId.contains('.')) 'bundleId': bundleId else 'id': bundleId,
        if (country != null) 'country': country,
      };

      final uri = Uri.https('itunes.apple.com', '/lookup', params);

      final response = await http.get(uri);

      if(response.statusCode == 404) {
        debugPrint("Version Sentry: App not found on App Store for id: $bundleId");
        return null;
      }

      if (response.statusCode != 200) {
        debugPrint('App Store lookup failed: ${response.statusCode}');
        return null;
      }

      final Map<String, dynamic> jsonObj = jsonDecode(response.body);
      final List results = jsonObj['results'] ?? [];

      if (results.isEmpty) {
        debugPrint("Version Sentry: App not found on App Store for id: $bundleId");
        return null;
      }

      final result = results.first;

      return {
        "storeUrl": "https://apps.apple.com/app/id${result['trackId']}",
        "storeVersion": result['version'],
        "releaseNotes": result['releaseNotes'],
      };
    } catch (e, stackTrace) {
      debugPrint('Error querying iOS App Store: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Fetches Android app version by parsing the Google Play Store page.
  static Future<Map<String, dynamic>?> _payStoreVersion({
    required String packageName,
    required bool androidHtmlReleaseNotes,
  }) async {
    try {
      final uri = Uri.https(
        "play.google.com",
        "/store/apps/details",
        {
          "id": packageName,
          "hl": _playStoreLanguage,
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await http.get(uri);

      if(response.statusCode == 404) {
        debugPrint("Version Sentry: App not found on Play Store for package name: $packageName");
        return null;
      }

      if (response.statusCode != 200) {
        debugPrint("Play Store lookup failed: ${response.statusCode}");
        return null;
      }

      final body = response.body;

      /// Version regex
      final versionMatch = _versionRegex.firstMatch(body);
      final storeVersion = versionMatch?.group(1);

      /// Release notes
      final releaseMatch = _releaseRegex.firstMatch(body);
      String? releaseNotes = releaseMatch?.group(3);

      if (!androidHtmlReleaseNotes) {
        releaseNotes = releaseNotes?.replaceAll(_removeHtmlRegex, '').replaceAll(_removeQuoteRegex, '"');
      } else {
        releaseNotes = _parseUnicodeToString(releaseNotes);
      }

      return {
        "storeUrl": "https://play.google.com/store/apps/details?id=$packageName",
        "storeVersion": RegExp(r'\d+(\.\d+)?(\.\d+)?').stringMatch(storeVersion ?? "") ?? '0.0.0',
        "releaseNotes": releaseNotes,
      };
    } catch (e, stackTrace) {
      debugPrint('Failed to query Google Play Store: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }


  static String? _parseUnicodeToString(String? text) {
    if (text == null || text.isEmpty) return text;

    try {
      final regex = RegExp(
        r'(%(?<ascii>[0-9A-Fa-f]{2}))'
        r'|(\\u(?<unicode>[0-9A-Fa-f]{4}))'
        r'|.',
      );

      final codePoints = <int>[];

      for (final match in regex.allMatches(text)) {
        final ascii = match.namedGroup('ascii');
        final unicode = match.namedGroup('unicode');

        if (ascii != null) {
          codePoints.add(int.parse(ascii, radix: 16));
        } else if (unicode != null) {
          codePoints.add(int.parse(unicode, radix: 16));
        } else {
          codePoints.addAll(match.group(0)!.runes);
        }
      }

      return String.fromCharCodes(codePoints);
    } catch (_) {
      return text;
    }
  }
}