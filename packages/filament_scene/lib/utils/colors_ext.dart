import 'dart:ui';

///convert color to hex string
extension ColorsExt on Color {
  String toHex() {
    return "#${value.toRadixString(16)}";
  }
}
