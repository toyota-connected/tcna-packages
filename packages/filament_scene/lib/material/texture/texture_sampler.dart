part of '../material.dart';

/// Magnification filter to be used.
///
/// See Also:
/// [TextureSampler]
enum MagFilter {
  /// No filtering. Nearest neighbor is used.
  nearest("NEAREST"),

  /// Box filtering. Weighted average of 4 neighbors is used.
  linear("LINEAR");

  final String value;
  const MagFilter(this.value);
}



/// Minification filter to be used.
///
/// See Also:
/// [TextureSampler]
enum MinFilter {
  /// No filtering. Nearest neighbor is used.
  nearest("NEAREST"),

  /// Box filtering. Weighted average of 4 neighbors is used.
  linear("LINEAR"),

  /// Mip-mapping is activated. But no filtering occurs.
  nearestMipmapNearest("NEAREST_MIPMAP_NEAREST"),

  /// Box filtering within a mip-map level.
  linearMipmapNearest("LINEAR_MIPMAP_NEAREST"),

  /// Mip-map levels are interpolated, but no other filtering occurs.
  nearestMipmapLinear("NEAREST_MIPMAP_LINEAR"),

  /// Both interpolated Mip-mapping and linear filtering are used.
  linearMipmapLinear("LINEAR_MIPMAP_LINEAR");

  final String value;
  const MinFilter(this.value);
}




///Type of the texture to be used
/// Color is the only type of texture we want to pre-multiply with the alpha channel
/// Pre-multiplication is the default behavior, so we need to turn it off  based on the type.
enum TextureType {
  color("COLOR"),
  normal("NORMAL"),
  data("DATA");

  final String value;
  const TextureType(this.value);
}



///Wrap Mode to be used.
///
///See Also:
///[TextureSampler]
enum WrapMode {
  /// The edge of the texture extends to infinity.
  clampToEdge("CLAMP_TO_EDGE"),

  /// The texture infinitely repeats in the wrap direction.
  repeat("REPEAT"),

  /// The texture infinitely repeats and mirrors in the wrap direction.
  mirroredRepeat("MIRRORED_REPEAT");

  final String value;
  const WrapMode(this.value);
}




/// An object that defines how a texture is accessed.
class TextureSampler {
  ///Minification filter to be used.
  /// Defaults to LINEAR_MIPMAP_LINEAR
  MinFilter min;

  ///Magnification filter to be used.
  /// Defaults to LINEAR
  MagFilter mag;

  /// Wrap mode to be used
  /// Defaults to REPEAT
  WrapMode wrap;

  ///Amount of anisotropy, controls anisotropic filtering, should be a power-of-two. The default is 0. The maximum permissible value is 7.
  double? anisotropy;

  TextureSampler({
    this.min = MinFilter.linearMipmapLinear,
    this.mag = MagFilter.linear,
    this.wrap = WrapMode.clampToEdge,
    this.anisotropy,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'min': min.value,
    'mag': mag.value,
    'wrap': wrap.value,
    'anisotropy': anisotropy,
  };

  @override
  String toString() {
    return 'TextureSampler(min: $min, mag: $mag, wrap: $wrap, anisotropy: $anisotropy)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is TextureSampler &&
      other.min == min &&
      other.mag == mag &&
      other.wrap == wrap &&
      other.anisotropy == anisotropy
    ;
  }

  @override
  int get hashCode =>
      min.hashCode ^ mag.hashCode ^ wrap.hashCode ^ anisotropy.hashCode;
}
