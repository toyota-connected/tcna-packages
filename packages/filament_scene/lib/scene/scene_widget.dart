import 'dart:async';
import 'dart:core';

import 'package:collection/collection.dart';
import 'package:filament_scene/filament_scene.dart' show Camera, IndirectLight, Light, Skybox;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:filament_scene/model/model.dart';
import 'package:filament_scene/scene/scene.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:filament_scene/utils/result.dart';

typedef SceneCreatedCallback = void Function( SceneController controller);
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
  Future<Result<bool>> updateFilamentScene({
    final Scene? scene,
    final List<Model>? models,
    final List<Shape>? shapes,
  }) async {

    
    final Future<bool?> data = _channel.invokeMethod<bool>(
      _updateFilamentScene,
      <String, Object?>{
        _updateFilamentSceneSceneKey: scene?.toJson(),
        _updateFilamentSceneModelKey: models?.map((final e) => e.toJson()).toList(),
        _updateFilamentSceneShapesKey: shapes?.map((final e) => e.toJson()).toList(),
      },
    );

    return handleError(data);
  }
}

const String _updateFilamentScene = "UPDATE_FILAMENT_SCENE";
const String _updateFilamentSceneSceneKey = "UPDATE_FILAMENT_SCENE_SCENE_KEY";
const String _updateFilamentSceneModelKey = "UPDATE_FILAMENT_SCENE_MODEL_KEY";
const String _updateFilamentSceneShapesKey = "UPDATE_FILAMENT_SCENE_SHAPES_KEY";


class SceneView extends StatefulWidget {
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

  /// onCreated callback provides an object of [SceneController] when the native view is created.
  /// This controller provides utility methods to update the viewer, change the animation environment, lightening, etc.
  /// The onCreated callback is called once when the native view is created and provide unique controller to each widget.
  /// See also:
  /// [SceneController]
  final SceneCreatedCallback? onCreated;

  /// Which gestures should be consumed by the view.
  ///
  /// When the view is put inside other view like [ListView],
  /// it might claim gestures that are recognized by any of the recognizers on this list.
  /// as the [ListView] will handle vertical drags gestures.
  ///
  /// To get the [SceneView] to claim the vertical drag gestures we can pass a vertical drag
  /// gesture recognizer factory in [gestureRecognizers] e.g:
  ///
  /// ```dart
  /// GestureDetector(
  ///   onVerticalDragStart: (DragStartDetails details) {},
  ///   child: SizedBox(
  ///     width: 200.0,
  ///     height: 100.0,
  ///     child: FilamentScene(
  ///       gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
  ///         Factory<OneSequenceGestureRecognizer>(
  ///           () => EagerGestureRecognizer(),
  ///         ),
  ///       },
  ///     ),
  ///   ),
  /// )
  /// ```
  ///
  /// When this set is empty, the view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  const SceneView(
      {super.key,
      this.models,
      this.scene,
      this.shapes,
      this.onCreated,
      this.gestureRecognizers =
          const <Factory<OneSequenceGestureRecognizer>>{},});

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
      ..add(ObjectFlagProperty<SceneCreatedCallback?>.has('onCreated', onCreated))
      ..add(IterableProperty<Factory<OneSequenceGestureRecognizer>>('gestureRecognizers', gestureRecognizers));
  }
}

class ModelViewerState extends State<SceneView> {
  final Map<String, dynamic> _creationParams = <String, dynamic>{};
  final Completer<SceneController> _controller =
      Completer<SceneController>();

  ModelViewerState();

  @override
  void initState() {
    _setupCreationParams();
    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return AndroidView(
        viewType: _viewType,
        creationParams: _creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
      );
    }
    return Text('$defaultTargetPlatform is not yet supported by the plugin');
  }

  void _setupCreationParams() {
    //final model = widget.models?.toJson();
    final Map<String, dynamic>? scene = widget.scene?.toJson();
    _creationParams["models"] =
        widget.models?.map((final param) => param.toJson()).toList();
    _creationParams["scene"] = scene;
    // _creationParams["shapes"] =
    //     widget.shapes?.map((param) => param.toJson()).toList();
    // use concatenated toFlatJson
    _creationParams["shapes"] = 
        widget.shapes?.map((final param) => param.toFlatJson()).flattenedToList;

    // pretty print json
    // JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    // final json = encoder.convert(_creationParams);
    // debugPrint(json);
  }

  void _onPlatformViewCreated(final int id) {
    final SceneController controller = SceneController(id: id);

    _controller.complete(controller);
    if (widget.onCreated != null) {
      widget.onCreated?.call(controller);
    }
  }

  @override
  void didUpdateWidget(final SceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateWidget(oldWidget);
  }

  void _updateWidget(final SceneView? oldWidget) {
    _setupCreationParams();
    if (!listEquals(oldWidget?.models, widget.models) ||
        oldWidget?.scene != widget.scene ||
        !listEquals(oldWidget?.shapes, widget.shapes)) {
      unawaited(_updateScene());
    }
  }

  Future<void> _updateScene() async {
    final SceneController controller = (await _controller.future);
    await controller.updateFilamentScene(
      models: widget.models,
      scene: widget.scene,
      shapes: widget.shapes,
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    // Update scene on hot reload for better debugging
    _updateWidget(null);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
