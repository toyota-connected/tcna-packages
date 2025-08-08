import 'dart:math' as Math;

import 'package:filament_scene/camera/camera.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:my_fox_example/assets.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/math/utils.dart';
import 'package:my_fox_example/utils.dart';

/// Trainset scene view
///
/// This scene features a train that moves along a predefined path
/// shaped as a rectangular loop with rounded corners.
/// The train consists of multiple cars that follow each other along the path.
/// UI includes 3 camera presets to view the scene from different angles.
class TrainsetSceneView extends StatefulSceneView {
  const TrainsetSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  static final Vector3 sceneOrigin = Vector3(72, 0, -68);

  static final Map<String, EntityGUID> objectGuids = {
    // Models
    'trainset_camera0': generateGuid(),
    'trainset_camera1': generateGuid(),
    'trainset_camera2': generateGuid(),
    'trainset_floor': generateGuid(),
    // trainset_traincarX generated dynamically
  };

  static const int traincarCount = 4;

  @override
  _TrainsetSceneViewState createState() => _TrainsetSceneViewState();

  static final List<Camera> cameras = [
    // camera0: located to the side of the scene, looking at the middle
    Camera(
      id: objectGuids['trainset_camera0']!,
      name: 'Camera 0',
      orbitOriginPoint: sceneOrigin + Vector3(-16, 8, 0),
      targetPoint: sceneOrigin + Vector3(0, 0, 0),
    ),
    // camera1: located above the first train car
    Camera(
      id: objectGuids['trainset_camera1']!,
      name: 'Camera 1',
      orbitOriginEntity: objectGuids['trainset_traincar0']!,
      orbitDistance: 5,
      orbitAngles: Vector2(radians(90), radians(-25)),
      dollyOffset: Vector3(0, 1, 0),
    ),
    // camera2: located in the middle, looking at the car
    Camera(
      id: objectGuids['trainset_camera2']!,
      name: 'Camera 2',
      orbitOriginPoint: sceneOrigin + Vector3(0, 1, 0),
      targetEntity: objectGuids['trainset_traincar0']!,
    ),
  ];

  static List<Camera> getSceneCameras() {
    return cameras;
  }

  static List<Model> traincars = [];

  static List<Model> getSceneModels() {
    List<Model> models = [];

    // Floor
    models.add(
      GlbModel.asset(
        id: objectGuids['trainset_floor']!,
        assetPath: checkerboardFloor,
        position: sceneOrigin, // + Vector3(-8, 0, -8),
        scale: Vector3(2, 1, 2),
        rotation: Quaternion.identity(),
        collider: null,
        animation: null,
        receiveShadows: true,
        castShadows: false,
        instancingMode: ModelInstancingType.instanced,
      ),
    );

    // Train cars
    for (int i = 0; i < traincarCount; i++) {
      final EntityGUID id = generateGuid();

      final model = GlbModel.asset(
        id: id,
        name: 'traincar$i',
        assetPath: sequoiaAsset,
        position: sceneOrigin + Vector3(-8, 0, 4 + (i * -3)),
        scale: Vector3.all(0.5),
        rotation: Quaternion.euler(radians(-90), 0, 0),
        animation: null,
        collider: null,
        receiveShadows: true,
        castShadows: true,
        instancingMode: ModelInstancingType.instanced,
      );

      traincars.add(model);
      objectGuids['trainset_traincar$i'] = id;
      models.add(model);
    }

    return models;
  }

  static List<Shape> getSceneShapes() {
    // Define and return the shapes for the trainset scene
    return [];
  }
}

class _TrainsetSceneViewState extends StatefulSceneViewState {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Expanded(),
        Expanded(
          flex: 0,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: TrainsetSceneView.cameras
                .map(
                  (cam) => ElevatedButton(
                    onPressed: () => {cam.setActive()},
                    child: Text(cam.name ?? ''),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  @override
  void onCreate() {
    TrainsetSceneView.cameras[0].setActive();

    widget.filament.setFogOptions(true);
  }

  @override
  void onDestroy() {}

  @override
  void onTriggerEvent(String eventName, [eventData]) {}

  static const double pathWidth = 18;
  static const double pathHeight = 18;
  static const double pathCornerRadius = 4;

  static const double _horizontalPathLength = pathWidth - 2 * pathCornerRadius;
  static const double _verticalPathLength = pathHeight - 2 * pathCornerRadius;
  static const double _arcPathLengthQuarter = 0.5 * Math.pi * pathCornerRadius;
  static const double _pathLength =
      (_horizontalPathLength + _verticalPathLength) * 2 + 2 * Math.pi * pathCornerRadius;

  double speed = 4;
  List<double> traincarDistanceTraveled = List.generate(
    TrainsetSceneView.traincarCount,
    (i) => _pathLength - i * _traincarPathDistanceOffset,
  );

  /// How far back each traincar is from the front one
  static const double _traincarPathDistanceOffset = 2.5;

  @override
  void onUpdateFrame(FilamentViewApi filament, double dt) {
    for (int i = 0; i < TrainsetSceneView.traincarCount; i++) {
      final Model traincar = TrainsetSceneView.traincars[i];

      double distanceTraveled = traincarDistanceTraveled[i];
      distanceTraveled += speed * dt;
      distanceTraveled = distanceTraveled % _pathLength;
      distanceTraveled += distanceTraveled < 0 ? _pathLength : 0;

      Vector3 flatPos = getPointOnPath(distanceTraveled);
      if (i == 0) {
        // print('Traincar position: ${(distanceTraveled / _pathLength * 100).toStringAsFixed(0)}%');
      }

      final Vector3 pos = Vector3(flatPos.x, 0, flatPos.y);
      traincar.setLocalPosition(pos);
      traincar.setLocalRotation(Quaternion.euler(flatPos.z, 0, 0));

      traincarDistanceTraveled[i] = distanceTraveled;
    }
  }

  /// Get the position on the path at a given distance
  /// Returns a Vector3: x,y are flat plane coordinates, z is the angle around the Y axis
  Vector3 getPointOnPath(double dist) {
    double d = dist;
    Vector3 center = TrainsetSceneView.sceneOrigin;

    // 1) Right vertical segment (going down)
    if (d < _verticalPathLength) {
      double x = center.x + pathWidth / 2;
      double z = center.z + pathHeight / 2 - pathCornerRadius - d;
      double angle = radians(-90);
      return Vector3(x, z, angle);
    }
    d -= _verticalPathLength;

    // 2) Bottom-right corner arc
    if (d < _arcPathLengthQuarter) {
      double t = d / _arcPathLengthQuarter;
      double angle = lerp(0, -Math.pi / 2, t);
      Vector2 arcCenter = Vector2(
        center.x + pathWidth / 2 - pathCornerRadius,
        center.z - pathHeight / 2 + pathCornerRadius,
      );
      double x = arcCenter.x + Math.cos(angle) * pathCornerRadius;
      double z = arcCenter.y + Math.sin(angle) * pathCornerRadius;

      // lerp between right angle and down angle
      double zAngle = lerp(radians(-90), radians(0), t);
      return Vector3(x, z, zAngle);
    }
    d -= _arcPathLengthQuarter;

    // 3) Bottom horizontal segment (going left)
    if (d < _horizontalPathLength) {
      double x = center.x + pathWidth / 2 - pathCornerRadius - d;
      double z = center.z - pathHeight / 2;
      double angle = radians(0);
      return Vector3(x, z, angle);
    }
    d -= _horizontalPathLength;

    // 4) Bottom-left corner arc
    if (d < _arcPathLengthQuarter) {
      double t = d / _arcPathLengthQuarter;
      double angle = lerp(-Math.pi / 2, -Math.pi, t);
      Vector2 arcCenter = Vector2(
        center.x - pathWidth / 2 + pathCornerRadius,
        center.z - pathHeight / 2 + pathCornerRadius,
      );
      double x = arcCenter.x + Math.cos(angle) * pathCornerRadius;
      double z = arcCenter.y + Math.sin(angle) * pathCornerRadius;

      // lerp between bottom angle and left angle
      double zAngle = lerp(radians(0), radians(90), t);
      return Vector3(x, z, zAngle);
    }
    d -= _arcPathLengthQuarter;

    // 5) Left vertical segment (going up)
    if (d < _verticalPathLength) {
      double x = center.x - pathWidth / 2;
      double z = center.z - pathHeight / 2 + pathCornerRadius + d;
      double angle = radians(90);
      return Vector3(x, z, angle);
    }
    d -= _verticalPathLength;

    // 6) Top-left corner arc
    if (d < _arcPathLengthQuarter) {
      double t = d / _arcPathLengthQuarter;
      double angle = lerp(-Math.pi, -3 * Math.pi / 2, t);
      Vector2 arcCenter = Vector2(
        center.x - pathWidth / 2 + pathCornerRadius,
        center.z + pathHeight / 2 - pathCornerRadius,
      );
      double x = arcCenter.x + Math.cos(angle) * pathCornerRadius;
      double z = arcCenter.y + Math.sin(angle) * pathCornerRadius;

      // lerp between left angle and top angle
      double zAngle = lerp(radians(90), radians(180), t);
      return Vector3(x, z, zAngle);
    }
    d -= _arcPathLengthQuarter;

    // 7) Top horizontal segment (going right)
    if (d < _horizontalPathLength) {
      double x = center.x - pathWidth / 2 + pathCornerRadius + d;
      double z = center.z + pathHeight / 2;
      double angle = radians(180);
      return Vector3(x, z, angle);
    }
    d -= _horizontalPathLength;

    // 8) Top-right corner arc
    if (d < _arcPathLengthQuarter) {
      double t = d / _arcPathLengthQuarter;
      double angle = lerp(-3 * Math.pi / 2, -2 * Math.pi, t);
      Vector2 arcCenter = Vector2(
        center.x + pathWidth / 2 - pathCornerRadius,
        center.z + pathHeight / 2 - pathCornerRadius,
      );
      double x = arcCenter.x + Math.cos(angle) * pathCornerRadius;
      double z = arcCenter.y + Math.sin(angle) * pathCornerRadius;

      // lerp between top angle and right angle
      double zAngle = lerp(radians(-180), radians(-90), t);
      return Vector3(x, z, zAngle);
    }

    // Fallback: wrap to start position
    return Vector3(
      center.x + pathWidth / 2,
      center.z + pathHeight / 2 - pathCornerRadius,
      radians(90),
    );
  }
}
