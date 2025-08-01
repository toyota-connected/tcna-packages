part of './indirect_light.dart';

/// An object that represents indirect light that is created from ktx file format.
///
/// To extract indirect light from images, Use the cmgen tool to generate the indirect light data as ktx file format.
class KtxIndirectLight extends IndirectLight {
  /// creates a new indirect light from ktx file format from assets.
  KtxIndirectLight.asset(final String path, {super.intensity}) : super(assetPath: path);

  /// creates a new indirect light from ktx file format from url.
  KtxIndirectLight.url(final String url, {super.intensity}) : super(url: url);

  @override
  IndirectLightType get lightType => IndirectLightType.ktx;
}
