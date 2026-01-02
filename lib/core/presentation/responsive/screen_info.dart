import 'package:boklo/core/presentation/responsive/device_type.dart';
import 'package:flutter/material.dart';

class ScreenInfo {
  final double width;
  final double height;
  final Orientation orientation;
  final DeviceType deviceType;

  const ScreenInfo({
    required this.width,
    required this.height,
    required this.orientation,
    required this.deviceType,
  });

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  @override
  String toString() {
    return 'ScreenInfo(width: $width, height: $height, orientation: $orientation, deviceType: $deviceType)';
  }
}
