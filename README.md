Version Sentry 
================
A Flutter package to help apps stay up-to-date by fetching the latest version from the Play Store (Android) or App Store (iOS).
Usage


## 📱 Screenshots

| Patch & Minor Update                                                                                              | Major Update                                                                                                       |
|-------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| ![patch_update](https://raw.githubusercontent.com/abubakar955786/version_sentry/main/screenshots/patch_update.png) | ![major_update](https://raw.githubusercontent.com/abubakar955786/version_sentry/main/screenshots/major_update.png) |




## Usage

``` dart
import 'package:version_sentry/version_sentry.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Version Sentry"),
      ),
      body: const VersionSentryWidget(

        /// Customize Your Update Style

        // countryCode: "in",
        // showPatchAndMinorUpdate: true,
        // showMajorUpdate: true,
        // reminderEvery : const Duration(hours: 12),
        // updateButtonText : 'Update',
        // cancelButtonText : 'Cancel',
        // updateButtonStyle: const ButtonStyle(),
        // cancelButtonStyle: const ButtonStyle(),
        // sowStaticReleaseNotes: true,
        // iconWidget: const Icon(CupertinoIcons.download_circle),
        // releaseNotes: const Text("Custom release notes"),
        // titleStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        // appBarColor: Theme.of(context).primaryColor.withOpacity(0.2),
        // releaseNotesTextStyle: Theme.of(context).textTheme.bodyLarge,
        // primacyColor: Theme.of(context).primaryColor,

        child: Text("Your Widget"),
      ),
    );
  }
}
```

-----

## Check for App Updates Programmatically
You can also get version details and use them according to your requirement:

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

