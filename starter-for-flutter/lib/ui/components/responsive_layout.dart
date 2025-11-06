import 'package:flutter/material.dart';

/// A widget that provides a responsive layout by switching between two layouts
/// based on the available screen width.
///
/// This widget uses a [LayoutBuilder] to determine if the screen width exceeds
/// the given [breakPoint]. If it does, the [largeDeviceLayout] is displayed;
/// otherwise, the [smallDeviceLayout] is shown.
///
/// Example usage:
/// ```dart
/// ResponsiveLayout(
///   breakPoint: 768,
///   smallDeviceLayout: SmallScreenWidget(),
///   largeDeviceLayout: LargeScreenWidget(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final int breakPoint;
  final Widget smallDeviceLayout;
  final Widget largeDeviceLayout;

  /// Creates a [ResponsiveLayout] widget.
  const ResponsiveLayout({
    super.key,
    this.breakPoint = 1024,
    required this.smallDeviceLayout,
    required this.largeDeviceLayout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isRunningOnALargeDevice = constraints.maxWidth > breakPoint;
      return isRunningOnALargeDevice ? largeDeviceLayout : smallDeviceLayout;
    });
  }
}
