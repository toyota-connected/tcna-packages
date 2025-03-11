part of 'indirect_light.dart';

/// An object that represents indirect light that is created from hdr file format.
class HdrIndirectLight extends IndirectLight {
  /// creates a new indirect light from HDR file format from assets.
  HdrIndirectLight.asset(final String path, {super.intensity})
      : super(assetPath: path);

  /// creates a new indirect light from HDR file format from url.
  HdrIndirectLight.url(final String url, {super.intensity}) : super(url: url);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'assetPath': assetPath,
    'url': url,
    'intensity': intensity,
    'lightType': 2
  };

  @override
  String toString() {
    return 'HdrIndirectLight(assetPath: $assetPath, url: $url, intensity: $intensity)';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return
      other is HdrIndirectLight &&
      super == other
    ;
  }
}
