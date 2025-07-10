import 'package:flutter/material.dart';
import 'package:my_fox_example/scenes/planetarium_scene.dart';
import 'package:my_fox_example/scenes/playground_scene.dart';
import 'package:my_fox_example/scenes/radar_scene.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:my_fox_example/scenes/settings_scene.dart';
import 'package:filament_scene/filament_scene.dart';
import 'dart:async';
import 'dart:io';
import 'shape_and_object_creators.dart';
import 'events/animation_event_channel.dart';
import 'events/frame_event_channel.dart';
import 'events/collision_event_channel.dart';
import 'events/native_readiness.dart';
import 'package:filament_scene/generated/messages.g.dart';

// Rebuilding materials to match filament versions.
// filament_scene/example/assets/materials$
// /home/tcna/dev/workspace-automation/app/filament/cmake-build-release/staging/release/bin/matc -a vulkan -o lit.filamat raw/lit.mat
// filament_scene/example/assets/materials$
// /home/tcna/dev/workspace-automation/app/filament/cmake-build-release/staging/release/bin/matc -a vulkan -o textured_pbr.filamat raw/textured_pbr.mat

////////////////////////////////////////////////////////////////////////
void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded<Future<void>>(
    () async {
      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      stdout.write('runZonedGuarded error caught error: $error\n$stack');
    },
  );
}

////////////////////////////////////////////////////////////////////////
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

////////////////////////////////////////////////////////////////////////
class _MyAppState extends State<MyApp> {
  ////////////////////////////////////////////////////////////////////////
  // Event channels
  final AnimationEventChannel _animEventChannel = AnimationEventChannel();
  final CollisionEventChannel _collisionEventChannel = CollisionEventChannel();
  final FrameEventChannel _frameEventChannel = FrameEventChannel();

  late SceneController poController;

  final NativeReadiness _nativeReadiness = NativeReadiness();
  bool isReady = false;

  final filamentViewApi = FilamentViewApi();

  /// field to store the scene widget so it's created only once
  late final SceneView _filamentViewWidget;

  /// Scene state/overlay widget
  StatefulSceneView? _sceneView;

  @override
  void initState() {
    super.initState();

    _filamentViewWidget = poGetFilamentScene();
    _setScene(0);

    initializeReadiness();
  }

  /// Call only from setState
  void _setScene(int sceneId) {
    _sceneView = switch (sceneId) {
      0 => PlaygroundSceneView(
        filament: filamentViewApi,
        frameController: _frameEventChannel,
        collisionController: _collisionEventChannel,
        readinessController: _nativeReadiness,
      ),
      1 => RadarSceneView(
        filament: filamentViewApi,
        frameController: _frameEventChannel,
        collisionController: _collisionEventChannel,
        readinessController: _nativeReadiness,
      ),
      2 => SettingsSceneView(
        filament: filamentViewApi,
        frameController: _frameEventChannel,
        collisionController: _collisionEventChannel,
        readinessController: _nativeReadiness,
      ),
      3 => PlanetariumSceneView(
        filament: filamentViewApi,
        frameController: _frameEventChannel,
        collisionController: _collisionEventChannel,
        readinessController: _nativeReadiness,
      ),
      _ => throw UnsupportedError("nothiiiing"),
    };
  }

  Future<void> initializeReadiness() async {
    const int maxRetries = 30;
    const Duration retryInterval = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Checking native readiness, attempt $attempt...');
        final bool nativeReady = await _nativeReadiness.isNativeReady();

        if (nativeReady) {
          print('Native is ready. Proceeding...');
          startListeningForEvents();
          return;
        } else {
          print('Native is not ready. Retrying...');
        }
      } catch (e) {
        print('Error checking readiness: $e');
      }

      await Future.delayed(retryInterval);
    }

    print('Failed to confirm native readiness after $maxRetries attempts.');
  }

  ////////////////////////////////////////////////////////////////////////
  void startListeningForEvents() {
    _nativeReadiness.readinessStream.listen(
      (event) {
        if (event == "ready") {
          print('Received ready event from native side.');
          setState(() {
            print('Creating Event Channels');
            _animEventChannel.initEventChannel();
            _collisionEventChannel.initEventChannel();
            _frameEventChannel.initEventChannel();
            print('Event Channels created.');
            isReady = true;
          });
        }
      },
      onError: (error) {
        print('Error listening for readiness events: $error');
      },
    );
  }

  ////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black.withAlpha(0),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _filamentViewWidget,

            if (_sceneView != null) _sceneView!,

            // A button at the top-right to switch scenes
            Positioned(
              top: 24,
              right: 24,
              // Show menu with list of scenes with MenuAnchor and a FilledButton in builder
              child: MenuAnchor(
                builder:
                    (
                      BuildContext context,
                      MenuController controller,
                      Widget? child,
                    ) => FilledButton(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: const Text('Scenes'),
                    ),
                menuChildren: [
                  MenuItemButton(
                    child: const Text('Playground'),
                    onPressed: () => setState(() => _setScene(0)),
                  ),
                  MenuItemButton(
                    child: const Text('Radar'),
                    onPressed: () => setState(() => _setScene(1)),
                  ),
                  MenuItemButton(
                    child: const Text('Settings'),
                    onPressed: () => setState(() => _setScene(2)),
                  ),
                  MenuItemButton(
                    child: const Text('Planetarium'),
                    onPressed: () => setState(() => _setScene(3)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////////////////
  Scene poGetScene() {
    return Scene(
      skybox: ColoredSkybox(color: Colors.white),
      //skybox: HdrSkybox.asset("assets/envs/courtyard.hdr"),
      indirectLight: HdrIndirectLight.asset("assets/envs/courtyard.hdr"),
      //indirectLight: poGetDefaultIndirectLight(),
      lights: poGetSceneLightsList(),

      //       camera: Camera.inertiaAndGestures(
      //           exposure: Exposure.formAperture(
      //             aperture: 24.0,
      //             shutterSpeed: 1 / 60,
      //             sensitivity: 150,
      //           ),

      //           /*orbitHomePosition: Position(-40, 5, 0),
      //           targetPosition: Position(-50.0, 0.0, 0.0),
      //           // This is used as your extents when orbiting around an object
      //           // when the camera is set to inertiaAndGestures
      //           flightStartPosition: Position(-25.0, 15.0, 0),
      // */
      //           orbitHomePosition: Position(0, 3.0, 0),
      //           targetPosition: Position(0.0, 0.0, 0.0),
      //           // This is used as your extents when orbiting around an object
      //           // when the camera is set to inertiaAndGestures
      //           flightStartPosition: Position(8.0, 3.0, 8.0),
      //           upVector: Position(0.0, 1.0, 0.0),
      //           // how much ongoing rotation velocity effects, default 0.05
      //           inertia_rotationSpeed: 0.05,
      //           // 0-1 how much of a flick distance / delta gets multiplied, default 0.2
      //           inertia_velocityFactor: 0.2,
      //           // 0-1 larger number means it takes longer for it to decay, default 0.86
      //           inertia_decayFactor: 0.86,
      //           pan_angleCapX: 15,
      //           pan_angleCapY: 20,
      //           // how close can you zoom in.
      //           zoom_minCap: 3,
      //           // max that you're able to zoom out.
      //           zoom_maxCap: 10),
    );
  }

  ////////////////////////////////////////////////////////////////////////
  SceneView poGetFilamentScene() {
    return SceneView(
      filament: filamentViewApi,
      models: poGetModelList(),
      scene: poGetScene(),
      shapes: poGetScenesShapes(),
      cameras: poGetScenesCameras(),
      onCreated: (SceneController controller) async {
        print('poGetFilamentScene onCreated');

        poController = controller;

        _frameEventChannel.setController(filamentViewApi);
        _collisionEventChannel.setController(filamentViewApi);

        print('poGetFilamentScene onCreated completed');
      },
    );
  }
}
