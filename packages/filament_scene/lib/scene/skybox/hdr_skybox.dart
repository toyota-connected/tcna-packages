part of 'skybox.dart';

/// An object that represents skybox that will be loaded from hdr file.
class HdrSkybox extends Skybox {
  ///Indicates whether the sun should be rendered. The sun can only be rendered
  ///if there is at least one light of type LightType.SUN in the Scene.
  ///The default value is false.
  bool showSun = false;

  /// creates skybox object from hdr file from assets.
  HdrSkybox.asset(final String path) : super(assetPath: path);

  /// creates skybox object from hdr file from url.
  HdrSkybox.url(final String url) : super(url: url);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'assetPath': assetPath,
    'url': url,
    'showSun': showSun,
    'skyboxType': 2,
  };

  @override
  String toString() {
    return 'HdrSkybox(assetPath: $assetPath, url: $url, showSun: $showSun)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is HdrSkybox && super == other && other.showSun == showSun;
  }

  @override
  int get hashCode => super.hashCode ^ showSun.hashCode;
}
