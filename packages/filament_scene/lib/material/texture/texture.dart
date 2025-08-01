part of '../material.dart';

/// An object represents textures to be loaded by the material.
class Texture with Jsonable {
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

  @override
  JsonObject toJson() => <String, dynamic>{
    'assetPath': assetPath,
    'url': url,
    'type': type?.value,
    'sampler': sampler?.toJson(),
  };
}
