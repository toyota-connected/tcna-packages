
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
      // itemsToReturn.add(poGetModel(
      // sequoiaAsset,
      // Vector3.only(x: 0, y: 0, z: 0),
      // Vector3.only(x: 1, y: 1, z: 1),
      // Vector4(x: 0, y: 0, z: 0, w: 1),
      // Collidable(isStatic: false, shouldMatchAttachedObject: true),
      // null,
      // true,
      // true,
      // generateGuid(),
      // true,
      // false));
    models.add(GlbModel.asset(
      sequoiaAsset,
      centerPosition: Vector3.only(x: 0, y: 0, z: 0),
      scale: Vector3.only(x: 1, y: 1, z: 1),
      rotation: Vector4(x: 0, y: 0, z: 0, w: 1),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: null,
      receiveShadows: true,
      castShadows: true,
      name: sequoiaAsset,
      id: objectGuids['car']!,
      keepInMemory: true,
      isInstancePrimary: false,
    ));

    // Garage
    models.add(GlbModel.asset(
      garageAsset,
      centerPosition: Vector3(0, 0, -16),
      scale: Vector3.all(1),
      rotation: Vector4(w: 1),
      castShadows: false,
      receiveShadows: true,
      id: objectGuids['garage']!,
    ));

    // Foxes
    models.add(GlbModel.asset(
      foxAsset,
      centerPosition: Vector3.only(x: 1, y: 0, z: 4),
      scale: Vector3.only(x: 0.04, y: 0.04, z: 0.04),
      rotation: Vector4(x: 0, y: 0, z: 0, w: 1),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: Animation.byIndex(0, autoPlay: true),
      receiveShadows: true,
      castShadows: true,
      id: objectGuids['fox1']!,
      keepInMemory: true,
      isInstancePrimary: false,
    ));

    models.add(GlbModel.asset(
      foxAsset,
      centerPosition: Vector3.only(x: -1, y: 0, z: 4),
      scale: Vector3.only(x: 0.04, y: 0.04, z: 0.04),
      rotation: Vector4(x: 0, y: 0, z: 0, w: 1),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: Animation.byIndex(1, autoPlay: true, notifyOfAnimationEvents: true),
      receiveShadows: true,
      castShadows: true,
      id: objectGuids['fox2']!,
      keepInMemory: true,
      isInstancePrimary: false,
    ));

    return models;
  }

  static List<Shape> getSceneShapes() {
    final List<Shape> shapes = [];

    shapes.add(poCreateCube(
      Vector3.only(x: 3, y: 1, z: 3),
      Vector3.only(x: 2, y: 2, z: 2),
      Vector3.only(x: 2, y: 2, z: 2),
      null,
    ));

    shapes.add(poCreateCube(
      Vector3.only(x: 0, y: 1, z: 3),
      Vector3.only(x: .1, y: 1, z: .1),
      Vector3.only(x: 1, y: 1, z: 1), 
      null,
    ));

    shapes.add(poCreateCube(
      Vector3.only(x: -3, y: 1, z: 3),
      Vector3.only(x: .5, y: .5, z: .5),
      Vector3.only(x: 1, y: 1, z: 1),
      null,
    ));

    shapes.add(poCreateSphere(
      Vector3.only(x: 3, y: 1, z: -3),
      Vector3.only(x: 1, y: 1, z: 1),
      Vector3.only(x: 1, y: 1, z: 1),
      11, 5, null,
    ));

    shapes.add(poCreateSphere(
      Vector3.only(x: 0, y: 1, z: -3),
      Vector3.only(x: 1, y: 1, z: 1),
      Vector3.only(x: 1, y: 1, z: 1),
      20, 20, null,
    ));

    shapes.add(poCreateSphere(
      Vector3.only(x: -3, y: 1, z: -3),
      Vector3.only(x: 1, y: .5, z: 1),
      Vector3.only(x: 1, y: 1, z: 1),
      20, 20, null,
    ));

    shapes.add(poCreatePlane(
      Vector3.only(x: -5, y: 1, z: 0),
      Vector3.only(x: 1, y: 1, z: 1),
      Vector3.only(x: 2, y: 1, z: 2),
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