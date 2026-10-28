import 'package:flutter/material.dart';
import 'package:version_sentry/version_sentry_widget/button_widget.dart';
import 'package:version_sentry/version_sentry_widget/update_progress_view.dart';
import 'package:version_sentry/version_sentry_widget/version_sentry_update_request.dart';

/// The major-update screen: full-screen and blocking, with no way out but
/// updating.
///
/// Everything it draws comes from the host app's [Theme].
class VersionSentryMajorUpdateScreen extends StatelessWidget {
  final VersionSentryUpdateRequest request;

  const VersionSentryMajorUpdateScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
    final progress = request.progress;

    /// A major update is mandatory, so the back button must not escape it.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 60),
              RichText(
                text: TextSpan(
                  text: 'Important ',
                  style: titleStyle?.copyWith(
                      fontWeight: FontWeight.w500, color: theme.primaryColor),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Update Available!',
                      style: titleStyle?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Icon(Icons.download_for_offline_outlined,
                          size: 70, color: theme.iconTheme.color),

                      const SizedBox(height: 8),
                      Text('Update Required to Continue',
                          style: titleStyle?.copyWith(fontSize: 18)),

                      const SizedBox(height: 4),
                      Text(
                        '${request.info.currentVersion}  →  ${request.info.storeVersion}',
                        style: theme.textTheme.bodySmall,
                      ),

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          request.releaseNote,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),

                      if (progress != null) ...[
                        const SizedBox(height: 20),
                        VersionSentryUpdateProgressView(progress: progress),
                      ],

                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: VersionSentryButtonWidget(
                          onTap: request.isBusy
                              ? null
                              : (request.isReadyToInstall
                                  ? request.onInstall
                                  : request.onUpdate),
                          buttonText: request.isReadyToInstall ? 'Install' : 'Update',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
