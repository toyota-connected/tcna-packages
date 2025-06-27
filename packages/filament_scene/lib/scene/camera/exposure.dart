
/// An object that control camera Exposure.
/// The exposure ultimately controls the scene's brightness,
/// just like with a real camera. The default values provide adequate exposure for a camera
/// placed outdoors on a sunny day with the sun at the zenith. With the default parameters,
/// the scene must contain at least one Light of intensity similar to the sun
/// (e.g.: a 100,000 lux directional light) and/or an indirect light of appropriate intensity (30,000).
/// Default is f/16, 1/125s, 100 ISO
class Exposure {
  /// Aperture in f-stops, clamped between 0.5 and 64. A lower aperture value increases the exposure,
  /// leading to a brighter scene. Realistic values are between 0.95 and 32.
  final double? aperture;

  /// shutterSpeed – Shutter speed in seconds,
  /// clamped between 1/25,000 and 60. A lower shutter speed increases the exposure.
  /// Realistic values are between 1/8000 and 30. sensitivity
  final double? shutterSpeed;

  /// Sensitivity in ISO, clamped between 10 and 204,800.
  /// A higher sensitivity increases the exposure. Realistic values are between 50 and 25600.
  final double? sensitivity;

  /// Sets this camera's exposure directly.
  final double? exposure;

  /// Sets this camera's exposure directly. Calling this method will set the aperture to 1.0,
  /// the shutter speed to 1.2 and the sensitivity will be computed to match the requested exposure
  /// (for a desired exposure of 1.0, the sensitivity will be set to 100 ISO).
  /// This method is useful when trying to match the lighting of other engines or tools.
  /// Many engines/tools use unit-less light intensities,
  /// which can be matched by setting the exposure manually.
  /// This can be typically achieved by setting the exposure to 1.0.
  const Exposure([
    final double exposure = 1.0,
  ]) :
    aperture = null,
    shutterSpeed = null,
    sensitivity = null,
    // ignore: prefer_initializing_formals
    exposure = exposure;

  ///Sets this camera's exposure (default is f/16, 1/125s, 100 ISO)
  const Exposure.fromAperture({
    final double? aperture = 16.0,
    final double? shutterSpeed = 1 / 125.0,
    final double? sensitivity = 100.0,
  }) :
    exposure = null,
    // ignore: prefer_initializing_formals
    aperture = aperture,
    assert(aperture != null && (aperture >= 0.5 && aperture <= 64), "Aperture must be between 0.5 and 64"),
    // ignore: prefer_initializing_formals
    shutterSpeed = shutterSpeed,
    assert(shutterSpeed != null && (shutterSpeed >= 1 / 25000 && shutterSpeed <= 60), "Shutter speed must be between 1/25000 and 60 seconds"),
    // ignore: prefer_initializing_formals
    sensitivity = sensitivity,
    assert(sensitivity != null && (sensitivity >= 10 && sensitivity <= 204800), "Sensitivity must be between 10 and 204800 ISO");

  Exposure copyWith({
    final double? aperture,
    final double? shutterSpeed,
    final double? sensitivity,
    final double? exposure,
  }) {
    if (exposure != null) {
      return Exposure(exposure);
    } else {
      return Exposure.fromAperture(
        aperture: aperture ?? this.aperture,
        shutterSpeed: shutterSpeed ?? this.shutterSpeed,
        sensitivity: sensitivity ?? this.sensitivity,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "aperture": aperture,
      "shutterSpeed": shutterSpeed,
      "sensitivity": sensitivity,
      "exposure": exposure,
    };
  }

  @override
  String toString() {
    return 'Exposure(aperture: $aperture, shutterSpeed: $shutterSpeed, sensitivity: $sensitivity, exposure: $exposure)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Exposure &&
        other.aperture == aperture &&
        other.shutterSpeed == shutterSpeed &&
        other.sensitivity == sensitivity &&
        other.exposure == exposure;
  }

  @override
  int get hashCode {
    return aperture.hashCode ^
        shutterSpeed.hashCode ^
        sensitivity.hashCode ^
        exposure.hashCode;
  }
}
