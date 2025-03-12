library model;

import 'package:filament_scene/ecs/entity.dart';
import 'package:filament_scene/scene/geometry/geometry.dart';

part 'animation.dart';
part 'glb_model.dart';
part 'gltf_model.dart';
  
/// represents base object of the 3d model to be rendered.
///
/// see also :
///
/// [GlbModel] :
/// [GltfModel] :
abstract class Model extends Entity {
  /// Model asset path to load the model from assets.
  String? assetPath;

  /// if this is true, we'll keep it in memory so other objects
  /// can use that memory and load from it, not incurring a disk load.
  bool? keepInMemory;

  /// all instances inherit the base transform so you might want a specific
  /// transform to inherit from.
  /// By default these DO NOT get added to the renderable scene!
  bool? isInstancePrimary;

  /// Model url to load the model from url.
  String? url;

  /// Scale Factor of the model.
  /// Should be greater than 0.
  /// Defaults to 1.
  Vector3? scale;

  /// Do we have a collidable for this object (expecting to collide)
  /// For now this will create a box using the extents value
  Collidable? collidable;

  /// Coordinate of center point position of the rendered model.
  ///
  /// Defaults to ( x:0,y: 0,z: -4)
  Vector3? centerPosition;

  /// Controls what animation should be played by the rendered model.
  Animation? animation;

  /// Quaternion rotation for the shape
  Vector4? rotation;

  /// Variables for filament renderer upon shape creation
  bool receiveShadows;

  /// Variables for filament renderer upon shape creation
  bool castShadows;

  Model({
    required super.id,
    super.name,
    this.assetPath,
    this.keepInMemory,
    this.isInstancePrimary,
    this.url,
    this.scale,
    this.rotation,
    this.collidable,
    this.centerPosition,
    this.animation,
    required this.castShadows,
    required this.receiveShadows,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Model &&
        other.assetPath == assetPath &&
        other.url == url &&
        other.scale == scale &&
        other.centerPosition == centerPosition &&
        other.animation == animation;
  }

  @override
  int get hashCode {
    return assetPath.hashCode ^
        url.hashCode ^
        scale.hashCode ^
        centerPosition.hashCode ^
        animation.hashCode;
  }
}
