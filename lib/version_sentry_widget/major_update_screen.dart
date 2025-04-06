import 'package:flutter/material.dart';
import 'button_widget.dart';

class VersionSentryMajorUpdateScreen extends StatelessWidget {
  final String updateNowButtonText;
  final Widget iconWidget, releaseNotes;
  final ButtonStyle? buttonStyle;
  final VoidCallback onTap;
  final Color? backgroundColor, appBarColor, primacyColor;
  final TextStyle? titleStyle;
  const VersionSentryMajorUpdateScreen({super.key,
    required this.releaseNotes,
    required this.iconWidget,
    this.buttonStyle,
    required this.updateNowButtonText,
    required this.onTap,
    this.backgroundColor,
    this.appBarColor,
    this.titleStyle, this.primacyColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Scaffold(
        backgroundColor: appBarColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 60),
              RichText(
                textAlign: TextAlign.start,
                text:  TextSpan(
                  text: 'Important ',
                  style: titleStyle?.copyWith(fontWeight: FontWeight.w500, color: primacyColor),
                  children: <TextSpan>[

                    TextSpan(
                        text: 'Update Available!',
                        style: titleStyle?.copyWith(fontWeight: FontWeight.w500)
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
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight:  Radius.circular(30))
                    ),

                    child:  Column(
                      children: [

                        const Spacer(),
                        iconWidget,

                        const SizedBox(height: 8,),

                        Text('Update Required to Continue', style: titleStyle?.copyWith(fontSize: 18)),

                        const SizedBox(height: 8,),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: releaseNotes,
                        ),

                        const Spacer(),

                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: VersionSentryButtonWidget(
                              onTap: onTap,
                              buttonStyle: buttonStyle,
                              buttonText: updateNowButtonText),
                        ),

                        const SizedBox(height: 20,),
                      ],
                    ),
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}