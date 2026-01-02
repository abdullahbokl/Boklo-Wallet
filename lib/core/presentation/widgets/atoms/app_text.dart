import 'package:flutter/material.dart';

/// A theme-aware text widget that enforces typographic consistency.
///
/// Rules:
/// - [Theme-Aware]: Uses [Theme.of(context).textTheme] by default.
/// - [Localization]: Enforce [text] is localized using [AppLocalizations].
/// - [No Business Logic]: Should only display data, no complex calculations.
/// - [Responsiveness]: Avoid direct [MediaQuery] usage.
class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  factory AppText.headlineLarge(
    String text, {
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return AppText(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: (context) => Theme.of(context).textTheme.headlineLarge,
    );
  }

  factory AppText.bodyMedium(
    String text, {
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return AppText(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: (context) => Theme.of(context).textTheme.bodyMedium,
    );
  }

  final String text;
  final TextStyle? Function(BuildContext context)? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style?.call(context) ?? Theme.of(context).textTheme.bodyMedium;
    return Text(
      text,
      style: effectiveStyle,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
