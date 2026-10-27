import 'package:flutter/material.dart';
import 'package:version_sentry/auto_update/version_sentry_update_progress.dart';

/// The download bar and status line shown by the built-in update screens.
///
/// Renders an indeterminate bar whenever the percentage isn't known — Play only
/// reports a total while the status is `downloading`.
class VersionSentryUpdateProgressView extends StatelessWidget {
  final VersionSentryUpdateProgress progress;

  const VersionSentryUpdateProgressView({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    if (progress.status == VersionSentryUpdateStatus.unknown) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final fraction = progress.fraction;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            color: theme.primaryColor,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.15),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress.label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
