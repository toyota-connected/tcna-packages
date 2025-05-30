
import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:flutter/material.dart';
import 'package:my_fox_example/material_helpers.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:my_fox_example/shape_and_object_creators.dart';

class PlanetariumSceneView extends StatefulSceneView {
  static final Vector3 scenePosition = Vector3(-720, 0, 680);
  static final Vector3 cameraOffset = Vector3(0, 90, 0);

  PlanetariumSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  @override
  _PlanetariumSceneViewState createState() => _PlanetariumSceneViewState();

  static const List<String> planets = [
    'sun',
    'mercury',
    'venus',
    'earth',
    'mars',
    'jupiter',
    'saturn',
    'uranus',
    'neptune',
    'pluto'
  ];

  static Map<String, EntityGUID> objectGuids = {
    // Models
    // Shapes
    'system': generateGuid(),
    'system_bg': generateGuid(),
    //
    'sun': generateGuid(),
    'mercury': generateGuid(),
    'venus': generateGuid(),
    'earth': generateGuid(),
    'mars': generateGuid(),
    'jupiter': generateGuid(),
    'saturn': generateGuid(),
    'uranus': generateGuid(),
    'neptune': generateGuid(),
    'pluto': generateGuid(),
    // Lights
    'sun_light': generateGuid(),
    'moon_light': generateGuid(),
  };

  static Map<String, Color> planetColors = {
    'sun': const Color(0xFFFFD700),
    'mercury': const Color.fromARGB(255, 201, 167, 128),
    'venus': const Color(0xFFFFA500),
    'earth': const Color.fromARGB(255, 0, 162, 255),
    'moon': const Color(0xFF808080),
    'mars': const Color(0xFFFF4500),
    // jupiter + moons
    'jupiter': const Color.fromARGB(255, 255, 205, 66),
    'saturn': const Color.fromARGB(255, 255, 240, 157),
    //
    'uranus': const Color(0xFF00FFFF),
    'neptune': const Color(0xFF00008B),
    'pluto': const Color(0xFF8B4513),
  };

  // 
  static const Map<String, double> planetSizes = {
    'sun': 10.0,
    'mercury': 0.5,
    'venus': 1.5,
    'earth': 1.0,
    'mars': 0.7,
    'jupiter': 2.3,
    'saturn': 2.0,
    'titan': 0.5,
    'uranus': 1.25,
    'neptune': 1.5,
    'pluto': 0.25,
  };

  static const double planetScale = 1;

  /// each distance is relative to the middle
  static Map<String, double> planetDistances = {
    'sun': 0,
    'mercury': 10,
    'venus': 13,
    'earth': 15,
    'mars': 18,
    'jupiter': 25,
    'saturn': 30,
    'uranus': 35,
    'neptune': 40,
    'pluto': 45,
  };

  // speed of orbit (full rotations per year)
  static Map<String, double> planetSpeeds = {
    'sun': 365,
    'mercury': 0.24,
    'venus': 0.615,
    'earth': 1,
    'mars': 1.88,
    'jupiter': 11.86,
    'saturn': 29.46,
    'uranus': 84.01,
    'neptune': 164.8,
    'pluto': 248,
  };


  static List<Model> getSceneModels() {
    return [];
  }

  static List<Shape> getSceneShapes() {
    final Map<String, Shape> shapes = {};
    // return shapes.values.toList();

    shapes['system'] = Sphere(
      id: objectGuids['system']!,
      name: 'system',
      position: scenePosition,
      scale: Vector3.all(1),
      size: Vector3.all(1),
      rotation: Quaternion.identity(),
      stacks: 8,
      slices: 8,
      receiveShadows: false,
      castShadows: false,
      material: poGetLitMaterial(const Color(0x10000000)),
    );

    // TODO: double-sided spheres are not implemented in filament_view
    // shapes['system_bg'] = Sphere(
    //   id: objectGuids['system_bg']!,
    //   name: 'system_bg',
    //   // parentId: objectGuids['system']!,
    //   // position: Vector3.all(0),
    //   position: scenePosition,
    //   scale: Vector3.all(200),
    //   size: Vector3.all(1),
    //   rotation: Quaternion.identity(),
    //   stacks: 64,
    //   slices: 64,
    //   receiveShadows: false,
    //   castShadows: false,
    //   material: poGetLitMaterial(const Color(0x10000000)),
    //   doubleSided: true,
    // );

    // Create orbits
    // for each planet create a sphere
    // of the size equal to the distance of the planet
    // If a planet has an orbit, parent it to the orbit,
    // otherwise parent it to the system
    final Map<String, EntityGUID> orbitIds = {};
    for(final String name in planets) {
      final id = orbitIds[name] = generateGuid();
      objectGuids["${name}_orbit"] = id;

      shapes["${name}_orbit"] = Sphere(
        id: id,
        name: "${name}_orbit",
        parentId: objectGuids['system']!,
        position: Vector3.all(0),
        scale: name == 'sun'
          ? Vector3.all(1)
          : Vector3.all(planetDistances[name]!),
        size: Vector3.all(1),
        rotation: Quaternion.identity(),
        stacks: 8,
        slices: 8,
        receiveShadows: false,
        castShadows: false,
        material: poGetLitMaterial(const Color(0x10000000)),
      );
    }

    // Create planets
    for(final String name in planets) {
      final double distance = planetDistances[name]!;
      print("$name distance: $distance");
      print('planet: $name (${objectGuids[name]!}), distance: ${planetDistances[name]}, size: ${planetSizes[name]}');
      
      shapes[name] = Sphere(
        id: objectGuids[name]!,
        name: "${name}_planet",
        parentId: orbitIds[name]!,
        position: name == 'sun'
          ? Vector3.all(0)
          : Vector3(1, 0, 0),
        scale: name == 'sun'
          ? Vector3.all(planetSizes[name]!)
          : Vector3.all(planetSizes[name]! / distance),
        size: Vector3.all(1),
        rotation: Quaternion.identity(),
        // collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
        material: poGetLitMaterial(planetColors[name]!),
        stacks: 20,
        slices: 20,
        receiveShadows: true,
        castShadows: false,
      );
    }

    return shapes.values.toList();
  }

  static List<Light> getSceneLights() {
    final List<Light> lights = [];

    // sun light
    // lights.add(Light(
    //   type: LightType.directional,
    //   color: planetColors['sun']!,
    //   intensity: 1.0,
    //   direction: Vector3(0, 0, -1),
    //   id: objectGuids['sun_light']!,
    //   position: scenePosition,
    // ));

    return lights;
  }
}

class _PlanetariumSceneViewState extends StatefulSceneViewState {
  @override
  void onCreate() {
    final Vector3 cameraOffset = PlanetariumSceneView.scenePosition + PlanetariumSceneView.cameraOffset;

    // set camera
    widget.filament.changeCameraTargetPosition(
      PlanetariumSceneView.scenePosition.x,
      PlanetariumSceneView.scenePosition.y,
      PlanetariumSceneView.scenePosition.z,
    );
    widget.filament.changeCameraOrbitHomePosition(
      cameraOffset.x,
      cameraOffset.y,
      cameraOffset.z,
    );
    widget.filament.changeCameraFlightStartPosition(
      cameraOffset.x,
      cameraOffset.y,
      cameraOffset.z,
    );

    widget.filament.setFogOptions(false);

    // deactivate rendering for system and orbits
    widget.filament.turnOffVisualForEntity(PlanetariumSceneView.objectGuids['system']!);
    for(final String name in PlanetariumSceneView.objectGuids.keys) {
      if(name.endsWith('_orbit')) {
        widget.filament.turnOffVisualForEntity(PlanetariumSceneView.objectGuids[name]!);
      }
    }

  }

  @override
  void onTriggerEvent(final String eventName, [ final dynamic? eventData ]) {}

  double _timer = 60 * 10; // 10 minutes

  @override
  void onUpdateFrame(FilamentViewApi engine, double dt) {
    _timer += dt;

    // rotate planets
    for(final String name in PlanetariumSceneView.planets) {
      final double speed = 1 / PlanetariumSceneView.planetSpeeds[name]! * 0.25;
      final double distance = PlanetariumSceneView.planetDistances[name]!;

      // rotate around the sun
      final double angle = _timer * speed * 2 * 3.14;
      Quaternion rot = Quaternion.euler(angle, 0, 0);

      widget.filament.changeRotationByGUID(
        PlanetariumSceneView.objectGuids["${name}_orbit"]!,
        rot.x, rot.y, rot.z, rot.w,
      );
    }
  }

  @override
  void onDestroy() {

  }

  /*
   *  UI
   */
  Widget build(BuildContext context) {
    return Container();
  }
}