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
  final bool? sowStaticReleaseNotes;
  final TextStyle? titleStyle, releaseNotesTextStyle;
  final Color? backgroundColor, appBarColor, primacyColor;
  final String? cancelButtonText, updateButtonText, countryCode;
  final ButtonStyle? updateButtonStyle, cancelButtonStyle;
  final Widget? iconWidget, releaseNotes;
  final Widget child;
  final bool? showPatchAndMinorUpdate;
  final bool? showMajorUpdate;
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
    this.sowStaticReleaseNotes = true,
    this.iconWidget,
    this.releaseNotes,
    this.titleStyle,
    this.backgroundColor,
    this.releaseNotesTextStyle,
    this.appBarColor,
    this.primacyColor,
    this.countryCode
  });

  @override
  State<VersionSentryWidget> createState() => _VersionSentryWidgetState();
}

class _VersionSentryWidgetState extends State<VersionSentryWidget> {
  String? releaseNotes;
  late Duration nextReminder;
  VersionSentryInfo? versionSentryInfo;


  void init () async {
      versionSentryInfo = await VersionSentry.versionSentryInfo(countryCode: widget.countryCode??'in');
      if(widget.sowStaticReleaseNotes == true){
        releaseNotes = "Please update to the latest version now to ensure you have the best experience and access to all new features.";
      }
      if(versionSentryInfo?.isMajorUpdate??false ) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
            VersionSentryMajorUpdateScreen(
              releaseNotes: releaseNotesWidget (),
              iconWidget: iconWidget(70),
              updateNowButtonText: widget.updateButtonText??"",
              onTap: ()async{
                try {
                  await launchUrl(Uri.parse(versionSentryInfo?.appUpdateLink??""));
                } catch (e) {
                  throw "Error while open app url: ${versionSentryInfo?.appUpdateLink??""}";
                }
                },
              titleStyle: titleStyle(),
              primacyColor: primacyColor (),
              backgroundColor: backgroundColor (),
              appBarColor: appBarColor (),
            )));
      }


      if((versionSentryInfo?.isPatchUpdate??false) || (versionSentryInfo?.isMinorUpdate??false)){
        nextReminder = widget.reminderEvery??const Duration(hours: 12);
        bool show = await readyToShow(nextReminder.inMinutes);
        if(show){
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
            await launchUrl(Uri.parse(versionSentryInfo?.appUpdateLink??""));
          } catch (e) {
            throw "Error while open app url: ${versionSentryInfo?.appUpdateLink??""}";
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