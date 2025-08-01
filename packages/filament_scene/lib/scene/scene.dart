import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/utils/serialization.dart';

/// An object that represents the scene to  be rendered with information about light, skybox and more.
// TODO(kerberjg): separate into Scene(entities, camera) and SceneLighting(skybox, indirectLight)
class Scene with Jsonable {
  Skybox? skybox;
  IndirectLight? indirectLight;
  List<Light>? lights;

  final Map<EntityGUID, Entity> entities = <EntityGUID, Entity>{};

  Scene({this.skybox, this.indirectLight, this.lights});

  /*
   *  Entity management
   */
  Entity? getEntity(final EntityGUID id) => entities[id];

  /*
   *  Serialization
   */
  @override
  JsonObject toJson() => <String, dynamic>{
    'skybox': skybox?.toJson(),
    'lights': lights?.map((final light) => light.toJson()).toList(),
    'indirectLight': indirectLight?.toJson(),
  };

  Scene copyWith({
    final Skybox? skybox,
    final IndirectLight? indirectLight,
    final List<Light>? lights,
  }) {
    return Scene(
      skybox: skybox ?? this.skybox,
      indirectLight: indirectLight ?? this.indirectLight,
      lights: lights ?? this.lights,
    );
  }
}
