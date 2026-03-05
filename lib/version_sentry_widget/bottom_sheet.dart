import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'button_widget.dart';

Future<void> patchOrMinorUpdateBottomSheet ({
  required BuildContext context,
  required Widget releaseNotesWidget, iconWidget,
  required String cancelButtonText, updateNowButtonText,
  ButtonStyle? updateButtonStyle, cancelButtonStyle,
  required VoidCallback onTapUpdate,
  Color? bgColor,
  required TextStyle? titleStyle
}) async {
  await showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height*0.6),
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            )
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                iconWidget,

                const SizedBox(height: 8),
                Text('Update Available', style: titleStyle),

                const SizedBox(height: 12),

                releaseNotesWidget,

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: VersionSentryButtonWidget(
                        onTap: () {Navigator.pop(context);},
                        buttonStyle: cancelButtonStyle,
                        buttonText: cancelButtonText),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      child: VersionSentryButtonWidget(
                        onTap: onTapUpdate,
                        buttonStyle: updateButtonStyle,
                        buttonText: updateNowButtonText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}