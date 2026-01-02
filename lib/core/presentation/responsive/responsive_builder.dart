import 'package:boklo/core/presentation/responsive/app_breakpoints.dart';
import 'package:boklo/core/presentation/responsive/device_type.dart';
import 'package:boklo/core/presentation/responsive/screen_info.dart';
import 'package:flutter/material.dart';

typedef ResponsiveWidgetBuilder =
    Widget Function(
      BuildContext context,
      ScreenInfo screenInfo,
    );

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder? tablet;
  final ResponsiveWidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            DeviceType deviceType;
            if (width < AppBreakpoints.mobile) {
              deviceType = DeviceType.mobile;
            } else if (width < AppBreakpoints.tablet) {
              deviceType = DeviceType.tablet;
            } else {
              deviceType = DeviceType.desktop;
            }

            final screenInfo = ScreenInfo(
              width: width,
              height: height,
              orientation: orientation,
              deviceType: deviceType,
            );

            if (deviceType == DeviceType.desktop && desktop != null) {
              return desktop!(context, screenInfo);
            }

            if (deviceType == DeviceType.tablet && tablet != null) {
              return tablet!(context, screenInfo);
            }

            return mobile(context, screenInfo);
          },
        );
      },
    );
  }
}
