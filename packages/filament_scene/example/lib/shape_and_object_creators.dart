import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:my_fox_example/assets.dart';
import 'package:my_fox_example/scenes/planetarium_scene.dart';
import 'package:my_fox_example/scenes/playground_scene.dart';
import 'package:my_fox_example/scenes/radar_scene.dart';
import 'package:my_fox_example/scenes/settings_scene.dart';
import 'package:filament_scene/filament_scene.dart';

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): remove! Shapes will become components on scene entities, and this will go to init
List<Shape> poGetScenesShapes() {

  List<Shape> itemsToReturn = [];

  itemsToReturn.addAll(PlaygroundSceneView.getSceneShapes());
  itemsToReturn.addAll(RadarSceneView.getSceneShapes());
  itemsToReturn.addAll(SettingsSceneView.getSceneShapes());
  try {
    itemsToReturn.addAll(PlanetariumSceneView.getSceneShapes());
  } catch (e, st) {
    // TODO(kerberjg): remove this try/catch
    print("PlanetariumSceneView.getSceneShapes() failed: $e\n$st");
  }

  // TODO: add other scenes if needed

  return itemsToReturn;
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): refactor as an Entity
class MovingDemoLight {
  EntityGUID id;
  Vector3 origin;
  Vector3 direction;

  String phase = "moving"; // 'toCenter' or 'toOpposite'
  double startX = 0, startZ = 0;
  double oppositeX = 0, oppositeZ = 0;
  double t = 0;

  MovingDemoLight(this.id, this.origin,this.direction) {
    startX = origin.x;
    startZ = origin.z;

    // Compute opposite positions using the formula
    oppositeX = -startX;
    oppositeZ = -startZ;
  }

  @override
  String toString() {
    return 'Light(id: $id, origin: $origin, direction: $direction)';
  }
}
List<MovingDemoLight> lightsWeCanChangeParamsOn = [];

// NOTE: this is a good example of how to keep track of entities (as 'consts') so they can be referenced later
final EntityGUID centerPointLightGUID = generateGuid();

// TODO(kerberjg): this should be initialized as components on scene entities
List<Light> poGetSceneLightsList() {
  List<Light> itemsToReturn = [];

  itemsToReturn.add(poGetDefaultPointLight(Colors.white, 10000000));

  double yDirection = -1;
  double fallOffRadius = 10;
  double spotLightConeInnter = 0.1;
  double spotLightConeOuter = 0.3;
  //LightType lType = LightType.spot;
  LightType lType = LightType.point;

  EntityGUID id = generateGuid();

  lightsWeCanChangeParamsOn
      .add(MovingDemoLight(id, Position(-15.0, 5.0, -15.0), Direction(0.0, yDirection, 0.0)));

  itemsToReturn.add(Light(
      id: id,
      type: lType,
      colorTemperature: 36500,
      color: Colors.red,
      intensity: 100000000,
      castShadows: true,
      castLight: true,
      spotLightConeInner: spotLightConeInnter,
      spotLightConeOuter: spotLightConeOuter,
      falloffRadius: fallOffRadius,
      position: Vector3(-15, 5, -15),
      // should be a unit vector
      direction: Vector3(0, yDirection, 0)));

  id = generateGuid();

  lightsWeCanChangeParamsOn
      .add(MovingDemoLight(id, Position(15.0, 5.0, 15.0), Direction(0.0, yDirection, 0.0)));

  itemsToReturn.add(Light(
      id: id,
      type: lType,
      colorTemperature: 36500,
      color: Colors.blue,
      intensity: 100000000,
      castShadows: true,
      castLight: true,
      spotLightConeInner: spotLightConeInnter,
      spotLightConeOuter: spotLightConeOuter,
      falloffRadius: fallOffRadius,
      position: Vector3(15, 5, 15),
      // should be a unit vector
      direction: Vector3(0, yDirection, 0)));

  id = generateGuid();

  lightsWeCanChangeParamsOn
      .add(MovingDemoLight(id, Position(-15.0, 5.0, 15.0), Direction(0.0, yDirection, 0.0)));

  itemsToReturn.add(Light(
      id: id,
      type: lType,
      colorTemperature: 36500,
      color: Colors.green,
      intensity: 100000000,
      castShadows: true,
      castLight: true,
      spotLightConeInner: spotLightConeInnter,
      spotLightConeOuter: spotLightConeOuter,
      falloffRadius: fallOffRadius,
      position: Vector3(-15, 5, 15),
      // should be a unit vector
      direction: Vector3(0, yDirection, 0)));

  id = generateGuid();

  lightsWeCanChangeParamsOn
      .add(MovingDemoLight(id, Position(15.0, 5.0, -15.0), Direction(0.0, yDirection, 0.0)));

  itemsToReturn.add(Light(
      id: id,
      type: lType,
      colorTemperature: 36500,
      color: Colors.orange,
      intensity: 100000000,
      castShadows: true,
      castLight: true,
      spotLightConeInner: spotLightConeInnter,
      spotLightConeOuter: spotLightConeOuter,
      falloffRadius: fallOffRadius,
      position: Vector3(15, 5, -15),
      // should be a unit vector
      direction: Vector3(0, yDirection, 0)));

  Vector3 taillightOffset = Vector3(
      2.5,
      1.2,
      0.85,
    );

  // settings scene
  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_BL']!,
    type: LightType.point,
    color: Colors.red,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + taillightOffset,
  ));

  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_BR']!,
    type: LightType.point,
    color: Colors.red,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + taillightOffset + Vector3(0, 0, taillightOffset.z * -2),
  ));

  Vector3 frontlightOffset = Vector3(
      -2.5,
      1,
      0.85,
    );

  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_FL']!,
    type: LightType.point,
    color: Colors.yellow,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + frontlightOffset,
  ));


  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_FR']!,
    type: LightType.point,
    color: Colors.yellow,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + frontlightOffset + Vector3(0, 0, frontlightOffset.z * -2),
  ));

  // tunrning lights
  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_tBL']!,
    type: LightType.point,
    color: Colors.orange,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + taillightOffset,
  ));

  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_tBR']!,
    type: LightType.point,
    color: Colors.orange,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + taillightOffset + Vector3(0, 0, taillightOffset.z * -2),
  ));

  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_tFL']!,
    type: LightType.point,
    color: Colors.orange,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + frontlightOffset,
  ));

  id = generateGuid();
  itemsToReturn.add(Light(
    id: SettingsSceneView.objectGuids['l_light_tFR']!,
    type: LightType.point,
    color: Colors.orange,
    intensity: 100000000 * 0.05,
    falloffRadius: 2,
    castShadows: false,
    castLight: true,
    position: SettingsSceneView.carOrigin + frontlightOffset + Vector3(0, 0, frontlightOffset.z * -2),
  ));


  return itemsToReturn;
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): these go to scene file
@Deprecated("move to scene file")
List<String> radarConePieceGUID = [];

List<Model> poGetModelList() {
  // TODO(kerberjg): remove this, use scene files
  List<Model> itemsToReturn = [];


  // 'primary objects'
  itemsToReturn.addAll(getBaseModels());


  // scene 0
  itemsToReturn.addAll(PlaygroundSceneView.getSceneModels());

  // scene 1
  itemsToReturn.addAll(RadarSceneView.getSceneModels());

  // scene 2
  itemsToReturn.addAll(SettingsSceneView.getSceneModels());


  return itemsToReturn;
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): refactor as `DefaultIndirectLight.default`
DefaultIndirectLight poGetDefaultIndirectLight() {
  return DefaultIndirectLight(
      intensity: 1000000, // indirect light intensity.
      radianceBands: 1, // Number of spherical harmonics bands.
      radianceSh: [
        1,
        1,
        1
      ], // Array containing the spherical harmonics coefficients.
      irradianceBands: 1, // Number of spherical harmonics bands.
      irradianceSh: [
        1,
        1,
        1
      ] // Array containing the spherical harmonics coefficients.
      );
}

// Note point lights seem to only value intensity at a high
// range 30000000, for a 3 meter diameter of a circle, not caring about
// falloffradius
//
// TODO(kerberjg): refactor as `Light.default`
Light poGetDefaultPointLight(Color directLightColor, double intensity) {
  return Light(
      id: centerPointLightGUID,
      type: LightType.point,
      // colorTemperature: 36500,
      color: directLightColor,
      intensity: intensity,
      castShadows: true,
      castLight: true,
      spotLightConeInner: 1,
      spotLightConeOuter: 10,
      falloffRadius: 300.1, // what base is this in? meters?
      position: Vector3(0, 5, 1),
      direction: Vector3(0, 1, 0));
}
