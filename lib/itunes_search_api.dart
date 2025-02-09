import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ITunesSearchAPI {

  /// iTunes Search API documentation URL
  final String iTunesDocumentationURL =
      'https://affiliate.itunes.apple.com/resources/documentation/itunes-store-web-service-search-api/';

  /// iTunes Lookup API URL
  final String lookupPrefixURL = 'https://itunes.apple.com/lookup';

  /// iTunes Search API URL
  final String searchPrefixURL = 'https://itunes.apple.com/search';

  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client? client = http.Client();

  /// Provide the HTTP headers used by [client].
  Map<String, String>? clientHeaders;

  /// Enable print statements for debugging.
  bool debugLogging = false;

  /// Look up by bundle id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLByBundleId('com.google.Maps');```
  /// ```lookupURLByBundleId('com.google.Maps', country: 'FR');```
  Future<Map?> lookupByBundleId(String bundleId,
      {String? country = 'US',
      String? language = 'en',
      bool useCacheBuster = true}) async {
    assert(bundleId.isNotEmpty);
    if (bundleId.isEmpty) {
      return null;
    }

    final url = lookupURLByBundleId(bundleId,
        country: country ?? '',
        language: language ?? '',
        useCacheBuster: useCacheBuster)!;
    if (debugLogging) {
      print('Version Sentry: Final url $url');
    }

    try {
      final response =
          await client!.get(Uri.parse(url), headers: clientHeaders);

      final decodedResults = _decodeResults(response.body);
      return decodedResults;
    } catch (e) {
      if (debugLogging) {
        print('Version Sentry: API Error: $e');
      }
      return null;
    }
  }


  /// Look up URL by bundle id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLByBundleId('com.google.Maps');```
  /// ```lookupURLByBundleId('com.google.Maps', country: 'FR');```
  String? lookupURLByBundleId(String bundleId,
      {String country = 'US',
      String language = 'en',
      bool useCacheBuster = true}) {
    if (bundleId.isEmpty) {
      return null;
    }

    return lookupURLByQSP({
      'bundleId': bundleId,
      'country': country.toUpperCase(),
      'lang': language
    }, useCacheBuster: useCacheBuster);
  }


  /// Look up URL by QSP.
  String? lookupURLByQSP(Map<String, String?> qsp,
      {bool useCacheBuster = true}) {
    if (qsp.isEmpty) {
      return null;
    }

    final parameters = <String>[];
    qsp.forEach((key, value) => parameters.add('$key=$value'));
    if (useCacheBuster) {
      parameters.add('_cb=${DateTime.now().microsecondsSinceEpoch.toString()}');
    }
    final finalParameters = parameters.join('&');

    return '$lookupPrefixURL?$finalParameters';
  }

  Map? _decodeResults(String jsonResponse) {
    if (jsonResponse.isNotEmpty) {
      final decodedResults = json.decode(jsonResponse);
      if (decodedResults is Map) {
        final resultCount = decodedResults['resultCount'];
        if (resultCount == 0) {
          if (debugLogging) {
            print('Version Sentry: results are empty: $decodedResults');
          }
          return null;
        }
        return decodedResults;
      }
    }
    return null;
  }
}

extension ITunesResults on ITunesSearchAPI {
  /// Return field releaseNotes from iTunes results.
  String? releaseNotes(Map response) {
    String? value;
    try {
      value = response['results'][0]['releaseNotes'];
    } catch (e) {
      if (debugLogging) {
        print('Version Sentry.ITunesResults.releaseNotes: $e');
      }
    }
    return value;
  }


  /// Return field version from iTunes results.
  String? version(Map response) {
    String? value;
    try {
      value = response['results'][0]['version'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.version: $e');
      }
    }
    return value;
  }

  /// Extract App Store link from iTunes API response
  String appStoreLink(Map<dynamic, dynamic> response) {
    try {
      return response['results'][0]['trackViewUrl'] ?? '';
    } catch (e) {
      return 'https://apps.apple.com/app/id${response['results'][0]['trackId']}';
    }
  }

}
