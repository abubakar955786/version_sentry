import 'package:flutter/material.dart';
import 'package:version_sentry/version_sentry_widget/button_widget.dart';
import 'package:version_sentry/version_sentry_widget/update_progress_view.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

/// The patch prompt: a compact, dismissible sheet for a bug-fix release.
///
/// Deliberately lighter than [VersionSentryUpdateSheet] — a patch rarely earns
/// a full-width interruption, so the title and version pair sit on one row and
/// the dismiss action is a plain text button. The update flow is identical.
///
/// Everything it draws comes from the host app's [Theme].
class VersionSentryPatchUpdateSheet extends StatelessWidget {
  final VersionSentryUpdateRequest request;

  const VersionSentryPatchUpdateSheet({super.key, required this.request});

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.build_outlined,
                      size: 28, color: theme.iconTheme.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Small Update Available',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(
                          '${request.info.currentVersion}  →  ${request.info.storeVersion}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                request.releaseNote,
                style: theme.textTheme.bodyMedium,
              ),

              if (progress != null) ...[
                const SizedBox(height: 20),
                VersionSentryUpdateProgressView(progress: progress),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: request.onDismiss,
                    child: Text(
                      'Later',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 150,
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
