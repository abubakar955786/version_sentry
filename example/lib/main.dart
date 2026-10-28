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
    /// Wraps the app and prompts on its own: major -> blocking full-screen,
    /// minor -> bottom sheet, patch -> compact sheet, off by default.
    return VersionSentryWidget(
      autoUpdate: true,

      showMajorUpdate: true,
      showMinorUpdate: true,
      showPatchUpdate: false,

      minorUpdateReminder: const Duration(hours: 12),

      /// One release note per update type, each with a built-in default. Pass
      /// them only to match your own tone. They replace the store's own notes,
      /// which stay available on VersionSentryInfo.releaseNotes.
      // majorReleaseNote: 'This update is required to keep using the app.',
      // minorReleaseNote: 'A new version is available.',
      // patchReleaseNote: 'A few fixes are ready. This one is quick.',

      /// Handlers show your own UI instead of a built-in screen.
      ///
      /// A handler takes over outright: the built-in screen is never shown, and
      /// the show* flag above stops applying to that type — the flags only gate
      /// the built-in screens. So onPatchUpdate below still fires even with
      /// showPatchUpdate: false.
      ///
      /// `request` carries both versions, the release note for this type, and
      /// onUpdate / onInstall / onDismiss, so your screen drives the same flow
      /// the built-in ones do. `request.progress` is a snapshot — wrap your
      /// widget in VersionSentryProgressBuilder (imported from
      /// version_sentry_widget/version_sentry_progress_builder.dart) to be
      /// rebuilt on every download tick.
      ///
      /// Major: your own blocking route. Nothing dismisses it for you —
      /// request.onDismiss is a no-op for this type.
      // onMajorUpdate: (context, request) => Navigator.of(context).push(
      //   MaterialPageRoute<void>(
      //     builder: (_) => VersionSentryProgressBuilder(
      //       request: request,
      //       builder: (context, request) =>
      //           MyForcedUpdateScreen(request: request),
      //     ),
      //   ),
      // ),
      ///
      /// Minor: your own sheet. Still throttled by minorUpdateReminder, so it
      /// fires at most once per interval — pass Duration.zero to be called on
      /// every launch and pace it yourself.
      // onMinorUpdate: (context, request) => showModalBottomSheet<void>(
      //   context: context,
      //   builder: (_) => VersionSentryProgressBuilder(
      //     request: request,
      //     builder: (context, request) => MyUpdateSheet(request: request),
      //   ),
      // ),
      ///
      /// Patch: anything you like, down to a snackbar. Throttled like minor.
      // onPatchUpdate: (context, request) =>
      //     ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Version ${request.info.storeVersion} is available'),
      //     action: SnackBarAction(
      //       label: 'Update',
      //       onPressed: request.onUpdate,
      //     ),
      //   ),
      // ),


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
