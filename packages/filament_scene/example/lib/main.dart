import 'package:flutter/material.dart';
import 'package:my_fox_example/demo_widgets.dart';
import 'package:my_fox_example/scenes/planetarium_scene.dart';
import 'package:my_fox_example/scenes/playground_scene.dart';
import 'package:my_fox_example/scenes/radar_scene.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:my_fox_example/scenes/settings_scene.dart';
import 'package:my_fox_example/scenes/trainset_scene.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:provider/provider.dart';
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

class FrameProfilingData {
  final double deltaTime;
  final double cpuFrameTime;
  final double gpuFrameTime;
  final double scriptFrameTime; // Time taken to run the Dart script
  final double fps;

  FrameProfilingData({
    required this.deltaTime,
    required this.cpuFrameTime,
    required this.gpuFrameTime,
    required this.scriptFrameTime,
    required this.fps,
  });
}

final ValueNotifier<FrameProfilingData> frameProfilingDataNotifier =
    ValueNotifier<FrameProfilingData>(
      FrameProfilingData(
        deltaTime: 0.0, //
        cpuFrameTime: 0.0, //
        gpuFrameTime: 0.0, //
        scriptFrameTime: 0.0, //
        fps: 0.0, //
      ),
    );

////////////////////////////////////////////////////////////////////////
void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // ignore: discarded_futures
  runZonedGuarded<Future<void>>(
    () async {
      runApp(
        MultiProvider(
          providers: [
            //
            ChangeNotifierProvider.value(value: frameProfilingDataNotifier),
          ],
          child: const MyApp(),
        ),
      );
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

    unawaited(initializeReadiness());
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
      4 => TrainsetSceneView(
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

            // A profiling overlay
            Positioned(
              top: 0,
              left: 0,
              child: FrameProfilingOverlay(data: frameProfilingDataNotifier),
            ),
            // A button at the top-right to switch scenes
            Positioned(
              top: 24,
              right: 24,
              // Show menu with list of scenes with MenuAnchor and a FilledButton in builder
              child: MenuAnchor(
                builder: (BuildContext context, MenuController controller, Widget? child) =>
                    FilledButton(
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
                  MenuItemButton(
                    child: const Text('Trainset'),
                    onPressed: () => setState(() => _setScene(4)),
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
      skybox: ColorSkybox(color: Colors.white),
      //skybox: HdrSkybox.asset("assets/envs/courtyard.hdr"),
      indirectLight: HdrIndirectLight.asset("assets/envs/courtyard.hdr"),
      //indirectLight: poGetDefaultIndirectLight(),
      lights: poGetSceneLightsList(),
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
