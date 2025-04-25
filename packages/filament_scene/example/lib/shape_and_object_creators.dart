import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:filament_scene/utils/guid.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:my_fox_example/assets.dart';
import 'package:my_fox_example/scenes/planetarium_scene.dart';
import 'package:my_fox_example/scenes/playground_scene.dart';
import 'package:my_fox_example/scenes/radar_scene.dart';
import 'package:my_fox_example/scenes/settings_scene.dart';
import 'package:filament_scene/filament_scene.dart';

import 'material_helpers.dart';


// TODO(kerberjg): redudant, remove
@Deprecated("Use GlbModel.asset instead")
GlbModel poGetModel(
    String szAsset,
    Vector3 position,
    Vector3 scale,
    Quaternion rotation,
    Collidable? collidable,
    Animation? animationInfo,
    bool bReceiveShadows,
    bool bCastShadows,
    EntityGUID? id,
    bool bKeepInMemory,
    bool bWhenInstanceableIsPrimary) {
  return GlbModel.asset(szAsset,
    keepInMemory: bKeepInMemory,
    isInstancePrimary: bWhenInstanceableIsPrimary,
    animation: animationInfo,
    collidable: collidable,
    position: position,
    scale: scale,
    rotation: rotation,
    name: szAsset,
    receiveShadows: bReceiveShadows,
    castShadows: bCastShadows,
    id: id ?? generateGuid()
  );
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): investigate and remove
@Deprecated("Will be removed")
List<EntityGUID> thingsWeCanChangeParamsOn = [];

// TODO(kerberjg): refactor as `Cube.default`
@Deprecated("Will be removed")
Shape poCreateCube(Vector3 pos, Vector3 scale, Vector3 sizeExtents, Color? colorOveride, String name, [ EntityGUID? id ]) {
  id ??= generateGuid();

  // Just to show off changing material params during runtime.
  thingsWeCanChangeParamsOn.add(id);

  return Cube(
      id: id,
      name: name,
      size: sizeExtents,
      position: pos,
      rotation: Quaternion.identity(),
      scale: scale,
      castShadows: true,
      receiveShadows: true,
      material: poGetLitMaterialWithRandomValues(),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      //material: colorOveride != null
      //    ? poGetLitMaterial(colorOveride)
      //    : poGetLitMaterialWithRandomValues(),
      );
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): refactor as `Sphere.default`
@Deprecated("Will be removed")
Shape poCreateSphere(Vector3 pos, Vector3 scale, Vector3 sizeExtents,
    int stacks, int slices, Color? colorOveride, String name, [ EntityGUID? id ]) {
  return Sphere(
    position: pos,
    rotation: Quaternion.identity(),
    material: poGetTexturedMaterial(),
    //material: poGetLitMaterial(null),
    stacks: stacks,
    collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
    slices: slices,
    cullingEnabled: false,
    castShadows: true,
    receiveShadows: true,
    scale: scale,
    size: sizeExtents,
    id: id ?? generateGuid(),
    name: name,
  );
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): refactor as `Plane.default`
@Deprecated("Will be removed")
Shape poCreatePlane(Vector3 pos, Vector3 scale, Vector3 sizeExtents, String name, [ EntityGUID? id ]) {
  return Plane(
      id: id ?? generateGuid(),
      name: name,
      doubleSided: true,
      size: sizeExtents,
      scale: scale,
      castShadows: true,
      receiveShadows: true,
      position: pos,
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),

      // facing UP
      rotation: Quaternion(0, .7071, .7071, 0),
      // identity
      // rotation: Quaterion.identity(),
      material: poGetTexturedMaterial());
  //material: poGetLitMaterialWithRandomValues());
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): investigate
List<Shape> poCreateLineGrid() {
  List<Shape> itemsToReturn = [];
  double countExtents = 6;
  for (double i = -countExtents; i <= countExtents; i += 2) {
    for (int j = 0; j < 1; j++) {
      for (double k = -countExtents; k <= countExtents; k += 2) {
        itemsToReturn.add(poCreateCube(
          Vector3(i, 0, k),
          Vector3(1, 1, 1),
          Vector3(1, 1, 1),
          null,
          'lineGrid???_subcube$k'
        ));
      }
    }
  }

  return itemsToReturn;
}

////////////////////////////////////////////////////////////////////////////////
// TODO(kerberjg): remove! Shapes will become components on scene entities, and this will go to init
@Deprecated("Will be removed")
List<Shape> poGetScenesShapes() {
  //return poCreateLineGrid();

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
@Deprecated("Will be removed")
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
@Deprecated("Will be removed")
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
    id: SettingsSceneView.objectGuids['l_light_B1']!,
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
    id: SettingsSceneView.objectGuids['l_light_B2']!,
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
    id: SettingsSceneView.objectGuids['l_light_F1']!,
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
    id: SettingsSceneView.objectGuids['l_light_F2']!,
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
    id: SettingsSceneView.objectGuids['l_light_tB1']!,
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
    id: SettingsSceneView.objectGuids['l_light_tB2']!,
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
    id: SettingsSceneView.objectGuids['l_light_tF1']!,
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
    id: SettingsSceneView.objectGuids['l_light_tF2']!,
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
@Deprecated("move to scene file")
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
