part of '../material.dart';

/// An object represents textures to be loaded by the material.
class Texture {
  /// asset path of the texture.
  String? assetPath;

  /// url of the texture.
  String? url;

  /// type of the texture.
  TextureType? type;

  ///
  TextureSampler? sampler;

  Texture.asset(this.assetPath, {this.type, this.sampler});

  Texture.url(this.url, {this.type, this.sampler});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'assetPath': assetPath,
    'url': url,
    'type': type?.value,
    'sampler': sampler?.toJson(),
  };

  @override
  String toString() {
    return 'Texture(assetPath: $assetPath, url: $url, type: $type, sampler: $sampler)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Texture &&
        other.assetPath == assetPath &&
        other.url == url &&
        other.type == type &&
        other.sampler == sampler;
  }

  @override
  int get hashCode =>
      assetPath.hashCode ^ url.hashCode ^ type.hashCode ^ sampler.hashCode;
}
