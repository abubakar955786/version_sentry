import 'package:flutter/widgets.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

/// Rebuilds [builder] with the latest download progress.
///
/// Wrap a custom update screen in this and `request.progress`, `request.percent`
/// and `request.isReadyToInstall` stay current without managing a subscription:
///
/// ```dart
/// onMinorUpdate: (context, request) {
///   showModalBottomSheet(
///     context: context,
///     builder: (_) => VersionSentryProgressBuilder(
///       request: request,
///       builder: (context, request) => MySheet(request: request),
///     ),
///   );
/// }
/// ```
///
/// Only needed when auto update is on — without it there is no progress to
/// report, and the stream stays empty.
class VersionSentryProgressBuilder extends StatelessWidget {
  final VersionSentryUpdateRequest request;
  final VersionSentryUpdateBuilder builder;

  const VersionSentryProgressBuilder({
    super.key,
    required this.request,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VersionSentryUpdateProgress>(
      stream: request.progressStream,
      builder: (context, snapshot) {
        final progress = snapshot.data;

        return builder(
          context,
          progress == null ? request : request.copyWith(progress: progress),
        );
      },
    );
  }
}
