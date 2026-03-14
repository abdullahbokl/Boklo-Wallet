import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/shared/responsive/responsive_constraint.dart';
import 'package:flutter/material.dart';

class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.child,
    super.key,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.centerTitle = false,
    this.bottom,
    this.extendBodyBehindAppBar = false,
    this.padding,
    this.maxWidth,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final bool extendBodyBehindAppBar;
  final EdgeInsets? padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.pageTintDark
          : AppColors.pageTintLight,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title == null && actions == null && bottom == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              centerTitle: centerTitle,
              actions: actions,
              bottom: bottom,
            ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        top: !extendBodyBehindAppBar,
        child: ResponsiveConstraint(
          maxWidth: maxWidth ?? AppDimens.maxContentWidth,
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppDimens.pageHorizontalPadding,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}
