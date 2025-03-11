part of './indirect_light.dart';

/// An object that represents indirect light based on given parameters like:
/// Irradiance
/// The irradiance represents the light that comes from the environment and shines an object's surface.
/// The irradiance is calculated automatically from the Reflections (see below), and generally doesn't need to be provided explicitly.
/// However, it can be provided separately from the Reflections as Spherical Harmonics  (SH) of 1, 2 or 3 bands, respectively 1, 4 or 9 coefficients.
class DefaultIndirectLight extends IndirectLight {
  /// radiance Bands: Number of spherical harmonics bands. Must be 1, 2 or 3.
  int? radianceBands;

  ///radianceSh – Array containing the spherical harmonics coefficients.
  /// The size of the array must be 3 × bands2 (i.e. 1, 4 or 9 float3 coefficients respectively).
  /// Sets the irradiance from the radiance expressed as Spherical Harmonics.
  // The radiance must be specified as Spherical Harmonics coefficients Ll,m,
  // where each coefficient is comprised of three floats for red, green and blue components, respectively
  // The index in the sh array is given by: index(l, m) = 3 × (l * (l + 1) + m)
  // sh[index(l,m) + 0] = LRl,m sh[index(l,m) + 1] = LGl,m sh[index(l,m) + 2] = LBl,m
  List<double>? radianceSh;

  /// irradiance Bands: Number of spherical harmonics bands. Must be 1, 2 or 3.
  int? irradianceBands;

  /// irradiance sh –  Array containing the spherical harmonics coefficients.
  /// The size of the array must be 3 × bands2 (i.e. 1, 4 or 9 float3 coefficients respectively).
  ///Sets the irradiance as Spherical Harmonics.
  // The irradiance coefficients must be pre-convolved by < n ⋅ l > and pre-multiplied by the Lambertian diffuse BRDF 1/π and specified as Spherical Harmonics coefficients.
  // Additionally, these Spherical Harmonics coefficients must be pre-scaled by the reconstruction factors Al,m.
  // The final coefficients can be generated using the cmgen tool.
  // The index in the sh array is given by: index(l, m) = 3 × (l * (l + 1) + m)
  // sh[index(l,m) + 0] = LRl,m × 1/π × Al,m × Cl  sh[index(l,m) + 1] = LGl,m × 1/π × Al,m × Cl
  // sh[index(l,m) + 2] = LBl,m × 1/π × Al,m × Cl
  List<double>? irradianceSh;

  /// rotation – 3x3 rotation matrix. Must be a rigid-body transform.
  ///Specifies the rigid-body transformation to apply to the IBL.
  List<double>? rotation;

  DefaultIndirectLight({
    super.intensity,
    this.radianceBands,
    this.radianceSh,
    this.irradianceBands,
    this.irradianceSh,
    this.rotation,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'intensity': intensity,
    'radianceBands': radianceBands,
    'radianceSh': radianceSh,
    'irradianceBands': irradianceBands,
    'irradianceSh': irradianceSh,
    'rotation': rotation,
    'lightType': 3,
  };

  @override
  String toString() {
    return 'DefaultIndirectLight(intensity: $intensity, radianceBands: $radianceBands, radianceSh: $radianceSh, irradianceBands: $irradianceBands, irradianceSh: $irradianceSh, rotation: $rotation)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return
      other is DefaultIndirectLight &&
      other.radianceBands == radianceBands &&
      other.radianceSh == radianceSh &&
      other.irradianceBands == irradianceBands &&
      other.irradianceSh == irradianceSh &&
      other.rotation == rotation &&
      super == other
    ;
  }

  @override
  int get hashCode {
    return
      radianceBands.hashCode ^
      radianceSh.hashCode ^
      irradianceBands.hashCode ^
      irradianceSh.hashCode ^
      rotation.hashCode ^
      super.hashCode
    ;
  }
}
