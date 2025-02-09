import 'package:flutter/material.dart';
import 'package:version_sentry/version_sentry.dart';
import 'package:version_sentry/version_sentry_info.dart';

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
      home: const MyHomePage(),
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
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Version: ${versionSentryInfo?.currentVersion}', style: const TextStyle(fontSize: 20),),
            Text('Store Version: ${versionSentryInfo?.storeVersion}',style: const TextStyle(fontSize: 20),),
            Text('Needs Update: ${versionSentryInfo?.needsUpdate}',style: const TextStyle(fontSize: 20),),
            Text('Is Major Update: ${versionSentryInfo?.isMajorUpdate}',style: const TextStyle(fontSize: 20),),
            Text('Is Minor Update: ${versionSentryInfo?.isMinorUpdate}',style: const TextStyle(fontSize: 20),),
            Text('Is Patch Update: ${versionSentryInfo?.isPatchUpdate}',style: const TextStyle(fontSize: 20),),
            Text('Release Notes: ${versionSentryInfo?.releaseNotes}',style: const TextStyle(fontSize: 20),),
            Text('Package Name: ${versionSentryInfo?.packageName}',style: const TextStyle(fontSize: 20),),
            Text('Platform: ${versionSentryInfo?.platform}',style: const TextStyle(fontSize: 20),),
          ],
        ),
      ),
    );
  }
}
