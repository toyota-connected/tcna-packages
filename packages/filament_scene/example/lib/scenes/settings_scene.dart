
import 'dart:math';

import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/material.dart' hide Material;
import 'package:my_fox_example/assets.dart';
import 'package:my_fox_example/demo_widgets.dart';
import 'package:my_fox_example/events/collision_event_channel.dart';
import 'package:my_fox_example/main.dart';
import 'package:my_fox_example/material_helpers.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:my_fox_example/shape_and_object_creators.dart';
import 'package:filament_scene/filament_scene.dart';


final Random random = Random();

class SettingsSceneView extends StatefulSceneView {
  SettingsSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  });

  @override
  _SettingsSceneViewState createState() => _SettingsSceneViewState();

  static final Vector3 carOrigin = Vector3(72, 0, 68);

  static final Map<String, EntityGUID> objectGuids = {
    'car': generateGuid(),
    'floor1': generateGuid(),
    'floor2': generateGuid(),
    'floor3': generateGuid(),
    'floor4': generateGuid(),
    'floor5': generateGuid(),
    'floor6': generateGuid(),
    'floor7': generateGuid(),
    'floor8': generateGuid(),
    'floor9': generateGuid(),
    'wall1': generateGuid(),
    'wall2': generateGuid(),
    'wall3': generateGuid(),
    'wall4': generateGuid(),

    'cube': generateGuid(),

    'wiper1': generateGuid(),
    'wiper2': generateGuid(),
    's_wheel_F1': generateGuid(),
    's_wheel_F2': generateGuid(),
    's_wheel_B1': generateGuid(),
    's_wheel_B2': generateGuid(),
    'light1': generateGuid(),
    'light2': generateGuid(),
    'l_light_B1': generateGuid(),
    'l_light_B2': generateGuid(),
    'l_light_F1': generateGuid(),
    'l_light_F2': generateGuid(),
    //turning lights, front and back
    'l_light_tB1': generateGuid(),
    'l_light_tB2': generateGuid(),
    'l_light_tF1': generateGuid(),
    'l_light_tF2': generateGuid(),

    'bg_shape_0': generateGuid(),
    'bg_shape_1': generateGuid(),
  };

  static List<Model> getSceneModels() {
    final List<Model> models = [];


    models.add(GlbModel.asset(
      assetPath: sequoiaAsset,
      position: carOrigin,
      scale: Vector3.all(1),
      rotation: Quaternion(0, 0, 0, 1),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: null,
      receiveShadows: true,
      castShadows: true,
      name: sequoiaAsset,
      id: objectGuids['car']!,
      instancingMode: ModelInstancingType.instanced,
    ));

    final Vector3 lightOffset = Vector3(-2.5, 1, -0.9);

    // use 'radar_cone' asset for lights
    models.add(GlbModel.asset(
      assetPath: radarConeAsset,
      position: carOrigin + lightOffset - Vector3(0, 0, lightOffset.z * 2),
      scale: lightSize,
      rotation: Quaternion(0, 0, 0, 1),
      collidable: null,
      animation: null,
      receiveShadows: false,
      castShadows: false,
      name: radarConeAsset,
      id: objectGuids['light1']!,
      instancingMode: ModelInstancingType.instanced,
    ));


    models.add(GlbModel.asset(
      assetPath: radarConeAsset,
      // position: Vector3(lightOffset.z * 10),
      position: carOrigin + lightOffset - Vector3(0, 0, lightOffset.z * 0),
      scale: lightSize,
      rotation: Quaternion(0, 0, 0, 1),
      collidable: null,
      animation: null,
      receiveShadows: false,
      castShadows: false,
      name: radarConeAsset,
      id: objectGuids['light2']!,
      instancingMode: ModelInstancingType.instanced,
    ));

    // 16x16 floor, 3x3 tiles
    const List<Vector3Data> floorPositions = [
      Vector3Data(x: 0, y: 0, z: 0),
      Vector3Data(x: -16, y: 0, z: 16),
      Vector3Data(x: -16, y: 0, z: 0),
      Vector3Data(x: -16, y: 0, z: -16),
      Vector3Data(x: 0, y: 0, z: -16),
      Vector3Data(x: 16, y: 0, z: -16),
      Vector3Data(x: 16, y: 0, z: 0),
      Vector3Data(x: 16, y: 0, z: 16),
      Vector3Data(x: 0, y: 0, z: 16),
    ];

    for(int i = 0; i < floorPositions.length; i++) {
      final Vector3Data pos = floorPositions[i];
      models.add(GlbModel.asset(
        assetPath: checkerboardFloor,
        position: carOrigin + pos.toVector3(),
        scale: Vector3.all(1),
        rotation: Quaternion(0, 0, 0, 1),
        collidable: null,
        animation: null,
        receiveShadows: true,
        castShadows: false,
        name: "${checkerboardFloor}_${i + 1}",
        id: objectGuids['floor${i + 1}']!,
        instancingMode: ModelInstancingType.instanced,
      ));
    }

    // Bounce ball
    models.add(GlbModel.asset(
      assetPath: bounceBall,
      position: carOrigin + Vector3(12, 3, 12),
      scale: Vector3.all(0.75),
      // rotation: Quaternion.fromEulerAngles(0, 90, 0),
      rotation: Quaternion.identity()..setEulerDegrees(0, 90, 0),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: null,
      receiveShadows: true,
      castShadows: true,
      name: bounceBall,
      id: objectGuids['bg_shape_0']!,
      instancingMode: ModelInstancingType.none,
    ));
    // Donut
    models.add(GlbModel.asset(
      assetPath: donut,
      position: carOrigin + Vector3(12, 3, -12),
      scale: Vector3.all(0.005),
      rotation: Quaternion.identity()..setEulerDegrees(0, 90, 0),
      collidable: Collidable(isStatic: false, shouldMatchAttachedObject: true),
      animation: null,
      receiveShadows: true,
      castShadows: true,
      name: donut,
      id: objectGuids['bg_shape_1']!,
      instancingMode: ModelInstancingType.none,
    ));

    return models;
  }

  static final Vector3 wiperSize = Vector3(0.05, 0.75, 0.05);
  static final Vector3 lightSize = Vector3(0.2, 0.2, 0.2);

  static final Vector3 wheelOffset = Vector3(1.75, 0.425, 0.85);
  static final double wheelBackOffset = 0.4;
  static final Vector3 wheelSize = Vector3(0.5, 0.5, 0.2);
  static final int wheelSegments = 8;
  static final Map<String, Vector3> wheelPositions = {
    's_wheel_F1': carOrigin + Vector3(-wheelOffset.x,                   wheelOffset.y, wheelOffset.z),
    's_wheel_F2': carOrigin + Vector3(-wheelOffset.x,                   wheelOffset.y, -wheelOffset.z),
    's_wheel_B1': carOrigin + Vector3(wheelOffset.x - wheelBackOffset,  wheelOffset.y, wheelOffset.z),
    's_wheel_B2': carOrigin + Vector3(wheelOffset.x - wheelBackOffset,  wheelOffset.y, -wheelOffset.z),
  };

  static List<Shape> getSceneShapes() {
    final List<Shape> shapes = [];

    /// tree of nested cubes above the car
    final tree_uuids = {
      (generateGuid()): "tree_root",
      (generateGuid()): "tree_layer_1",
      (generateGuid()): "tree_layer_2",
      (generateGuid()): "tree_layer_3",
      (generateGuid()): "tree_layer_4",
    };

    print("tree_uuids: $tree_uuids");

    shapes.add(
      Cube(
        id: tree_uuids.keys.elementAt(0),
        name: tree_uuids.values.elementAt(0),
        position: carOrigin + Vector3(0, 2, 0),
        scale: Vector3(2, 0.25, 2),
        rotation: Quaternion.identity(),
        size: Vector3.all(1),
        material: poGetLitMaterial(Colors.green),
        children: [
          Cube(
            id: tree_uuids.keys.elementAt(1),
            name: tree_uuids.values.elementAt(1),
            position: Vector3(0, 2, 0), // relative to parent
            scale: Vector3(0.75, 1, 0.75),
            rotation: Quaternion.identity(),
            size: Vector3.all(1),
            material: poGetLitMaterial(Colors.green),
            children: [
              Cube(
                id: tree_uuids.keys.elementAt(2),
                name: tree_uuids.values.elementAt(2),
                position: Vector3(0, 2, 0), // relative to parent
                scale: Vector3(0.75, 1, 0.75),
                rotation: Quaternion.identity(),
                size: Vector3.all(1),
                material: poGetLitMaterial(Colors.green),
                children: [
                  Cube(
                    id: tree_uuids.keys.elementAt(3),
                    name: tree_uuids.values.elementAt(3),
                    position: Vector3(0, 2, 0), // relative to parent
                    scale: Vector3(0.75, 1, 0.75),
                    rotation: Quaternion.identity(),
                    size: Vector3.all(1),
                    material: poGetLitMaterial(Colors.green),
                    children: [
                      Cube(
                        id: tree_uuids.keys.elementAt(4),
                        name: tree_uuids.values.elementAt(4),
                        position: Vector3(0, 2, 0), // relative to parent
                        scale: Vector3(0.25, 0.25, 0.25),
                        rotation: Quaternion.identity(),
                        size: Vector3.all(1),
                        material: poGetLitMaterial(Colors.yellow),
                      ),
                    ]
                  ),
                ],
              ),
            ],
          ),
        ]
      ),
    );

    // shapes.add(poCreateCube(
    //   Vector3(72, 4, 68),
    //   Vector3(2, 2, 2),
    //   Vector3(2, 2, 2),
    //   null,
    //   objectGuids['cube']!,
    // ));

    // Wall (use cube as wall), floor is 48x48 
    // shapes.add(poCreateCube(
    //   carOrigin - Vector3(0, -8 + 0.1, 24),
    //   Vector3(48, 16, 0.1),
    //   Vector3(48, 16, 0.1),
    //   null,
    //   objectGuids['wall1']!,
    // ));
    // shapes.add(poCreateCube(
    //   carOrigin - Vector3(0, -8 + 0.1, -24),
    //   Vector3(48, 16, 0.1),
    //   Vector3(48, 16, 0.1),
    //   null,
    //   objectGuids['wall2']!,
    // ));
    // shapes.add(poCreateCube(
    //   carOrigin - Vector3(24, -8 + 0.1, 0),
    //   Vector3(0.1, 16, 48),
    //   Vector3(0.1, 16, 48),
    //   null,
    //   objectGuids['wall3']!,
    // ));
    // shapes.add(poCreateCube(
    //   carOrigin - Vector3(-24, -8 + 0.1, -0),
    //   Vector3(0.1, 16, 48),
    //   Vector3(0.1, 16, 48),
    //   null,
    //   objectGuids['wall4']!,
    // ));

    // use cube as wipers
    Vector3 wiperOffset = Vector3(-1.3, 1.45, -0.45);

    shapes.add(poCreateCube(
      Vector3(72, 0, 68) + wiperOffset,
      wiperSize,
      wiperSize,
      null,
      'wiper1',
      objectGuids['wiper1']!,
    ));

    shapes.add(poCreateCube(
      Vector3(72, 0, 68) + wiperOffset - Vector3(0, 0, wiperOffset.z * 2),
      wiperSize,
      wiperSize,
      null,
      'wiper2',
      objectGuids['wiper2']!,
    ));

    // Use spheres as wheels
    for(final entry in wheelPositions.entries) {
      shapes.add(poCreateSphere(
        entry.value,
        wheelSize,
        wheelSize,
        wheelSegments, wheelSegments,
        null,
        entry.key,
        objectGuids[entry.key]!,
      ));
    }

    return shapes;
  }

  static List<Light> getSceneLights() {
    final List<Light> lights = [];

    return lights;
  }
}

class _SettingsSceneViewState extends StatefulSceneViewState<SettingsSceneView> with SingleTickerProviderStateMixin {
  /*
   *  Game logic
   */
  @override
  void onCreate() {
    _resetCamera();

    _animationController = BottomSheet.createAnimationController(
      this,
    );

    // Set up listeners for wheel clicks
    widget.collisionController.addListener(_onObjectTouch);
    // Set tire meshes to invisible
    for(String name in SettingsSceneView.wheelPositions.keys) {
      widget.filament.turnOffVisualForEntity(SettingsSceneView.objectGuids[name]!);
    }
  }

  void _resetCamera({ bool autoOrbit = false}) {
    if(autoOrbit) {
      widget.filament.changeCameraMode("AUTO_ORBIT");
    } else {
      widget.filament.changeCameraMode("INERTIA_AND_GESTURES");
    }


    widget.filament.changeCameraOrbitHomePosition(64,3,64);
    widget.filament.changeCameraTargetPosition(72,1,68);
    widget.filament.changeCameraFlightStartPosition(64, 3, 64);

    // fog
    widget.filament.setFogOptions(true);
  }

  void _onObjectTouch(CollisionEvent event) {
    print("Scene received touch!");
    onTriggerEvent("touchObject", event);
  }

  double _timer = 0;
  final ValueNotifier<bool> _showWipers = ValueNotifier<bool>(true);
  final ValueNotifier<double> _wiperSpeed = ValueNotifier<double>(8);

  final ValueNotifier<bool> _showLights = ValueNotifier<bool>(true);
  final ValueNotifier<double> _lightLength = ValueNotifier<double>(1);
  final ValueNotifier<double> _lightWidth = ValueNotifier<double>(1);
  final ValueNotifier<double> _lightAngleX = ValueNotifier<double>(0);
  final ValueNotifier<double> _lightAngleY = ValueNotifier<double>(0);
  final ValueNotifier<double> _lightIntensity = ValueNotifier<double>(1);

  final ValueNotifier<bool> _activateTurningLights = ValueNotifier<bool>(false);

  @override
  void onUpdateFrame(FilamentViewApi filament, double dt) {
    _timer += dt;

    // Wipers
    final double wiperSpeed = _wiperSpeed.value;
    final double wiperAngle = sin(_timer * wiperSpeed) * 0.66;
    final Quaternion wiperRotation = Quaternion.identity()..setEulerRadians(wiperAngle, 0, -0.8);
    filament.changeRotationByGUID(
      SettingsSceneView.objectGuids['wiper1']!,
      wiperRotation.x,
      wiperRotation.y,
      wiperRotation.z,
      wiperRotation.w,
    );
    filament.changeRotationByGUID(
      SettingsSceneView.objectGuids['wiper2']!,
      wiperRotation.x,
      wiperRotation.y,
      wiperRotation.z,
      wiperRotation.w,
    );

    // show/hide wipers
    filament.changeScaleByGUID(
      SettingsSceneView.objectGuids['wiper1']!,
      SettingsSceneView.wiperSize.x * (_showWipers.value ? 1 : 0),
      SettingsSceneView.wiperSize.y * (_showWipers.value ? 1 : 0),
      SettingsSceneView.wiperSize.z * (_showWipers.value ? 1 : 0),
    );
    filament.changeScaleByGUID(
      SettingsSceneView.objectGuids['wiper2']!,
      SettingsSceneView.wiperSize.x * (_showWipers.value ? 1 : 0),
      SettingsSceneView.wiperSize.y * (_showWipers.value ? 1 : 0),
      SettingsSceneView.wiperSize.z * (_showWipers.value ? 1 : 0),
    );

    // Lights
    Vector3 lightScale = SettingsSceneView.lightSize.mul(Vector3(
      _lightLength.value,
      1,
      _lightWidth.value,
    )).mul(Vector3.all(
      _showLights.value ? 1 : 0,
    ));

    filament.changeScaleByGUID(
      SettingsSceneView.objectGuids['light1']!,
      lightScale.x,
      lightScale.y,
      lightScale.z,
    );
    filament.changeScaleByGUID(
      SettingsSceneView.objectGuids['light2']!,
      lightScale.x,
      lightScale.y,
      lightScale.z,
    );
    Quaternion lightRotation = Quaternion.identity()..setEulerRadians(0, _lightAngleX.value, _lightAngleY.value);
    filament.changeRotationByGUID(
      SettingsSceneView.objectGuids['light1']!,
      lightRotation.x,
      lightRotation.y,
      lightRotation.z,
      lightRotation.w,
    );
    filament.changeRotationByGUID(
      SettingsSceneView.objectGuids['light2']!,
      lightRotation.x,
      lightRotation.y,
      lightRotation.z,
      lightRotation.w,
    );

    // show/hide lights
    if(_showLights.value) {
      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_B1']!,
        Colors.red.toHex(),
        (5000000 * _lightIntensity.value).round(),
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_B2']!,
        Colors.red.toHex(),
        (5000000 * _lightIntensity.value).round(),
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_F1']!,
        Colors.yellow.toHex(),
        (5000000 * _lightIntensity.value).round()
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_F2']!,
        Colors.yellow.toHex(),
        (5000000 * _lightIntensity.value).round()
      );
    } else {
      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_B1']!,
        Colors.black.toHex(),
        0,
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_B2']!,
        Colors.black.toHex(),
        0,
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_F1']!,
        Colors.black.toHex(),
        0,
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_F2']!,
        Colors.black.toHex(),
        0,
      );
    }

    // blink turning lights
    if((_timer * 2).floor() % 2 == 1 && _activateTurningLights.value == true) {
      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tB1']!,
        Colors.orange.toHex(),
        (5000000 * _lightIntensity.value).round(),
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tB2']!,
        Colors.orange.toHex(),
        (5000000 * _lightIntensity.value).round(),
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tF1']!,
        Colors.orange.toHex(),
        (5000000 * _lightIntensity.value).round(),
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tF2']!,
        Colors.orange.toHex(),
        (5000000 * _lightIntensity.value).round(),
      );
    } else {
      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tB1']!,
        Colors.black.toHex(),
        0,
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tB2']!,
        Colors.black.toHex(),
        0,
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tF1']!,
        Colors.black.toHex(),
        0,
      );

      filament.changeLightColorByGUID(
        SettingsSceneView.objectGuids['l_light_tF2']!,
        Colors.black.toHex(),
        0,
      );
    }

    // Bounce and rotate ball
    {
      final ballGuid = SettingsSceneView.objectGuids['bg_shape_0']!;
      final double bounce = sin(_timer * 2) * 1;

      final Vector3 pos = SettingsSceneView.carOrigin + Vector3(9, 2.5 + bounce, -9);
      final Quaternion rot = Quaternion.identity()..setEulerDegrees(30, _timer * 90, 0);

      filament.changeTranslationByGUID(
        ballGuid,
        pos.x,
        pos.y,
        pos.z,
      );
      filament.changeRotationByGUID(
        SettingsSceneView.objectGuids['bg_shape_0']!,
        rot.x,
        rot.y,
        rot.z,
        rot.w,
      );
    }

    // Bounce and rotate donut
    {
      final donutGuid = SettingsSceneView.objectGuids['bg_shape_1']!;
      final double bounce = sin(_timer * 2) * 1;

      final Vector3 pos = SettingsSceneView.carOrigin + Vector3(-10, 2 + bounce, 10);
      final Quaternion rot = Quaternion.identity()..setEulerDegrees(30 * bounce, _timer * 90, 0);

      filament.changeTranslationByGUID(
        donutGuid,
        pos.x,
        pos.y,
        pos.z,
      );
      filament.changeRotationByGUID(
        donutGuid,
        rot.x,
        rot.y,
        rot.z,
        rot.w,
      );
    }
  }

  static const double _wheelCameraDistanceZ = 1;
  static const double _wheelCameraDistanceY = 0;
  static final Map<String, Vector3> _wheelCameraPositions = SettingsSceneView.wheelPositions.map((key, value) => MapEntry(
    key,
    value
      + Vector3(0, _wheelCameraDistanceY, 0)
      + (
        value.z > 0
          ? Vector3(0, 0,  _wheelCameraDistanceZ)
          : Vector3(0, 0, -_wheelCameraDistanceZ)
        )
  ));

  @override
  void onTriggerEvent(final String eventName, [ final dynamic? eventData ]) {
    if(eventName != "touchObject") return;

    final CollisionEvent event = eventData as CollisionEvent;
    final EntityGUID id = event.results[0].id;

    print('Touched object with id: ${id}');

    // If touched any of the wheels...
    if(
      id == SettingsSceneView.objectGuids['s_wheel_F1'] ||
      id == SettingsSceneView.objectGuids['s_wheel_F2'] ||
      id == SettingsSceneView.objectGuids['s_wheel_B1'] ||
      id == SettingsSceneView.objectGuids['s_wheel_B2']
    ) {
      final String name = SettingsSceneView.objectGuids.entries.firstWhere((entry) => entry.value == id).key;
      print('Touched wheel ${name}');

      // Change camera position to wheel
      _cameraFocusOnTire(name);

      // Set menu setting
      _menuSelected.value = 4;

      // Increase tire pressure
      _tirePressures[name]!.value = (_tirePressures[name]!.value + 0.025).clamp(0, 1);
    }
  }

  void _cameraFocusOnTire(String name) {
    final Vector3 cameraLookAt = SettingsSceneView.wheelPositions[name]!;
    final Vector3 cameraLookFrom = _wheelCameraPositions[name]!;


    widget.filament.changeCameraFlightStartPosition(
      cameraLookFrom.x,
      cameraLookFrom.y,
      cameraLookFrom.z,
    );

    // widget.filament.changeCameraOrbitHomePosition(
    //   cameraLookFrom.x,
    //   cameraLookFrom.y,
    //   cameraLookFrom.z,
    // );

    widget.filament.changeCameraTargetPosition(
      cameraLookAt.x,
      cameraLookAt.y,
      cameraLookAt.z,
    );


    // If last character is 1, it's left - set camera angle
    if(name.endsWith('1')) {  
      widget.filament.setCameraRotation(pi * 0.5);
    } else {
      widget.filament.setCameraRotation(pi * -0.5);
    }


    print("Set camera to tire ${name}, look from ${cameraLookFrom} at ${cameraLookAt}");


    // widget.filament.resetInertiaCameraToDefaultValues();
  }

  @override
  void onDestroy() {
    widget.collisionController.removeListener(_onObjectTouch);
  }

  /*
   *  UI
   */
  double _screenHeight = 0;
  bool _showSettings = false;
  late AnimationController _animationController;

  ValueNotifier<double> _setting1 = ValueNotifier<double>(0.5);
  ValueNotifier<double> _setting2 = ValueNotifier<double>(0.5);
  ValueNotifier<double> _setting3 = ValueNotifier<double>(0.5);

  ValueNotifier<int> _menuSelected = ValueNotifier<int>(0);

  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;

    // If settings hidden, show large invisible button to show settings
    if(!_showSettings) {
      // TODO(kerberjg): add viewport adjustment to filament view
      _resetCamera(autoOrbit: true);
    } else {
      _resetCamera(autoOrbit: false);
    }

    return Stack(
      children: [
        // GestureDetector to show/hide
        if(!_showSettings) GestureDetector(
          onTap: () {
            setState(() {
              _showSettings = !_showSettings;
              if (_showSettings) {
                _animationController.forward();
              } else {
                _animationController.reverse();
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Settings bottom sheet on the left (use AnimatedBuilder to animate)
        AnimatedPositioned(
          left: 0,
          bottom: _showSettings ? 0 : -_screenHeight,
          duration: const Duration(milliseconds: 300),
          child: _buildSettingsBottomSheet(context),
        )
      ]
    );
  }

  Widget _buildSettingsBottomSheet(BuildContext context) {
    ButtonStyle squareStyle = ButtonStyle(
      padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.all(8)),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    return Container(
        height: _screenHeight,
        width: 320,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.66),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        //
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Row 1: title, close button
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // back button (visible only when _menuSelected.value != 0)
                  ListenableBuilder(
                    listenable: _menuSelected,
                    builder: (BuildContext context, Widget? child) => Visibility(
                      visible: _menuSelected.value != 0,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          _resetCamera();
                          _menuSelected.value = 0;
                        },
                      ),
                    )
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  //spacing
                  const Spacer(),
                  // close button
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Navigator.of(context).pop();
                      setState(() {
                        _showSettings = false;
                      });
                    },
                  ),
                ],
              ),
              // Row 2: settings (3 sliders)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ListenableBuilder(
                  listenable: _menuSelected,
                  builder:(context, child) => switch(_menuSelected.value) {
                    0 => child!,
                    1 => _buildMaterialSettings(context),
                    2 => _buildLightSettings(context),
                    3 => _buildWiperSettings(context),
                    4 => _buildTireSettings(context),
                    _ => Text("Unknown menu item"),
                  },

                  // Menu selector (buttons with icon and text)
                  child: Wrap(
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      // Material settings
                      // square button, large icon and text under
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: FilledButton(
                          onPressed: () {
                            _menuSelected.value = 1;
                          },
                          // not round
                          style: squareStyle,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.color_lens, size: 48),
                              Text('Material'),
                            ],
                          ),
                        ),
                      ),
                      // Light settings
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: FilledButton(
                          onPressed: () {
                            _menuSelected.value = 2;
                          },
                          // not round
                          style: squareStyle,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.lightbulb, size: 48),
                              Text('Light'),
                            ],
                          ),
                        ),
                      ),
                      // Wiper settings
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: FilledButton(
                          onPressed: () {
                            _menuSelected.value = 3;
                          },
                          // not round
                          style: squareStyle,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.wb_sunny, size: 48),
                              Text('Wiper'),
                            ],
                          ),
                        ),
                      ),
                      // Tire settings
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: FilledButton(
                          onPressed: () {
                            _menuSelected.value = 4;
                          },
                          // not round
                          style: squareStyle,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.directions_car, size: 48),
                              Text('Tire'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                )
              ),
            ],
        ),
      );
  }

  Material _customizedMaterial = poGetLitMaterialWithRandomValues();
  MaterialParameter _paramColor = MaterialParameter.baseColor(color: Colors.white);
  MaterialParameter _paramRoughness = MaterialParameter.roughness(value: 0.8);
  MaterialParameter _paramMetalness = MaterialParameter.metallic(value: 0.0);
  HSVColor _customColor = HSVColor.fromColor(Color(0xffff00ff));

  void _onSettingChanged() {
    // Update hue
    _customColor = _customColor.withHue(_setting1.value * 360);
    _paramColor = MaterialParameter.baseColor(color: _customColor.toColor());

    // Update roughness
    _paramRoughness = MaterialParameter.roughness(value: _setting2.value);

    // Update metalness
    _paramMetalness = MaterialParameter.metallic(value: _setting3.value);

    // Set material
    _customizedMaterial = Material.asset(
      litMat,
      parameters: [
        _paramColor,
        _paramRoughness,
        _paramMetalness,
      ],
    );
    widget.filament.changeMaterialDefinition(_customizedMaterial.toJson(), SettingsSceneView.objectGuids['car']!);
  }

  Widget _buildMaterialSettings(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(height: 16),
      // Slider 1: Ambient light
      Text("Color"),
      ListenableBuilder(
        listenable: _setting1,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0,
          max: 1,
          value: _setting1.value,
          onChanged: (double value) {
            _setting1.value = value;
            _onSettingChanged();
          },
        )
      ),
      // Slider 2: Direct light
      Text("Roughness"),
      ListenableBuilder(
        listenable: _setting2,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0,
          max: 1,
          value: _setting2.value,
          onChanged: (double value) {
            _setting2.value = value;
            _onSettingChanged();
          },
        )
      ),
      // Slider 3: Indirect light
      Text("Metallic"),
      ListenableBuilder(
        listenable: _setting3,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0,
          max: 1,
          value: _setting3.value,
          onChanged: (double value) {
            _setting3.value = value;
            _onSettingChanged();
          },
        )
      ),
      // Button: Randomize
      ElevatedButton(
        onPressed: () {
          _setting1.value = random.nextDouble();
          _setting2.value = random.nextDouble();
          _setting3.value = random.nextDouble();
          _onSettingChanged();
        },
        child: const Text('Randomize'),
      ),
    ],
  );


  // Wiper settings
  Widget _buildWiperSettings(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(height: 16),
      // Switch 1: Show wipers
      Row(
        children: <Widget>[
          Text("Show wipers"),
          ListenableBuilder(
            listenable: _showWipers,
            builder: (BuildContext context, Widget? child) => Switch(
              value: _showWipers.value,
              onChanged: (bool value) {
                _showWipers.value = value;
              },
            ),
          ),
        ],
      ),
      // Slider 1: Wiper speed
      Text("Wiper speed"),
      ListenableBuilder(
        listenable: _wiperSpeed,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0,
          max: 64,
          value: _wiperSpeed.value,
          onChanged: (double value) {
            _wiperSpeed.value = value;
          },
        )
      ),
    ],
  );

  // Light settings
  Widget _buildLightSettings(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(height: 16),
      // Switch 1: Show lights
      Row(
        children: <Widget>[
          Text("Show lights"),
          ListenableBuilder(
            listenable: _showLights,
            builder: (BuildContext context, Widget? child) => Switch(
              value: _showLights.value,
              onChanged: (bool value) {
                _showLights.value = value;
              },
            ),
          ),
        ],
      ),
      // Switch 2: Activate turning lights
      Row(
        children: <Widget>[
          Text("Activate turning lights"),
          ListenableBuilder(
            listenable: _activateTurningLights,
            builder: (BuildContext context, Widget? child) => Switch(
              value: _activateTurningLights.value,
              onChanged: (bool value) {
                _activateTurningLights.value = value;
              },
            ),
          ),
        ],
      ),
      // Slider 1: Light length
      Text("Light length"),
      ListenableBuilder(
        listenable: _lightLength,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0.1,
          max: 5,
          value: _lightLength.value,
          onChanged: (double value) {
            _lightLength.value = value;
          },
        )
      ),
      // Slider 2: Light width
      Text("Light width"),
      ListenableBuilder(
        listenable: _lightWidth,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0.1,
          max: 5,
          value: _lightWidth.value,
          onChanged: (double value) {
            _lightWidth.value = value;
          },
        )
      ),
      // Slider 3: Light angle X
      Text("Light turning"),
      ListenableBuilder(
        listenable: _lightAngleX,
        builder: (BuildContext context, Widget? child) => Slider(
          min: -pi / 4,
          max:  pi / 4,
          value: _lightAngleX.value,
          onChanged: (double value) {
            _lightAngleX.value = value;
          },
        )
      ),
      // Slider 4: Light angle Y
      Text("Light height"),
      ListenableBuilder(
        listenable: _lightAngleY,
        builder: (BuildContext context, Widget? child) => Slider(
          min: -pi / 4,
          max:  pi / 4,
          value: _lightAngleY.value,
          onChanged: (double value) {
            _lightAngleY.value = value;
          },
        )
      ),
      // Slider 5: Light intensity
      Text("Light intensity"),
      ListenableBuilder(
        listenable: _lightIntensity,
        builder: (BuildContext context, Widget? child) => Slider(
          min: 0,
          max: 2,
          value: _lightIntensity.value,
          onChanged: (double value) {
            _lightIntensity.value = value;
          },
        )
      ),

    ],
  );

  final Map<String, ValueNotifier<double>> _tirePressures = {
    's_wheel_F1': ValueNotifier<double>(0.5),
    's_wheel_F2': ValueNotifier<double>(0.5),
    's_wheel_B1': ValueNotifier<double>(0.5),
    's_wheel_B2': ValueNotifier<double>(0.5),
  };

  static const Map<String, String> _tireNames = {
    's_wheel_F1': 'Front-left',
    's_wheel_F2': 'Front-right',
    's_wheel_B1': 'Back-left',
    's_wheel_B2': 'Back-right',
  };

  Widget _buildTireSettings(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SizedBox(height: 16),
      
      // All tire pressure sliders
      for(final entry in _tirePressures.entries) ...[
        Text(_tireNames[entry.key]!),
        ListenableBuilder(
          listenable: entry.value,
          builder: (BuildContext context, Widget? child) => Slider(
            min: 0,
            max: 1,
            value: entry.value.value,
            onChangeStart: (double value) {
              // focus camera on tire
              _cameraFocusOnTire(entry.key);
            },
            onChanged: (double value) {
              // set value
              entry.value.value = value;
            },
          )
        ),
      ],
    ],
  );

}