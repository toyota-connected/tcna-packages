library model;

import 'package:filament_scene/components/collider.dart';
import 'package:filament_scene/ecs/entity.dart';
import 'package:filament_scene/utils/serialization.dart';

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

  /// Do we have a collider for this object (expecting to collide)
  /// For now this will create a box using the extents value
  Collider? collider;

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
    this.collider,
    required super.position,
    this.animation,
    required this.castShadows,
    required this.receiveShadows,
  }) : assert(assetPath != null && assetPath.isNotEmpty, "path should not be empty"),

       /// if [ModelInstancingType.primaryInstanceable] is true, it cannot have collider and animation
       assert(
         instancingMode != ModelInstancingType.primaryInstanceable ||
             (collider == null && animation == null),
         "Primary model (instance template) cannot have collider and animation",
       );

  @override
  JsonObject toJson() => <String, dynamic>{
    ...super.toJson(),
    'assetPath': assetPath,
    'instancingMode': instancingMode.value,
    'collider': collider?.toJson(),
    'animation': animation?.toJson(),
    'castShadows': castShadows,
    'receiveShadows': receiveShadows,
  };
}
