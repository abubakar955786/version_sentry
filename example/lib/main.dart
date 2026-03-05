import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:version_sentry/version_sentry.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Version Sentry',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  VersionSentryInfo? versionSentryInfo;

  void getVersionInfo () async {
    versionSentryInfo = await VersionSentry.versionSentryInfo(countryCode: 'in');

    print(versionSentryInfo?.currentVersion); // 1.0.0
    print(versionSentryInfo?.storeVersion); // 1.4.20
    print(versionSentryInfo?.needsUpdate); // true
    print(versionSentryInfo?.isMajorUpdate); // false
    print(versionSentryInfo?.isMinorUpdate); // true
    print(versionSentryInfo?.isPatchUpdate); // true
    print(versionSentryInfo?.releaseNotes); // Improve Design
    print(versionSentryInfo?.packageName); // com.example.example
    print(versionSentryInfo?.platform); // iOS
    setState(() {});
  }

  @override
  void initState() {
    getVersionInfo ();
    super.initState();
  }
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

        child: Center(
          child: Text('A Minor or Patch Update is\nNow Available!', style: TextStyle(fontSize: 20),textAlign: TextAlign.center,),
        ),
      ),
    );
  }
}