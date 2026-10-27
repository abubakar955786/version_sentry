import 'dart:async';

import 'package:flutter/material.dart';
import 'package:version_sentry/auto_update/version_sentry_auto_update.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';
import 'package:version_sentry/version_sentry.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  VersionSentryInfo? info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    /// Everything the package knows, without showing any UI.
    final result = await VersionSentry.versionSentryInfo();
    if (!mounted) return;
    setState(() => info = result);
  }

  @override
  Widget build(BuildContext context) {
    /// Wraps the app and prompts on its own:
    ///   major -> blocking full-screen, minor -> bottom sheet, patch -> silent.
    return VersionSentryWidget(
      autoUpdate: true,

      showMajorUpdate: true,
      showMinorUpdate: true,
      showPatchUpdate: false,

      reminderEvery: const Duration(hours: 12),

      // majorReleaseNote: 'This update is required to keep using the app.',
      // minorReleaseNote: 'A new version is available.',
      // iOSAppStoreCountry: 'in',
      // androidPlayStoreCountry: 'en_IN',

      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Version Sentry'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Installed: ${info?.currentVersion ?? '…'}'),
              Text('Store: ${info?.storeVersion ?? '…'}'),
              Text('Needs update: ${info?.needsUpdate ?? false}'),
              Text('Major: ${info?.isMajorUpdate ?? false}'),
              Text('Minor: ${info?.isMinorUpdate ?? false}'),
              Text('Patch: ${info?.isPatchUpdate ?? false}'),
              Text('Store URL: ${info?.storeUrl ?? '…'}'),
              const SizedBox(height: 24),
              const Expanded(child: ManualUpdatePanel()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Driving the update yourself, with no packaged UI at all.
///
/// This is the `if (needsUpdate) { ... }` shape: ask whether an update exists,
/// start the download, watch the status and percentage, then install.
class ManualUpdatePanel extends StatefulWidget {
  const ManualUpdatePanel({super.key});

  @override
  State<ManualUpdatePanel> createState() => _ManualUpdatePanelState();
}

class _ManualUpdatePanelState extends State<ManualUpdatePanel> {
  StreamSubscription<VersionSentryUpdateProgress>? _subscription;
  VersionSentryUpdateProgress? _progress;

  @override
  void initState() {
    super.initState();

    /// Subscribe before starting, so no early ticks are missed.
    _subscription = VersionSentryAutoUpdate.progress.listen((progress) {
      if (!mounted) return;
      setState(() => _progress = progress);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _runAutoUpdate() async {
    final info = await VersionSentry.versionSentryInfo();

    if (info?.needsUpdate ?? false) {
      await VersionSentryAutoUpdate.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manual flow', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Status: ${progress?.status.name ?? 'idle'}'),
        Text('Progress: ${progress?.percent?.toString() ?? '—'}%'),
        if (progress?.fraction != null)
          LinearProgressIndicator(value: progress!.fraction),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: _runAutoUpdate,
              child: const Text('Start download'),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              /// Only does anything once the status reads `downloaded`.
              onPressed: (progress?.status.isReadyToInstall ?? false)
                  ? VersionSentryAutoUpdate.completeInstall
                  : null,
              child: const Text('Install'),
            ),
          ],
        ),
      ],
    );
  }
}
