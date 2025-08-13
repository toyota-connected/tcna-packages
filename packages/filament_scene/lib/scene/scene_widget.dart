import 'dart:async';
import 'dart:core';

import 'package:collection/collection.dart';
import 'package:filament_scene/camera/camera.dart';
import 'package:filament_scene/components/camera.dart' show CameraHead, CameraRig;
import 'package:filament_scene/engine.dart';
import 'package:filament_scene/filament_scene.dart' show IndirectLight, Light, Skybox;
import 'package:filament_scene/generated/messages.g.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:filament_scene/model/model.dart';
import 'package:filament_scene/scene/scene.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:filament_scene/utils/result.dart';

typedef SceneCreatedCallback = void Function(SceneController controller);
const String _channelName = "com.toyotaconnected.filament_view.channel";
const String _viewType = "${_channelName}_3d_scene";

/// An object which helps facilitate communication between the [SceneView] Widget
/// and android side model viewer based on Filament.
///
/// It provides utility methods to update the viewer, change the animation environment, lighting, etc.
/// Each controller is unique for each widget.
class SceneController {
  int id;
  late MethodChannel _channel;

  SceneController({required this.id}) {
    _channel = MethodChannel('${_channelName}_$id');
  }

  /// Updates the current 3d scene view with the new [scene], [models], and [shapes].
  /// Returns true if the scene was updated successfully.
  Future<void> updateFilamentScene({
    final Scene? scene,
    final List<Model>? models,
    final List<Shape>? shapes,
  }) async {
    // TODO(kerberjg): implement scene update logic
  }
}

const List<TargetPlatform> kSupportedPlatforms = <TargetPlatform>[
  TargetPlatform.android,
  TargetPlatform.linux,
];

class SceneView extends StatefulWidget {
  /// FilamentViewApi instance to be used for rendering the scene.
  final FilamentViewApi filament;

  /// Model to be rendered.
  /// provide details about the model to be rendered.
  /// like asset path, url, animation, etc.
  final List<Model>? models;

  /// Scene to be rendered.
  /// provide details about the scene to be rendered.
  /// like skybox, light, camera, etc.
  /// Default scene is a transparent [Skybox] with default [Light] and default [IndirectLight]
  /// with default [Camera]
  final Scene? scene;

  /// List of shapes to be rendered.
  /// could be plane cube or sphere.
  /// each shape will be rendered with its own position size and material.
  /// See also:
  /// [Shape]
  /// [Cube]
  /// [Sphere]
  /// [Plane]
  final List<Shape>? shapes;

  /// List of cameras to be rendered.
  /// each camera will be rendered with its own rig and head.
  /// See also:
  /// [Camera]
  /// [CameraRig]
  /// [CameraHead]
  final List<Camera>? cameras;

  /// onCreated callback provides an object of [SceneController] when the native view is created.
  /// This controller provides utility methods to update the viewer, change the animation environment, lightening, etc.
  /// The onCreated callback is called once when the native view is created and provide unique controller to each widget.
  /// See also:
  /// [SceneController]
  final SceneCreatedCallback? onCreated;

  const SceneView({
    super.key,
    required this.filament,
    this.models,
    this.scene,
    this.shapes,
    this.cameras,
    this.onCreated,
  });

  @override
  State<StatefulWidget> createState() {
    return ModelViewerState();
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Model>('models', models))
      ..add(DiagnosticsProperty<Scene?>('scene', scene))
      ..add(IterableProperty<Shape>('shapes', shapes))
      ..add(IterableProperty<Camera>('cameras', cameras))
      ..add(ObjectFlagProperty<FilamentViewApi>('filament', filament, ifNull: 'no engine'))
      ..add(ObjectFlagProperty<SceneCreatedCallback?>.has('onCreated', onCreated));
  }

  bool compare(final Object other) {
    if (other is! SceneView) {
      return false;
    }

    return // dart format off
      listEquals(other.models, models) &&
      listEquals(other.shapes, shapes) &&
      listEquals(other.cameras, cameras) &&
      other.scene == scene //
    ; // dart format on
  }
}

class ModelViewerState extends State<SceneView> {
  final Completer<SceneController> _controller = Completer<SceneController>();

  int _stateHash = 0;
  JsonObject _sceneState = <String, dynamic>{};

  int _prevStateHash = -1;
  JsonObject _prevSceneState = <String, dynamic>{};

  late Widget _nativeView;

  ModelViewerState();

  @override
  void initState() {
    super.initState();

    _sceneState = _serializeSceneState();
    _stateHash = _sceneState.hashCode;

    _nativeView = AndroidView(
      viewType: _viewType,
      creationParams: _sceneState,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
      // NOTE: [hitTestBehavior] is set to [PlatformViewHitTestBehavior.transparent] to allow
      // Flutter to handle the gestures instead of passing them to the platform view directly.
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      gestureRecognizers: const {},
    );
  }

  @override
  Widget build(final BuildContext context) {
    if (kSupportedPlatforms.contains(defaultTargetPlatform)) {
      return GestureDetector(
        onTapUp: (final details) {
          widget.filament.queueFrameTask(
            widget.filament.raycastFromTap(details.globalPosition.dx, details.globalPosition.dy),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: _nativeView, // NOTE: this might be null, be careful
      );
    }

    return Text('$defaultTargetPlatform is not yet supported by the plugin');
  }

  JsonObject _serializeSceneState() {
    final JsonObject state = <String, dynamic>{};

    //final model = widget.models?.toJson();
    final JsonObject? scene = widget.scene?.toJson();
    state["models"] = widget.models?.map((final param) => param.toJson()).toList();
    state["scene"] = scene;
    // use concatenated toFlatJson
    state["shapes"] = widget.shapes?.map((final param) => param.toFlatJson()).flattenedToList;
    state["cameras"] = widget.cameras?.map((final param) => param.toJson()).toList();

    // NOTE: use this to debug the creation params
    // pretty print json
    // JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    // final json = encoder.convert(state);
    // debugPrint(json);

    return state;
  }

  void _onPlatformViewCreated(final int id) {
    final SceneController controller = SceneController(id: id);

    _controller.complete(controller);
    if (widget.onCreated != null) {
      // Set the engine on all entities
      // TODO(kerberjg): just keep a list of entities in a single map
      widget.models?.forEach((final model) => model.initialize(widget.filament));
      widget.shapes?.forEach((final shape) => shape.initialize(widget.filament));
      widget.cameras?.forEach((final camera) => camera.initialize(widget.filament));

      // Call the onCreated callback with the controller
      widget.onCreated?.call(controller);
    }
  }

  @override
  void reassemble() {
    super.reassemble();

    print(" === HOT RELOAD === ");
  }

  @override
  void didUpdateWidget(final SceneView oldWidget) {
    print("ModelViewerState didUpdateWidget");
    super.didUpdateWidget(oldWidget);

    // Check if the scene state has changed
    if (widget.compare(oldWidget)) {
      print("Scene widget changed, updating scene state");
      unawaited(_updateSceneState());
    }
  }

  Future<void> _updateSceneState() async {
    _prevSceneState = _sceneState;
    _prevStateHash = _stateHash;

    // Serialize the new scene state
    _sceneState = _serializeSceneState();
    _stateHash = _sceneState.hashCode;

    // Diff the states
    JsonObject stateDiff = <String, dynamic>{};
    // TODO(kerberjg): calculate the diff between _prevSceneState and _sceneState

    final SceneController controller = (await _controller.future);
    await controller.updateFilamentScene(
      models: widget.models,
      scene: widget.scene,
      shapes: widget.shapes,
    );
  }

  @override
  void dispose() {
    super.dispose();

    print("ModelViewerState dispose");
  }
}
