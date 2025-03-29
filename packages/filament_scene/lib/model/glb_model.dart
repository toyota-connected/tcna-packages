part of 'model.dart';

/// represents object of model that will be loaded from glb file.
///
/// GLB is a binary container format of glTF.
/// It bundles all the textures and mesh data into a single file.
class GlbModel extends Model {
  /// creates glb model based on glb file asset path.
  GlbModel.asset(
    final String path, {
    required super.scale,
    super.keepInMemory,
    super.isInstancePrimary, 
    super.collidable,
    required super.position,
    super.animation,
    required super.rotation,
    required super.castShadows,
    required super.receiveShadows,
    super.name,
    required super.id
  }) : 
    assert(path.isNotEmpty, "path should not be empty"),
    assert(path.contains('.glb'), "path should be a glb file path"),
    // if is_primary_to_instance_from is true, it cannot have collidable and animation
    assert(
      isInstancePrimary == false || (collidable == null && animation == null),
      "Primary model (instance template) cannot have collidable and animation",
    ),
    super(assetPath: path)
  ;

  /// creates glb model based on glb file url.
  GlbModel.url({
    required super.url,
    required super.id,
    required super.scale,
    required super.position,
    required super.rotation,
    super.keepInMemory,
    super.isInstancePrimary,
    super.animation, 
    required super.receiveShadows, 
    required super.castShadows,
  }) : super();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'assetPath': assetPath,
    'url': url,
    // TODO(kerberjg): update fields in Filament C++ API
    'should_keep_asset_in_memory': keepInMemory,
    'is_primary_to_instance_from': isInstancePrimary,
    'scale': scale?.toJson(),
    'collidable': collidable?.toJson(),
    'rotation': rotation?.toJson(),
    'position': position?.toJson(),
    'animation': animation?.toJson(),
    'castShadows': castShadows,
    'receiveShadows': receiveShadows,
    'isGlb': true,
  };

  @override
  bool operator ==(final  Object other) {
    if (identical(this, other)) return true;

    return
      other is GlbModel &&
      other.assetPath == assetPath &&
      other.url == url &&
      other.scale == scale &&
      other.position == position &&
      other.animation == animation;
  }

  @override
  int get hashCode {
    return
      assetPath.hashCode ^
      url.hashCode ^
      scale.hashCode ^
      position.hashCode ^
      animation.hashCode;
  }
}
