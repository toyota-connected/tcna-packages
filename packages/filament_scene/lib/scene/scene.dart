import 'package:filament_scene/filament_scene.dart';

/// An object that represents the scene to  be rendered with information about light, skybox and more.
// TODO(kerberjg): separate into Scene(entities, camera) and SceneLighting(skybox, indirectLight)
class Scene {
  Skybox? skybox;
  IndirectLight? indirectLight;
  List<Light>? lights;
  Camera? camera;

  final Map<EntityGUID, Entity> entities = <EntityGUID, Entity>{};

  Scene({this.skybox, this.indirectLight, this.lights, this.camera});

  /*
   *  Entity management
   */
  Entity? getEntity(final EntityGUID id) => entities[id];


  /*
   *  Serialization
   */
  Map<String, dynamic> toJson() => <String, dynamic>{
    'skybox': skybox?.toJson(),
    'lights': lights?.map((final light) => light.toJson()).toList(),
    'indirectLight': indirectLight?.toJson(),
    'camera': camera?.toJson(),
  };

  @override
  String toString() {
    return 'Scene(skybox: $skybox, indirectLight: $indirectLight, lights: $lights, camera: $camera)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Scene &&
        other.skybox == skybox &&
        other.indirectLight == indirectLight &&
        other.lights == lights &&
        other.camera == camera;
  }

  @override
  int get hashCode {
    return skybox.hashCode ^
        indirectLight.hashCode ^
        lights.hashCode ^
        camera.hashCode;
  }

  Scene copyWith({
    final Skybox? skybox,
    final IndirectLight? indirectLight,
    final List<Light>? lights,
    final Camera? camera,
  }) {
    return Scene(
      skybox: skybox ?? this.skybox,
      indirectLight: indirectLight ?? this.indirectLight,
      lights: lights ?? this.lights,
      camera: camera ?? this.camera,
    );
  }
}
