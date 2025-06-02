import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/filament_scene.dart';


const String sequoiaWithWheelsAsset = "assets/models/sequoia_notes.glb";
const String sequoiaAsset = "assets/models/sequoia_ngp.glb";
const String garageAsset = "assets/models/garagescene.glb";

const String checkerboardFloor = "assets/models/cb_floor.glb";
const String bounceBall = "assets/models/bounce_ball.glb";
const String donut = "assets/models/donut.glb";

const String radarConeAsset = "assets/models/radar_cone.glb";
const String radarSegmentAsset = "assets/models/half_torus.glb";
//const String radarSegmentAsset = "assets/models/half_torus_parent_mat.glb";
//const String radarSegmentAsset = "assets/models/2-Candle.glb";
const String roadAsset = "assets/models/road_segment.glb";

// fox has animation
const String foxAsset = "assets/models/Fox.glb";
//const String dmgHelmAsset = "assets/models/DamagedHelmet.glb";

/// Returns a list of base models (instance templates) to be used in the scene(s)
List<Model> getBaseModels() {
  final List<Model> models = [];

  // Car
  models.add(GlbModel.asset(
    assetPath: sequoiaAsset,
    position: Vector3(0, 0, 0),
    scale: Vector3.all(1),
    rotation: Quaternion(0, 0, 0, 1),
    collidable: null,
    animation: null,
    receiveShadows: true,
    castShadows: true,
    name: sequoiaAsset,
    id: generateGuid(),
    instancingMode: ModelInstancingType.primaryInstanceable,
  ));

  // Fox
  models.add(GlbModel.asset(
    assetPath: foxAsset,
    position: Vector3(0, 0, 0),
    scale: Vector3.all(1),
    rotation: Quaternion(0, 0, 0, 1),
    collidable: null,
    animation: null,
    receiveShadows: true,
    castShadows: true,
    id: generateGuid(),
    instancingMode: ModelInstancingType.primaryInstanceable,
  ));

  // Radar cone
  models.add(GlbModel.asset(
    assetPath: radarConeAsset,
    position: Vector3(0, 0, 0),
    scale: Vector3.all(1),
    rotation: Quaternion(0, 0, 0, 1),
    collidable: null,
    animation: null,
    receiveShadows: false,
    castShadows: false,
    name: radarConeAsset,
    id: generateGuid(),
    instancingMode: ModelInstancingType.primaryInstanceable,
  ));

  // Radar segment
  models.add(GlbModel.asset(
    assetPath: radarSegmentAsset,
    position: Vector3(0, 0, 0),
    scale: Vector3.all(1),
    rotation: Quaternion(0, 0, 0, 1),
    collidable: null,
    animation: null,
    receiveShadows: true,
    castShadows: true,
    name: radarSegmentAsset,
    id: generateGuid(),
    instancingMode: ModelInstancingType.primaryInstanceable,
  ));

  // Floor
  models.add(GlbModel.asset(
      assetPath: checkerboardFloor,
      position: Vector3(0, -0.1, 0),
      scale: Vector3.all(1),
      rotation: Quaternion(0, 0, 0, 1),
      collidable: null,
      animation: null,
      receiveShadows: true,
      castShadows: false,
      name: checkerboardFloor,
      id: generateGuid(),
    instancingMode: ModelInstancingType.primaryInstanceable,
    ));

  return models;
}