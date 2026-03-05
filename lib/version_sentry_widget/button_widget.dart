import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class VersionSentryButtonWidget extends StatelessWidget {
  final VoidCallback onTap;
  final String buttonText;
  final ButtonStyle? buttonStyle;
  const VersionSentryButtonWidget({super.key, required this.onTap,this.buttonStyle, required this.buttonText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: buttonStyle??ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).canvasColor,
        ),
        child: Text(buttonText,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),),
      ),
    );
  }
}