import 'dart:ui';

/// Extension on [Color] to provide additional color manipulation utilities.
extension ColorExtensions on Color {
  /// Returns a new color with the given [opacity] applied.
  ///
  /// The [opacity] value should be between `0.0` (fully transparent) and `1.0` (fully opaque).
  /// If the value is out of bounds, it is clamped within the valid range.
  Color applyOpacity(double opacity) {
    return withAlpha((opacity * 255).toInt().clamp(0, 255));
  }
}
