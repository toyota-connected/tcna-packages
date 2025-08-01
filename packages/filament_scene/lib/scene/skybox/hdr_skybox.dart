part of 'skybox.dart';

/// An object that represents skybox that will be loaded from hdr file.
class HdrSkybox extends Skybox {
  /// Indicates whether the sun should be rendered. The sun can only be rendered
  /// if there is at least one light of type LightType.SUN in the Scene.
  /// The default value is false.
  bool showSun = false;

  /// creates skybox object from hdr file from assets.
  HdrSkybox.asset(final String path) : super(assetPath: path);

  /// creates skybox object from hdr file from url.
  HdrSkybox.url(final String url) : super(url: url);

  @override
  SkyboxType get type => SkyboxType.hdr;

  @override
  JsonObject toJson() => <String, dynamic>{
    ...super.toJson(), //
    'showSun': showSun, //
  };
}
