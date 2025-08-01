part of 'skybox.dart';

/// An object that represents skybox that will be loaded from ktx file.
/// Filament supports rendering with image-based lighting, or IBL.
/// This uses an environment map to approximate the lighting all directions.
///the Skybox object can be loaded from a KTX that does contain visible images.
///Filament provides an offline tool called cmgen that can consume an equirectangular image and produce these two files in one fell swoop.
class KtxSkybox extends Skybox {
  /// Creates skybox object from ktx file from assets.
  KtxSkybox.asset(final String path) : super(assetPath: path);

  /// Creates skybox object from ktx file from url.
  KtxSkybox.url(final String url) : super(url: url);

  @override
  SkyboxType get type => SkyboxType.ktx;
}
