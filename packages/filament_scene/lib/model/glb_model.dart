part of 'model.dart';

/// represents object of model that will be loaded from glb file.
///
/// GLB is a binary container format of glTF.
/// It bundles all the textures and mesh data into a single file.
class GlbModel extends Model {
  /// creates glb model based on glb file asset path.
  GlbModel.asset({
    required super.assetPath,
    required super.scale,
    super.instancingMode,
    super.collidable,
    required super.position,
    super.animation,
    required super.rotation,
    required super.castShadows,
    required super.receiveShadows,
    super.name,
    required super.id,
  }) :
    assert(assetPath!.contains('.glb'), "path should be a glb file path"),
    super()
  ;


  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'isGlb': true,
  };

  @override
  // ignore: hash_and_equals
  bool operator ==(final  Object other) {
    if (identical(this, other)) return true;

    return
      other is GlbModel &&
      other.assetPath == assetPath &&
      other.scale == scale &&
      other.position == position &&
      other.animation == animation;
  }
}
