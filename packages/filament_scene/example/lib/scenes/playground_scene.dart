
import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:flutter/material.dart' hide Animation;
import 'package:my_fox_example/assets.dart';
import 'package:my_fox_example/demo_widgets.dart';
import 'package:my_fox_example/events/collision_event_channel.dart';
import 'package:my_fox_example/events/frame_event_channel.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:my_fox_example/shape_and_object_creators.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/utils/guid.dart';


class PlaygroundSceneView extends StatefulSceneView {

  PlaygroundSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  @override
  _PlaygroundSceneViewState createState() => _PlaygroundSceneViewState();

  static Map<String, EntityGUID> objectGuids = {
    // Models
    'car': generateGuid(),
    'garage': generateGuid(),
    'fox1': generateGuid(),
    'fox2': generateGuid(),
    // Shapes

    // Lights

  };

  static List<Model> getSceneModels() {
    final List<Model> models = [];

    // TODO: use only GlbModel.asset instead of poCreateModel

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

    shapes.add(poCreateCube(
      Vector3(3, 1, 3),
      Vector3(2, 2, 2),
      Vector3(2, 2, 2),
      null,
      'cube1',
    ));

    shapes.add(poCreateCube(
      Vector3(0, 1, 3),
      Vector3(.1, 1, .1),
      Vector3(1, 1, 1), 
      null,
      'cube2',
    ));

    shapes.add(poCreateCube(
      Vector3(-3, 1, 3),
      Vector3(.5, .5, .5),
      Vector3(1, 1, 1),
      null,
      'cube3',
    ));

    shapes.add(poCreateSphere(
      Vector3(3, 1, -3),
      Vector3(1, 1, 1),
      Vector3(1, 1, 1),
      11, 5, null,
      'sphere1',
    ));

    shapes.add(poCreateSphere(
      Vector3(0, 1, -3),
      Vector3(2, 2, 2),
      Vector3(1, 1, 1),
      20, 20, null,
      'sphere2',
    ));

    shapes.add(poCreateSphere(
      Vector3(-3, 1, -3),
      Vector3(1, .5, 1),
      Vector3(1, 1, 1),
      20, 20, null,
      'sphere3',
    ));

    shapes.add(poCreatePlane(
      Vector3(-5, 1, 0),
      Vector3(1, 1, 1),
      Vector3(2, 1, 2),
      'smolPlane',
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
    widget.filament.changeCameraOrbitHomePosition(8, 3, 0);
    widget.filament.changeCameraTargetPosition(0, 0, 0);
    widget.filament.changeCameraFlightStartPosition(8, 3, 8);

    widget.filament.setFogOptions(false);
  }

  @override
  void onDestroy() {}

  @override
  void onTriggerEvent(final String eventName, [ final dynamic? eventData ]) {}

  @override
  void onUpdateFrame(FilamentViewApi filament, double dt) {
    // print("update playground");
  }
}