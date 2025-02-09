import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

/// Provides an interface to the Google Play Store Search API.
class PlayStoreSearchAPI {
  /// The base URL for the Play Store Search API.
  final String playStorePrefixURL = 'play.google.com';

  /// Provides an HTTP client that can be replaced for mock testing.
  final http.Client? client = http.Client();


  /// Returns a [Document] object containing the app's details.
  Future<Document?> lookupById(String id,
      {String? country = 'US',
        String? language = 'en'}) async {
    // Ensure the ID is not empty.
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    // Generate the URL for the API request.
    final url = lookupURLById(id,
        country: country, language: language)!;

    // Log the final URL for debugging purposes.
      if (kDebugMode) {
        print('Version Sentry: Final url: $url');
      }

    try {
      // Send a GET request to the API.
      final response = await client!.get(Uri.parse(url));

      // Check if the response was successful.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Log an error message if the response was not successful.
        if (kDebugMode) {
          print('Version Sentry: Can\'t App || App id: $id');
        }
        return null;
      }

      // Decode the response body into a [Document] object.
      final decodedResults = _decodeResults(response.body);

      return decodedResults;
    } on Exception catch (e) {
      // Log an error message if an exception occurs.
      if (kDebugMode) {
        print('Version Sentry: API Error: $e');
      }
      return null;
    }
  }

  /// Generates a URL that points to the Play Store details for an app.
  ///
  /// Returns a URL string.
  String? lookupURLById(String id,
      {String? country = 'US',
        String? language = 'en'}) {
    // Ensure the ID is not empty.
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    // Create a map of query parameters.
    Map<String, dynamic> parameters = {'id': id};
    if (country != null && country.isNotEmpty) {
      parameters['gl'] = country;
    }
    if (language != null && language.isNotEmpty) {
      parameters['hl'] = language;
    }
    parameters['_cb'] = DateTime.now().microsecondsSinceEpoch.toString();

    // Generate the URL using the query parameters.
    final url = Uri.https(playStorePrefixURL, '/store/apps/details', parameters)
        .toString();

    return url;
  }

  /// Decodes a JSON response into a [Document] object.
  ///
  /// Returns a [Document] object or null if the response is empty.
  Document? _decodeResults(String jsonResponse) {
    // Check if the response is not empty.
    if (jsonResponse.isNotEmpty) {
      // Parse the JSON response into a [Document] object.
      final decodedResults = parse(jsonResponse);
      return decodedResults;
    }
    return null;
  }
}

extension PlayStoreResults on PlayStoreSearchAPI {
  static RegExp releaseNotesSpan = RegExp(r'>(.*?)</span>');

  /// release notes, the main app description is used.
  String? releaseNotes(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final releaseNotesElement = sectionElements.firstWhere(
          (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
          orElse: () => sectionElements[0]);

      final rawReleaseNotes = releaseNotesElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb');
      final releaseNotes = rawReleaseNotes == null
          ? null
          : multilineReleaseNotes(rawReleaseNotes);

      return releaseNotes;
    } catch (e) {
      return redesignedReleaseNotes(response);
    }
  }

  /// Returns field releaseNotes from Redesigned Play Store results. When there are no
  /// release notes, the main app description is used.
  String? redesignedReleaseNotes(Document response) {
    try {
      final sectionElements =
          response.querySelectorAll('[itemprop="description"]');

      final rawReleaseNotes = sectionElements.last;
      final releaseNotes = multilineReleaseNotes(rawReleaseNotes);
      return releaseNotes;
    } catch (e) {
      if (kDebugMode) {
        print(
            'Version Sentry: PlayStoreResults.redesignedReleaseNotes exception: $e');
      }
    }
    return null;
  }

  String? multilineReleaseNotes(Element rawReleaseNotes) {
    final innerHtml = rawReleaseNotes.innerHtml;
    String? releaseNotes = innerHtml;

    if (releaseNotesSpan.hasMatch(innerHtml)) {
      releaseNotes = releaseNotesSpan.firstMatch(innerHtml)!.group(1);
    }
    // Detect default multiline replacement
    releaseNotes = releaseNotes!.replaceAll('<br>', '\n');

    return releaseNotes;
  }

  /// Return field version from Play Store results.
  String? version(Document response) {
    String? version;
    try {
      final additionalInfoElements = response.getElementsByClassName('hAyfc');
      final versionElement = additionalInfoElements.firstWhere(
        (elm) => elm.querySelector('.BgcNfc')!.text == 'Current Version',
      );
      final storeVersion = versionElement.querySelector('.htlgb')!.text;
      version = Version.parse(storeVersion).toString();
    } catch (e) {
      return redesignedVersion(response);
    }

    return version;
  }

  /// Return field version from Redesigned Play Store results.
  String? redesignedVersion(Document response) {
    String? version;
    try {
      const patternName = ",\"name\":\"";
      const patternVersion = ",[[[\"";
      const patternCallback = "AF_initDataCallback";
      const patternEndOfString = "\"";

      final scripts = response.getElementsByTagName("script");
      final infoElements =
          scripts.where((element) => element.text.contains(patternName));
      final additionalInfoElements =
          scripts.where((element) => element.text.contains(patternCallback));
      final additionalInfoElementsFiltered = additionalInfoElements
          .where((element) => element.text.contains(patternVersion));

      final nameElement = infoElements.first.text;
      final storeNameStartIndex =
          nameElement.indexOf(patternName) + patternName.length;
      final storeNameEndIndex = storeNameStartIndex +
          nameElement
              .substring(storeNameStartIndex)
              .indexOf(patternEndOfString);
      final storeName =
          nameElement.substring(storeNameStartIndex, storeNameEndIndex);
      final storeNameCleaned = storeName.replaceAll(r'\u0027', '\'');

      final versionElement = additionalInfoElementsFiltered
          .where((element) => element.text.contains("\"$storeNameCleaned\""))
          .first
          .text;
      final storeVersionStartIndex =
          versionElement.lastIndexOf(patternVersion) + patternVersion.length;
      final storeVersionEndIndex = storeVersionStartIndex +
          versionElement
              .substring(storeVersionStartIndex)
              .indexOf(patternEndOfString);
      final storeVersion = versionElement.substring(
          storeVersionStartIndex, storeVersionEndIndex);

      // storeVersion might be: 'Varies with device', which is not a valid version.
      version = Version.parse(storeVersion).toString();
    } catch (e) {
      if (kDebugMode) {
          print('Version Sentry: PlayStoreResults.redesignedVersion exception: $e');
      }
    }

    return version;
  }
}
