
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:my_fox_example/events/collision_event_channel.dart';
import 'package:my_fox_example/events/frame_event_channel.dart';
import 'package:my_fox_example/events/native_readiness.dart';
import 'package:filament_scene/generated/messages.g.dart';

abstract class StatefulSceneView extends StatefulWidget {
  final FilamentViewApi filament;
  final FrameEventChannel frameController;
  final CollisionEventChannel collisionController;
  final NativeReadiness readinessController;

  StatefulSceneView({
    super.key,
    required this.filament,
    required this.frameController,
    required this.collisionController,
    required this.readinessController,
  }) : super();
}

abstract class StatefulSceneViewState<T extends StatefulSceneView> extends State<T> {
  /// Called when the scene view is mounted - supercedes [State.initState]
  void onCreate();

  @override @nonVirtual
  void initState() {
    widget.frameController.addCallback(this.onUpdateFrame);
    widget.readinessController.addCallback(this.onCreate);
    super.initState();
  }

  /// Called every frame to allow the scene to update its logic
  void onUpdateFrame(FilamentViewApi filament, double dt);

  /// Called when an event by a given name is triggered
  void onTriggerEvent(String eventName, [ dynamic? eventData ]);

  /// Called when the scene is unmounted - supercedes [State.dispose]
  void onDestroy();

  @override @nonVirtual
  void dispose() {
    this.onDestroy();
    widget.frameController.removeCallback(this.onUpdateFrame);
    super.dispose();
  }
}