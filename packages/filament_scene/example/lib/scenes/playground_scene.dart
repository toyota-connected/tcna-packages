import 'package:filament_scene/camera/camera.dart';
import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:my_fox_example/assets.dart';
import 'package:my_fox_example/demo_widgets.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/material_helpers.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/math/utils.dart';


class PlaygroundSceneView extends StatefulSceneView {

  const PlaygroundSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  @override
  _PlaygroundSceneViewState createState() => _PlaygroundSceneViewState();

  static final Map<String, EntityGUID> objectGuids = {
    // Models
    'playground_camera': generateGuid(),
    'car': generateGuid(),
    'garage': generateGuid(),
    'fox1': generateGuid(),
    'fox2': generateGuid(),
    // Shapes

    // Lights
  };

  static final Camera _sceneCamera = Camera(
    id: objectGuids['playground_camera']!,
    targetPoint: Vector3(0, 0, 0),
    orbitAngles: Vector2(radians(14.85), radians(45)),
    targetDistance: 11.71,
    name: 'playgroundCamera',
  );

  static List<Camera> getSceneCameras() {
    return [ _sceneCamera ];
  }

  static List<Model> getSceneModels() {
    final List<Model> models = [];

    // Car
    models.add(GlbModel.asset(
      assetPath: sequoiaAsset,
      position: Vector3(0, 0, 0),
      scale: Vector3.all(1),
      rotation: Quaternion.identity(),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: null,
      receiveShadows: true,
      castShadows: true,
      name: sequoiaAsset,
      id: objectGuids['car']!,
      instancingMode: ModelInstancingType.instanced,
    ));

    // Garage
    models.add(GlbModel.asset(
      assetPath: garageAsset,
      position: Vector3(0, 0, -16),
      scale: Vector3.all(1),
      rotation: Quaternion.identity(),
      castShadows: false,
      receiveShadows: true,
      id: objectGuids['garage']!,
      name: "garageEnvironment"
    ));

    // Foxes
    models.add(GlbModel.asset(
      assetPath: foxAsset,
      position: Vector3(1, 0, 4),
      scale: Vector3(0.04, 0.04, 0.04),
      rotation: Quaternion.identity(),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: Animation.byIndex(0, autoPlay: true),
      receiveShadows: true,
      castShadows: true,
      id: objectGuids['fox1']!,
      instancingMode: ModelInstancingType.instanced,
    ));

    models.add(GlbModel.asset(
      assetPath: foxAsset,
      position: Vector3(-1, 0, 4),
      scale: Vector3(0.04, 0.04, 0.04),
      rotation: Quaternion.identity(),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: Animation.byIndex(1, autoPlay: true, notifyOfAnimationEvents: true),
      receiveShadows: true,
      castShadows: true,
      id: objectGuids['fox2']!,
      instancingMode: ModelInstancingType.instanced,
    ));

    return models;
  }

  static List<Shape> getSceneShapes() {
    final List<Shape> shapes = [];

    shapes.add(Cube(
      id: generateGuid(),
      position: Vector3(3, 1, 3),
      scale: Vector3(2, 2, 2),
      size: Vector3.all(1),
      rotation: Quaternion.identity(),
      name: 'cube1',
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetLitMaterialWithRandomValues(),
    ));

    shapes.add(Cube(
      id: generateGuid(),
      position: Vector3(0, 1, 3),
      scale: Vector3(.1, 1, .1),
      size: Vector3.all(1),
      rotation: Quaternion.identity(),
      name: 'cube2',
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetLitMaterialWithRandomValues(),
    ));

    shapes.add(Cube(
      id: generateGuid(),
      position: Vector3(-3, 1, 3),
      scale: Vector3.all(.5),
      size: Vector3.all(1),
      rotation: Quaternion.identity(),
      name: 'cube3',
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetLitMaterialWithRandomValues(),
    ));

    shapes.add(Sphere(
      id: generateGuid(),
      position: Vector3(3, 1, -3),
      size: Vector3.all(1),
      scale: Vector3.all(1),
      rotation: Quaternion.identity(),
      name: 'sphere1',
      stacks: 11,
      slices: 5,
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetTexturedMaterial(),
    ));

    shapes.add(Sphere(
      id: generateGuid(),
      position: Vector3(0, 1, -3),
      scale: Vector3(2, 2, 2),
      size: Vector3.all(1),
      rotation: Quaternion.identity(),
      name: 'sphere2',
      stacks: 20,
      slices: 20,
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetTexturedMaterial(),
    ));

    shapes.add(Sphere(
      id: generateGuid(),
      position: Vector3(-3, 1, -3),
      scale: Vector3(1, 0.5, 1),
      size: Vector3.all(1),
      rotation: Quaternion.identity(),
      name: 'sphere3',
      stacks: 20,
      slices: 20,
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetTexturedMaterial(),
    ));

    shapes.add(Plane(
      id: generateGuid(),
      position: Vector3(-5, 1, 0),
      size: Vector3(2, 1, 2),
      scale: Vector3.all(1),
      rotation: Quaternion(0,0,0,1)..setEulerDegrees(-90, 90, 0),
      name: 'smolPlane',
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      material: poGetTexturedMaterial(),
    ));

    return shapes;
  }
}

class _PlaygroundSceneViewState extends StatefulSceneViewState {
  @override
  Widget build(BuildContext context) {
    return Column(
      // Force left justification in the column
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // -- DIRECT LIGHT CONTROLS --
        Expanded(
          flex: 0,
          child: LightSettingsWidget(filament: widget.filament),
        ),

        const SizedBox(height: 20),

        // -- ORIGINAL BUTTONS ROW --
        ViewSettingsWidget(filament: widget.filament)
      ],
    );
  }

  @override
  void onCreate() {
    PlaygroundSceneView._sceneCamera.setActive();

    widget.filament.setFogOptions(false);
  }

  @override
  void onDestroy() {}

  @override
  void onTriggerEvent(final String eventName, [ final dynamic eventData ]) {}

  @override
  void onUpdateFrame(FilamentViewApi filament, double dt) {
    // print("update playground");
  }
}