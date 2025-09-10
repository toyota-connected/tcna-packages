import 'package:filament_scene/ecs/entity.dart' show Entity, EntityGUID;
import 'package:filament_scene/generated/messages.g.dart';
import 'package:filament_scene/utils/serialization.dart';

/// This class represents a basic component in the ECS to be used with [Entity].
abstract class Component with Jsonable {
  /// Unique identifier for the component.
  /// Used to identify the component in the ECS.
  String get type;

  /// Reference to owning [Entity].
  late final Entity entity;

  /// Initializes the component with the given [Entity].
  void initialize(final Entity entity) {
    // ignore: unnecessary_null_comparison
    if (this.entity != null) {
      throw StateError('Component is already initialized with an Entity.');
    }
    this.entity = entity;
  }

  EntityGUID get id => entity.id;

  FilamentViewApi get engine => entity.engine!;

  @override
  JsonObject toJson() => <String, dynamic>{
    'type': type, //
  };
}
