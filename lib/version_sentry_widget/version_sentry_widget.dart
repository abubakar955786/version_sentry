import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version_sentry/version_sentry.dart';
import 'package:version_sentry/version_sentry_info.dart';
import 'bottom_sheet.dart';
import 'major_update_screen.dart';

class VersionSentryWidget extends StatefulWidget {
  final bool? showMajorUpdate;

  /// Show the built-in generic update message instead of the store's notes.
  final bool? showStaticReleaseNotes;

  @Deprecated('Misspelled; use showStaticReleaseNotes instead.')
  final bool? sowStaticReleaseNotes;
  final TextStyle? titleStyle, releaseNotesTextStyle;
  final Color? backgroundColor, appBarColor, primacyColor;
  final String? cancelButtonText, updateButtonText, iOSAppStoreCountry, packageName, bundleId, androidPlayStoreCountry;
  final ButtonStyle? updateButtonStyle, cancelButtonStyle;
  final Widget? iconWidget, releaseNotes;
  final Widget child;
  final bool? showPatchAndMinorUpdate;
  final bool androidHtmlReleaseNotes;
  final Duration? reminderEvery;
  const VersionSentryWidget({super.key,
    required this.child,
    this.showPatchAndMinorUpdate = true,
    this.showMajorUpdate = true,
    this.reminderEvery = const Duration(hours: 12),
    this.updateButtonText = 'Update',
    this.cancelButtonText = 'Cancel',
    this.updateButtonStyle,
    this.cancelButtonStyle,
    this.showStaticReleaseNotes,
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Misspelled; use showStaticReleaseNotes instead.') this.sowStaticReleaseNotes,
    this.iconWidget,
    this.releaseNotes,
    this.titleStyle,
    this.backgroundColor,
    this.releaseNotesTextStyle,
    this.appBarColor,
    this.primacyColor,
    this.iOSAppStoreCountry,
    this.packageName,
    this.bundleId,
    this.androidPlayStoreCountry,
    this.androidHtmlReleaseNotes = false
  });

  @override
  State<VersionSentryWidget> createState() => _VersionSentryWidgetState();
}

class _VersionSentryWidgetState extends State<VersionSentryWidget> {
  String? releaseNotes;
  late Duration nextReminder;
  VersionSentryInfo? versionSentryInfo;


  void init () async {
      versionSentryInfo = await VersionSentry.versionSentryInfo(
          iOSAppStoreCountry: widget.iOSAppStoreCountry,
          androidPlayStoreCountry: widget.androidPlayStoreCountry,
          androidHtmlReleaseNotes: widget.androidHtmlReleaseNotes,
          packageName: widget.packageName,
          bundleId: widget.bundleId);

      if(!mounted) return;

      final info = versionSentryInfo;
      if(info == null || !info.needsUpdate) return;

      releaseNotes = useStaticReleaseNotes
          ? "Please update to the latest version now to ensure you have the best experience and access to all new features."
          : info.releaseNotes;

      /// Several flags can be true at once (2.1.1 over 1.0.0), so major wins.
      if(info.isMajorUpdate) {
        if(widget.showMajorUpdate != true) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
            VersionSentryMajorUpdateScreen(
              releaseNotes: releaseNotesWidget (),
              iconWidget: iconWidget(70),
              updateNowButtonText: widget.updateButtonText??"",
              onTap: ()async{
                try {
                  await launchUrl(Uri.parse(versionSentryInfo?.storeUrl??""));
                } catch (e) {
                  throw "Error while open app url: ${versionSentryInfo?.storeUrl??""}";
                }
                },
              titleStyle: titleStyle(),
              primacyColor: primacyColor (),
              backgroundColor: backgroundColor (),
              appBarColor: appBarColor (),
            )));
        return;
      }

      if(info.isMinorUpdate || info.isPatchUpdate){
        if(widget.showPatchAndMinorUpdate != true) return;
        nextReminder = widget.reminderEvery??const Duration(hours: 12);
        bool show = await readyToShow(nextReminder.inMinutes);
        if(show && mounted){
          saveDateTime();
          patchOrMinorUpdate ();
        }
      }
  }

  @override
  void initState() {
    if(!kIsWeb){
      WidgetsBinding.instance.addPostFrameCallback((value){init ();});
    }
    super.initState();
  }


  Future<void> saveDateTime() async {
    final prefs = await SharedPreferences.getInstance();
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('version_sentry_current_date_time', timestamp);
  }

  Future<bool> readyToShow(int minute) async {
    final prefs = await SharedPreferences.getInstance();
    int timestamp = prefs.getInt('version_sentry_current_date_time')??0;
    DateTime currentTime = DateTime.now();
    DateTime nextTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime updateFutureTime = nextTime.add(Duration(minutes: minute));
    return updateFutureTime.isAfter(currentTime)? false:true;
  }



  void patchOrMinorUpdate () {
    patchOrMinorUpdateBottomSheet(
        context: context,
        iconWidget: iconWidget(50),
        cancelButtonText: widget.cancelButtonText??"",
        updateNowButtonText: widget.updateButtonText,
        updateButtonStyle: widget.updateButtonStyle,
        cancelButtonStyle: widget.cancelButtonStyle,
        releaseNotesWidget: releaseNotesWidget(),
        onTapUpdate: () async {
          try {
            await launchUrl(Uri.parse(versionSentryInfo?.storeUrl??""));
          } catch (e) {
            throw "Error while open app url: ${versionSentryInfo?.storeUrl??""}";
          }
        },
        bgColor: backgroundColor(),
        titleStyle: titleStyle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
    );
  }



  bool get useStaticReleaseNotes {
    // ignore: deprecated_member_use_from_same_package
    return widget.showStaticReleaseNotes ?? widget.sowStaticReleaseNotes ?? true;
  }

  Widget iconWidget (double iconSize) {
    return SizedBox(
      height: iconSize,
      width: iconSize,
      child: widget.iconWidget??
          Icon(CupertinoIcons.download_circle,
              size: iconSize, color: Theme.of(context).iconTheme.color),
    );
  }

  Widget releaseNotesWidget () {
    return widget.releaseNotes?? Text(
      releaseNotes??"",
      textAlign: TextAlign.center,
      style: releaseNotesTextStyle (),
    );
  }

  TextStyle? titleStyle () {
    return widget.titleStyle?? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600);
  }

  TextStyle? releaseNotesTextStyle () {
    return widget.releaseNotesTextStyle?? Theme.of(context).textTheme.bodyLarge;
  }

  Color? backgroundColor () {
    return widget.backgroundColor?? Theme.of(context).scaffoldBackgroundColor;
  }

  Color? appBarColor () {
    return widget.appBarColor?? Theme.of(context).primaryColor.withOpacity(0.2);
  }

  Color? primacyColor () {
    return widget.primacyColor?? Theme.of(context).primaryColor;
  }


}