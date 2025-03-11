import 'package:filament_scene/scene/camera/camera.dart';
import 'package:filament_scene/scene/indirect_light/indirect_light.dart';
import 'package:filament_scene/scene/light/light.dart';
import 'package:filament_scene/scene/skybox/skybox.dart';

/// An object that represents the scene to  be rendered with information about light, skybox and more.
// TODO(kerberjg): separate into Scene(entities, camera) and SceneLighting(skybox, indirectLight)
class Scene {
  Skybox? skybox;
  IndirectLight? indirectLight;
  List<Light>? lights;
  Camera? camera;

  Scene({this.skybox, this.indirectLight, this.lights, this.camera});

  Map<String, dynamic> toJson() => {
    'skybox': skybox?.toJson(),
    'lights': lights?.map((light) => light.toJson()).toList(),
    'indirectLight': indirectLight?.toJson(),
    'camera': camera?.toJson(),
  };

  @override
  String toString() {
    return 'Scene(skybox: $skybox, indirectLight: $indirectLight, lights: $lights, camera: $camera)';
  }

  @override
  bool operator ==(Object other) {
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
    Skybox? skybox,
    IndirectLight? indirectLight,
    List<Light>? lights,
    Camera? camera,
  }) {
    return Scene(
      skybox: skybox ?? this.skybox,
      indirectLight: indirectLight ?? this.indirectLight,
      lights: lights ?? this.lights,
      camera: camera ?? this.camera,
    );
  }
}
