import 'dart:typed_data';

import 'package:flutter/widgets.dart' as Flutter show Color;

typedef BaseColor = Flutter.Color;

/// Extension for base Color class
extension ColorExtras on BaseColor {
  /// Returns a copy of this color as Float32List
  Float32List get storage {
    final Float32List list = Float32List(4);
    list[0] = r;
    list[1] = g;
    list[2] = b;
    list[3] = a;
    return list;
  }

  /// Returns a copy of this color as Float64List
  Float64List get storage64 {
    final Float64List list = Float64List(4);
    list[0] = r;
    list[1] = g;
    list[2] = b;
    list[3] = a;
    return list;
  }
}
