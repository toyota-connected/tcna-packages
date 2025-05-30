library model;

import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/entity/entity.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:vector_math/vector_math.dart';

part 'animation.dart';
part 'glb_model.dart';

enum ModelInstancingType {
  /// Model is not instanced, will be used once
  none(0),
  /// Model is instanceable - primary object, will be used as a template for other instances
  /// It will not be rendered
  primaryInstanceable(1),
  /// Model is instanced - rendered as a copy of the primary object
  instanced(2);

  final int value;
  const ModelInstancingType(this.value);
}
  
/// represents base object of the 3d model to be rendered.
///
/// see also :
///
/// [GlbModel] :
abstract class Model extends TransformEntity {
  /// Model asset path to load the model from assets.
  String? assetPath;

  /// Model instancing mode - whether the model is instanced or not.
  /// Default is [ModelInstancingType.none].
  ModelInstancingType instancingMode;

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
    this.instancingMode = ModelInstancingType.none,
    required super.scale,
    required super.rotation,
    this.collidable,
    required super.position,
    this.animation,
    required this.castShadows,
    required this.receiveShadows,
  })  : 
    assert(assetPath != null && assetPath.isNotEmpty, "path should not be empty"),
    /// if [ModelInstancingType.primaryInstanceable] is true, it cannot have collidable and animation
    assert(
      instancingMode != ModelInstancingType.primaryInstanceable || (collidable == null && animation == null),
      "Primary model (instance template) cannot have collidable and animation",
    )
  ;

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'assetPath': assetPath,
    'instancingMode': instancingMode.value,
    'collidable': collidable?.toJson(),
    'animation': animation?.toJson(),
    'castShadows': castShadows,
    'receiveShadows': receiveShadows,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Model &&
        other.assetPath == assetPath &&
        other.scale == scale &&
        other.position == position &&
        other.animation == animation;
  }

  @override
  int get hashCode {
    return 
      assetPath.hashCode ^
      scale.hashCode ^
      position.hashCode ^
      animation.hashCode;
  }
}
