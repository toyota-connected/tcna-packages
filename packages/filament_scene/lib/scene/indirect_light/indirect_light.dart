library indirect_light;

part './default_indirect_light.dart';
part './hdr_indirect_light.dart';
part './ktx_indirect_light.dart';



/// An object that represents Indirect Light which is used to simulate environment lighting, a form of global illumination.
/// Filament supports rendering with image-based lighting, or IBL.
/// This uses an environment map to approximate the lighting all directions.
/// Environment lighting has a two components:
/// irradiance  -  reflections (specular component)
/// Environments are usually captured as high-resolution HDR equirectangular images
/// and processed by the cmgen tool to generate the data needed by IndirectLight.
/// Currently IndirectLight is intended to be used for "distant probes",
/// that is, to represent global illumination from a distant (i.e. at infinity) environment,
/// such as the sky or distant mountains.
/// Only a single IndirectLight can be used in a Scene. This limitation will be lifted in the future.
/// Use the cmgen tool to generate the Spherical Harmonics for a given environment.
///
/// See also:
/// [KtxIndirectLight] : creates indirect light from ktx file.
/// [HdrIndirectLight] : creates indirect light from hdr file.
/// [DefaultIndirectLight] : creates indirect light from default parameters like intensity, irradiance ,etc.
///
/// Defaults to   [DefaultIndirectLight] with intensity = 30_000,
/// radianceBands = 1, radianceSh = [1,1,1], irradianceBands = 1, irradianceSh =[1,1,1]
abstract class IndirectLight {
  /// light asset path used to load KTX FILE from assets.
  /// used to change indirect lighting from Image-Based Light.
  String? assetPath;

  /// light url used to load KTX FILE from assets.
  /// used to change indirect lighting from Image-Based Light.
  String? url;

  /// indirect light intensity.
  /// can be used with light asset path.
  /// or create default light with certain intensity.
  double? intensity;

  IndirectLight({
    this.assetPath,
    this.url,
    this.intensity,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'intensity': intensity,
    'assetPath': assetPath,
    'url': url,
  };

  @override
  String toString() {
    return 'IndirectLight(assetPath: $assetPath, url: $url, intensity: $intensity)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return
      other is IndirectLight &&
      other.assetPath == assetPath &&
      other.url == url &&
      other.intensity == intensity
    ;
  }

  @override
  int get hashCode => assetPath.hashCode ^ url.hashCode ^ intensity.hashCode;
}
