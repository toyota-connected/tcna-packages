library model;

import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/entity/entity.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:vector_math/vector_math.dart';

part 'animation.dart';
part 'glb_model.dart';
part 'gltf_model.dart';
  
/// represents base object of the 3d model to be rendered.
///
/// see also :
///
/// [GlbModel] :
/// [GltfModel] :
abstract class Model extends TransformEntity {
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

  /// Do we have a collidable for this object (expecting to collide)
  /// For now this will create a box using the extents value
  Collidable? collidable;

  /// Controls what animation should be played by the rendered model.
  Animation? animation;

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
    required super.scale,
    required super.rotation,
    this.collidable,
    required super.position,
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
        other.position == position &&
        other.animation == animation;
  }

  @override
  int get hashCode {
    return assetPath.hashCode ^
        url.hashCode ^
        scale.hashCode ^
        position.hashCode ^
        animation.hashCode;
  }
}
