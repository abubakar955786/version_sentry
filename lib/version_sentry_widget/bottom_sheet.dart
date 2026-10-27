import 'package:flutter/material.dart';
import 'package:version_sentry/version_sentry_widget/button_widget.dart';
import 'package:version_sentry/version_sentry_widget/update_progress_view.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

/// The minor/patch prompt: a dismissible sheet with Cancel and Update.
///
/// Everything it draws comes from the host app's [Theme].
class VersionSentryUpdateSheet extends StatelessWidget {
  final VersionSentryUpdateRequest request;

  const VersionSentryUpdateSheet({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = request.progress;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.download_for_offline_outlined,
                  size: 50, color: theme.iconTheme.color),

              const SizedBox(height: 8),
              Text('Update Available',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),

              const SizedBox(height: 4),
              Text(
                '${request.info.currentVersion}  →  ${request.info.storeVersion}',
                style: theme.textTheme.bodySmall,
              ),

              const SizedBox(height: 12),
              Text(
                request.releaseNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),

              if (progress != null) ...[
                const SizedBox(height: 20),
                VersionSentryUpdateProgressView(progress: progress),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: VersionSentryButtonWidget(
                      onTap: request.onDismiss,
                      buttonText: 'Cancel',
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: VersionSentryButtonWidget(
                      /// Downloading already? Nothing to tap until it finishes
                      /// and the label becomes Install.
                      onTap: request.isBusy
                          ? null
                          : (request.isReadyToInstall
                              ? request.onInstall
                              : request.onUpdate),
                      buttonText: request.isReadyToInstall ? 'Install' : 'Update',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
