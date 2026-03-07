import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class NetworkManager {
  NetworkManager._();
  static final NetworkManager _instance = NetworkManager._();
  factory NetworkManager() => _instance;

  static final RegExp _versionRegex = RegExp(r'\[\[\[\"(\d+\.\d+(\.[a-z]+)?(\.([^"]|\\")*)?)\"\]\]');
  static final RegExp _releaseRegex = RegExp(r'\[(null,)\[(null,)\"((\.[a-z]+)?(([^"]|\\")*)?)\"\]\]');
  static final RegExp _removeHtmlRegex = RegExp(r"\\u003c[A-Za-z]{1,10}\\u003e");
  static final RegExp _removeQuoteRegex = RegExp(r"\\u0026quot;");


  static Future<Map<String, dynamic>?> getAppInfo({
    required String bundleId,
    required String packageName,
    String? iOSAppStoreCountry,
    String? androidPlayStoreCountry,
    bool androidHtmlReleaseNotes = false,
  }) async {

    if (Platform.isIOS) {
      return _appStoreVersion(
        bundleId: bundleId,
        iOSAppStoreCountry: iOSAppStoreCountry
      );
    }

    if (Platform.isAndroid) {
      return _payStoreVersion(
        packageName: packageName,
        androidPlayStoreCountry: androidPlayStoreCountry,
        androidHtmlReleaseNotes: androidHtmlReleaseNotes,
      );
    }

    debugPrint('Unsupported platform: ${Platform.operatingSystem}');
    return null;
  }



  /// Fetches iOS App Store version info using the iTunes Lookup API.
  static Future<Map<String, dynamic>?> _appStoreVersion({
    required String bundleId,
    String? iOSAppStoreCountry,
  }) async {
    try {
      final params = <String, String>{
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        if (bundleId.contains('.')) 'bundleId': bundleId else 'id': bundleId,
        if (iOSAppStoreCountry != null) 'country': iOSAppStoreCountry,
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
    String? androidPlayStoreCountry,
    required bool androidHtmlReleaseNotes,
  }) async {
    try {
      final uri = Uri.https(
        "play.google.com",
        "/store/apps/details",
        {
          "id": packageName,
          "hl": androidPlayStoreCountry ?? "en_US",
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