
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
  static final Vector3 scenePosition = Vector3(-72, 0, 68);
  static final Vector3 cameraOffset = Vector3(-20, 15, 0);

  PlanetariumSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  @override
  _PlanetariumSceneViewState createState() => _PlanetariumSceneViewState();

  static Map<String, EntityGUID> objectGuids = {
    // Models
    // Shapes
    'system': generateGuid(),
    'sun': generateGuid(),
    'mercury': generateGuid(),
    'venus': generateGuid(),
    // earth + moon
    'earth': generateGuid(),
    'moon': generateGuid(),
    //
    'mars': generateGuid(),
    'asteroid_belt': generateGuid(),
    // jupiter + moons
    'jupiter': generateGuid(),
    'io': generateGuid(),
    'europa': generateGuid(),
    'ganymede': generateGuid(),
    'callisto': generateGuid(),
    // saturn + moons
    'saturn': generateGuid(),
    'saturn_ring': generateGuid(),
    'titan': generateGuid(),
    //
    'uranus': generateGuid(),
    'neptune': generateGuid(),
    'pluto': generateGuid(),
    // Lights
    'sun_light': generateGuid(),
    'moon_light': generateGuid(),
  };

  static Map<String, Color> planetColors = {
    'sun': const Color(0xFFFFD700),
    'mercury': const Color(0xFFB0B0B0),
    'venus': const Color(0xFFFFA500),
    'earth': const Color(0xFF0000FF),
    'moon': const Color(0xFF808080),
    'mars': const Color(0xFFFF4500),
    'asteroid_belt': const Color(0xFF8B4513),
    // jupiter + moons
    'jupiter': const Color(0xFFFFD700),
    'io': const Color(0xFF8B4513),
    'europa': const Color(0xFFADD8E6),
    'ganymede': const Color(0xFF8B4513),
    'callisto': const Color(0xFF8B4513),
    // saturn + moons
    'saturn': const Color(0xFFFFD700),
    'saturn_ring': const Color(0xFFFFD700),
    'titan': const Color(0xFF8B4513),
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
    'moon': 0.3,
    'mars': 0.7,
    'jupiter': 2.3,
    'io': 0.4,
    'europa': 0.4,
    'ganymede': 0.5,
    'callisto': 0.5,
    'saturn': 2.0,
    'saturn_ring': 2.5,
    'titan': 0.5,
    'uranus': 1.25,
    'neptune': 1.5,
    'pluto': 0.25,
    // distance from the center
    'asteroid_belt': 20.0,
  };

  static const double planetScale = 0.05;

  /// each planet has a orbit
  /// if orbits around middle, set null
  static const Map<String, String?> planetOrbits = {
    'sun': null,
    'mercury': null,
    'venus': null,
    'earth': null,
    // moon orbits around earth
    'moon': 'earth',
    'mars': null,
    'asteroid_belt': null,
    // jupiter orbits around sun
    'jupiter': null,
    // moons orbits around jupiter
    'io': 'jupiter',
    'europa': 'jupiter',
    'ganymede': 'jupiter',
    'callisto': 'jupiter',
    // saturn orbits around sun
    'saturn': null,
    // moons orbits around saturn
    'saturn_ring': null,
    'titan': 'saturn',
    //
    'uranus': null,
    'neptune': null,
    // pluto orbits around sun
    'pluto': null,
  };

  /// each distance is relative to the middle
  static Map<String, double> planetDistances = {
    'sun': 0.0,
    'mercury': planetSizes['sun']! + planetSizes['mercury']! * 2,
    'venus': planetSizes['mercury']! * 2 + planetSizes['venus']! * 2,
    'earth': planetSizes['venus']! * 2 + planetSizes['earth']! * 2,
    // relative to earth
    'moon': planetSizes['earth']! * 2.5,
    'mars': planetSizes['earth']! * 2 + planetSizes['mars']! * 2,
    'asteroid_belt': planetSizes['mars']! * 2 + planetSizes['asteroid_belt']! * 2,
    'jupiter': planetSizes['asteroid_belt']! * 2 + planetSizes['jupiter']! * 2,
    // moons relative to jupiter
    'io': planetSizes['jupiter']! * 2 + planetSizes['io']! * 2,
    'europa': planetSizes['jupiter']! * 2 + planetSizes['europa']! * 2,
    'ganymede': planetSizes['jupiter']! * 2 + planetSizes['ganymede']! * 2,
    'callisto': planetSizes['jupiter']! * 2 + planetSizes['callisto']! * 2,
    //
    'saturn': planetSizes['callisto']! * 2 + planetSizes['saturn']! * 2,
    // moons relative to saturn
    'saturn_ring': planetSizes['saturn']! * 1.5,
    'titan': planetSizes['saturn']! * 2 + planetSizes['titan']! * 2,
    //
    'uranus': planetSizes['saturn']! * 2 + planetSizes['uranus']! * 2,
    'neptune': planetSizes['uranus']! * 2 + planetSizes['neptune']! * 2,
    'pluto': planetSizes['neptune']! * 6 + planetSizes['pluto']! * 2,
  };

  static List<Model> getSceneModels() {
    return [];
  }

  static List<Shape> getSceneShapes() {
    final Map<String, Shape> shapes = {};

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

    // Create orbits
    final Map<String, EntityGUID> orbitIds = {};
    for(final String name in planetOrbits.keys) {
      if(planetOrbits[name] != null) {
        orbitIds[name] = generateGuid();
        shapes["${name}_orbit"] = Sphere(
          id: orbitIds[name]!,
          name: name,
          parentId: objectGuids['system']!,
          position: Vector3.all(0),
          scale: Vector3.all(planetDistances[name]! * planetScale),
          size: Vector3.all(1),
          rotation: Quaternion.identity(),
          stacks: 8,
          slices: 8,
          receiveShadows: false,
          castShadows: false,
          material: poGetLitMaterial(const Color(0x10000000)),
          collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
        );
      }
    }

    for(final String name in planetDistances.keys) {
      final double distance = planetDistances[name]!;
      
      print('planet: $name (${objectGuids[name]!}), distance: ${planetDistances[name]}, size: ${planetSizes[name]}');
      shapes[name] = Sphere(
        id: objectGuids[name]!,
        name: name,
        parentId: planetOrbits[name] == null
          ? objectGuids['system']
          : orbitIds[name]!,
        position: Vector3(1, 0, 0),
        scale: Vector3.all(distance > 0
          ? (distance / planetSizes[name]!)
          : planetSizes[name]!
        ) * planetScale,
        size: Vector3.all(1),
        rotation: Quaternion.identity(),
        collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
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
    lights.add(Light(
      type: LightType.directional,
      color: planetColors['sun']!,
      intensity: 1.0,
      direction: Vector3(0, 0, -1),
      id: objectGuids['sun_light']!,
    ));

    // moon light
    lights.add(Light(
      type: LightType.point,
      color: planetColors['moon']!,
      intensity: 0.5,
      position: Vector3(planetDistances['moon']!, 0, 0),
      id: objectGuids['moon_light']!,
    ));

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
  }

  @override
  void onTriggerEvent(final String eventName, [ final dynamic? eventData ]) {}

  @override
  void onUpdateFrame(FilamentViewApi engine, double dt) {

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