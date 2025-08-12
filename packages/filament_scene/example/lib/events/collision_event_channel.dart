import 'package:filament_scene/engine.dart';
import 'package:filament_scene/entity/entity.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math' as math;
import '../material_helpers.dart';
import 'package:filament_scene/generated/messages.g.dart';

@immutable
class CollisionEvent {
  final List<CollisionEventHitResult> results;
  final String source;
  final int type;

  const CollisionEvent(this.results, this.source, this.type);
  // TODO(kerberjg): make sure `results` is immutable

  // //Received event: {collision_event_hit_count: 1, collision_event_hit_result_0: {id: 73bcc636-16b2-41d0-813e-f4d95f52d67a, hitPosition: [-1.4180145263671875, 1.1819745302200317, -0.35870814323425293], name: assets/models/sequoia_ngp.glb}, collision_event_source: vOnTouch, collision_event_type: 1}
  static CollisionEvent fromJson(JsonObject json) {
    print(json);

    final int resultCount = json['collision_event_hit_count'];
    final List<CollisionEventHitResult> results = <CollisionEventHitResult>[];

    for (int i = 0; i < resultCount; i++) {
      final JsonObject hitResult = JsonObject.from(json['collision_event_hit_result_$i']);
      final EntityGUID id = hitResult['guid'];
      final List<dynamic> hitPosition = hitResult['hitPosition'];
      final String name = hitResult['name'];

      results.add(
        CollisionEventHitResult(
          id,
          Vector3(
            hitPosition[0].toDouble(), //
            hitPosition[1].toDouble(), //
            hitPosition[2].toDouble(), //
          ),
          name,
        ),
      );
    }

    return CollisionEvent(
      results, //
      json['collision_event_source'], //
      json['collision_event_type'], //
    );
  }

  @override
  String toString() {
    return 'CollisionEvent{results: $results, source: $source, type: $type}';
  }
}

@immutable
class CollisionEventHitResult {
  final EntityGUID id;
  final Vector3 hitPosition;
  final String name;

  const CollisionEventHitResult(this.id, this.hitPosition, this.name);

  @override
  String toString() {
    return 'CollisionEventHitResult{id: $id, hitPosition: $hitPosition, name: $name}';
  }
}

typedef CollisionEventHandler = void Function(CollisionEvent event);

class CollisionEventChannel {
  static const EventChannel _eventChannel = EventChannel('plugin.filament_view.collision_info');

  late FilamentViewApi filamentViewApi;

  void setController(FilamentViewApi api) {
    filamentViewApi = api;
  }

  double randomInRange(double min, double max) {
    final random = math.Random();
    return random.nextDouble() * (max - min) + min;
  }

  /// Generates a uniformly distributed random unit quaternion.
  Quaternion randomQuaternion() {
    final random = math.Random();

    // Generate three random values in [0,1).
    final double u1 = random.nextDouble();
    final double u2 = random.nextDouble();
    final double u3 = random.nextDouble();

    // Convert them to quaternion components
    final double sqrt1MinusU1 = math.sqrt(1.0 - u1);
    final double sqrtU1 = math.sqrt(u1);
    final double twoPiU2 = 2.0 * math.pi * u2;
    final double twoPiU3 = 2.0 * math.pi * u3;

    final double x = sqrt1MinusU1 * math.sin(twoPiU2);
    final double y = sqrt1MinusU1 * math.cos(twoPiU2);
    final double z = sqrtU1 * math.sin(twoPiU3);
    final double w = sqrtU1 * math.cos(twoPiU3);

    return Quaternion(x, y, z, w);
  }

  void initEventChannel() {
    try {
      // Listen for events from the native side
      _eventChannel.receiveBroadcastStream().listen(
        (event) {
          // Handle incoming event
          print('Received event: $event\n');

          //Received event: {collision_event_hit_count: 1, collision_event_hit_result_0: {guid: 1682202689430419,, hitPosition: [-1.4180145263671875, 1.1819745302200317, -0.35870814323425293], name: assets/models/sequoia_ngp.glb}, collision_event_source: vOnTouch, collision_event_type: 1}

          if (event.containsKey("collision_event_hit_result_0")) {
            JsonObject hitResult = JsonObject.from(event["collision_event_hit_result_0"]);
            EntityGUID guid = hitResult["guid"];

            // Example: Change the material of the object that was touched
            JsonObject ourJson = poGetLitMaterialWithRandomValues().toJson();
            filamentViewApi.queueFrameTask(filamentViewApi.changeMaterialDefinition(ourJson, guid));

            // Emit event
            final CollisionEvent collisionEvent = CollisionEvent.fromJson(JsonObject.from(event));
            print(collisionEvent);
            _emitEvent(collisionEvent);
          }
        },
        onError: (error) {
          // Handle specific errors
          if (error is MissingPluginException) {
            stdout.write(
              'MissingPluginException: Make sure the plugin is registered on the native side.\nDetails: $error\n',
            );
          } else {
            stdout.write('Other Error: $error\n');
          }
        },
      );
    } catch (e, stackTrace) {
      // Catch any synchronous exceptions
      if (e is MissingPluginException) {
        stdout.write(
          'Caught MissingPluginException during EventChannel initialization.\nDetails: $e\nStack Trace:\n$stackTrace\n',
        );
      } else {
        stdout.write('Unexpected Error: $e\nStack Trace:\n$stackTrace\n');
      }
    }
  }

  /*
   *  Event handling
   */

  final List<CollisionEventHandler> _listeners = <CollisionEventHandler>[];

  void _emitEvent(CollisionEvent event) {
    for (final CollisionEventHandler listener in _listeners) {
      listener(event);
    }
  }

  void addListener(CollisionEventHandler listener) {
    _listeners.add(listener);
  }

  void removeListener(CollisionEventHandler listener) {
    _listeners.remove(listener);
  }

  void clearListeners() {
    _listeners.clear();
  }
}
