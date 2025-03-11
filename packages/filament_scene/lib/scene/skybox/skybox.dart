library skybox;

import 'dart:ui';
import 'package:filament_scene/utils/colors_ext.dart';

part 'colored_skybox.dart';
part 'hdr_skybox.dart';
part 'ktx_skybox.dart';

/// An object that represents the skybox to be rendered in the scene.
///
/// See Also:
/// [KtxSkybox] : creates Skybox from Ktx file.
/// [HdrSkybox] : creates Skybox from Hdr file.
/// [ColoredSkybox] : creates Skybox from color.
///
/// Defaults to transparent skybox.
abstract class Skybox {
  /// environment asset path used to load KTX FILE from assets.
  /// changes scene skybox from images converted to KTX FILE.
  /// Filament provides an offline tool called cmgen
  /// that can consume an image
  /// and produce Light and skybox ktx files in one fell swoop.
  String? assetPath;

  /// environment url used to load KTX FILE from web.
  String? url;

  /// Environment Color.
  /// Changes the background color for the scene.
  /// if not provided and environment asset path is not provided,
  /// A Transparent color will be used.
  Color? color;

  Skybox({
    this.color,
    this.assetPath,
    this.url,
  });

  Map<String, dynamic> toJson() => {
        'assetPath': assetPath,
        'url': url,
        'color': color?.toHex,
      };

  @override
  String toString() {
    return 'Skybox(assetPath: $assetPath, url: $url, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Skybox &&
        other.assetPath == assetPath &&
        other.url == url &&
        other.color == color;
  }

  @override
  int get hashCode => assetPath.hashCode ^ url.hashCode ^ color.hashCode;
}
