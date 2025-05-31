Version Sentry 
================
A Flutter package to help apps stay up-to-date by fetching the latest version from the Play Store (Android) or App Store (iOS).
Usage


## 📱 Screenshots

| Patch & Minor Update | Major Update |
|---------------------|--------------|
| ![patch_update](https://raw.githubusercontent.com/abubakar955786/version_sentry/main/screenshots/patch_update.png) | ![major_update](https://raw.githubusercontent.com/abubakar955786/version_sentry/main/screenshots/major_update.png) |





-----
To use Version Sentry, simply call the versionSentryInfo function and pass the country code:

```dart
import 'package:version_sentry/version_sentry.dart';

void main() async {
  VersionSentryInfo? versionSentryInfo = await VersionSentry.versionSentryInfo(countryCode: 'in');

  print(versionSentryInfo?.currentVersion); // 1.0.0
  print(versionSentryInfo?.storeVersion); // 1.4.20
  print(versionSentryInfo?.needsUpdate); // true
  print(versionSentryInfo?.isMajorUpdate); // false
  print(versionSentryInfo?.isMinorUpdate); // true
  print(versionSentryInfo?.isPatchUpdate); // true
  print(versionSentryInfo?.releaseNotes); // Improve Design
  print(versionSentryInfo?.packageName); // com.example.example
  print(versionSentryInfo?.platform); // iOS
}
```

Features
--------
1. Fetches the latest version from the Play Store (Android) or App Store (iOS)
2. Provides information about the current version, store version, and update requirements
3. Supports country-specific version fetching using country codes

