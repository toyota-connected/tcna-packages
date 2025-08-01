library skybox;

import 'dart:ui';
import 'package:filament_scene/utils/serialization.dart';

part 'color_skybox.dart';
part 'hdr_skybox.dart';
part 'ktx_skybox.dart';

/// Enumerates the types of skyboxes.
enum SkyboxType {
  /// Skybox created from a KTX file.
  ktx(1),

  /// Skybox created from an HDR file.
  hdr(2),

  /// Skybox created from a solid color.
  color(3);

  final int value;
  const SkyboxType(this.value);
}

/// An object that represents the skybox to be rendered in the scene.
///
/// See Also:
/// [KtxSkybox] : creates Skybox from Ktx file.
/// [HdrSkybox] : creates Skybox from Hdr file.
/// [ColorSkybox] : creates Skybox from color.
///
/// Defaults to transparent skybox.
abstract class Skybox with Jsonable {
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

  Skybox({this.color, this.assetPath, this.url});

  SkyboxType get type;

  @override
  JsonObject toJson() => <String, dynamic>{
    'assetPath': assetPath,
    'url': url,
    'color': color?.toHex(),
    'skyboxType': type.value,
  };
}
