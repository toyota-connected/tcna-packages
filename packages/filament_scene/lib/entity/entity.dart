import 'package:collection/collection.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/foundation.dart';

typedef EntityGUID = int;

class Entity with Jsonable {
  final EntityGUID id;
  final String? name;

  late final Scene scene;

  FilamentViewApi? _engine;
  @protected
  FilamentViewApi? get engine => _engine;

  EntityGUID? _parentId;
  Entity? get parent => _parentId != null ? scene.getEntity(_parentId!) : null;

  final List<EntityGUID> _children = <EntityGUID>[];
  Iterable<Entity> get children => _children.map((final id) => scene.getEntity(id)!);

  /// List of children to be passed from the constructor. Only using at scene
  /// initialization.
  Iterable<Entity> tmpChildren = <Entity>[];

  Entity({
    required this.id,
    this.name,
    final EntityGUID? parentId,
    final Iterable<Entity> children = const <Entity>[],
  }) : _parentId = parentId,
       tmpChildren = children {
    // Make sure that direct children don't directly define a parentId
    assert(
      children.every((final child) => child._parentId == null),
      'Direct children should not have a parentId set. '
      'When adding children, leave the parentId null.',
    );
  }

  @mustCallSuper
  void initialize(final FilamentViewApi engine) {
    if (_engine != null) {
      throw StateError('Entity is already initialized with a FilamentViewApi engine.');
    }

    _engine = engine;
  }

  /// Gets the parent entity's GUID.
  EntityGUID? get parentId => _parentId;

  /// Sets the parent of this entity by GUID.
  ///
  /// Maintains bidirectional consistency: removes this entity from the old
  /// parent's children list and adds it to the new parent's children list.
  /// Pass `null` to unparent this entity.
  set parentId(final EntityGUID? newParentId) {
    if (newParentId == _parentId) return;

    // Remove from old parent's children list
    if (_parentId != null) {
      scene.getEntity(_parentId!)?._children.remove(id);
    }

    // Add to new parent's children list
    if (newParentId != null) {
      scene.getEntity(newParentId)?._children.add(id);
    }

    _parentId = newParentId;
  }

  /// Sets the parent of this entity by reference.
  ///
  /// Maintains bidirectional consistency: removes this entity from the old
  /// parent's children list and adds it to the new parent's children list.
  /// Pass `null` to unparent this entity.
  set parent(final Entity? newParent) {
    parentId = newParent?.id;
  }

  /// Adds a child entity to this entity.
  ///
  /// Maintains bidirectional consistency: if the child already has a parent,
  /// it is first removed from that parent's children list.
  void addChild(final Entity child) {
    if (child._parentId == id) return; // already a child

    // Remove from old parent
    if (child._parentId != null) {
      scene.getEntity(child._parentId!)?._children.remove(child.id);
    }

    child._parentId = id;
    _children.add(child.id);
  }

  /// Removes a child entity from this entity.
  ///
  /// Maintains bidirectional consistency: clears the child's parentId.
  void removeChild(final Entity child) {
    if (child._parentId != id) return; // not a child of this entity

    child._parentId = null;
    _children.remove(child.id);
  }

  /// Returns a child entity with a given [name]
  Entity? getChildByName(final String name) =>
      children.firstWhereOrNull((final child) => child.name == name);

  /*
   *  Serialization
   */
  @override
  @mustCallSuper
  JsonObject toJson() => <String, dynamic>{
    'guid': id,
    'name': name,
    'children': tmpChildren.map<JsonObject>((final child) => child.toJson()).toList(),
    'parentId': _parentId,
  };

  @nonVirtual
  /// Flattens its children tree into a single list of entities.
  List<JsonObject> toFlatJson({final bool isParent = true}) {
    final List<JsonObject> flattenedChildren = <JsonObject>[];

    for (final Entity child in tmpChildren) {
      final List<JsonObject> children = child.toFlatJson(isParent: false);
      for (final JsonObject child in children) {
        child['parentId'] ??= id; // if already set, it's a grandchild

        child.remove('children');
        flattenedChildren.add(child);
      }
    }

    final JsonObject thisJson = toJson();
    if (isParent) thisJson['children'] = null;

    final List<JsonObject> data = <JsonObject>[thisJson, ...flattenedChildren];

    return data;
  }
}

class TransformEntity extends Entity {
  /// Coordinate of center point position of the rendered model.
  final Position position;

  /// Scale Factor of the model.
  /// Should be greater than 0.
  /// Defaults to 1.
  final Scale scale;

  /// Quaternion rotation for the shape
  /// Defaults to `Quaternion.identity()` or [0, 0, 0, 1]
  final Quaternion rotation;

  TransformEntity({
    required super.id,
    super.name,
    super.parentId,
    required this.position,
    required this.scale,
    required this.rotation,
    super.children,
  }) : super();

  JsonObject toComponentJson() => <JsonKey, JsonValue>{
    'position': position.toJson(),
    'scale': scale.toJson(),
    'rotation': rotation.toJson(),
  };

  @override
  @mustCallSuper
  JsonObject toJson() => <String, dynamic>{...super.toJson(), ...toComponentJson()};

  // TODO(kerberjg): instead of explicit setters, get vector array address on init

  /// Sets the local position of this entity.
  void setLocalPosition([final Position? newPosition]) {
    if (newPosition != null) position.setFrom(newPosition);
    engine?.queueFrameTask(engine?.setEntityTransformPosition(id, position.storage64));
  }

  /// Sets the local scale of this entity.
  void setLocalScale([final Scale? newScale]) {
    if (newScale != null) scale.setFrom(newScale);
    engine?.queueFrameTask(engine?.setEntityTransformScale(id, scale.storage64));
  }

  /// Sets the local rotation of this entity.
  void setLocalRotation([final Quaternion? newRotation]) {
    if (newRotation != null) rotation.setFrom(newRotation);
    engine?.queueFrameTask(engine?.setEntityTransformRotation(id, rotation.storage64));
  }

  /// Sets the local rotation of this entity from Euler angles.
  /// The angles are in radians.
  void setLocalRotationFromEuler(final Vector3 rad) {
    rotation.setEulerRadians(rad.x, rad.y, rad.z);
    setLocalRotation();
  }

  /// Flushes the current transform state to the engine
  void updateTransform() {
    engine?.queueFrameTask(engine?.setEntityTransformPosition(id, position.storage64));
    engine?.queueFrameTask(engine?.setEntityTransformScale(id, scale.storage64));
    engine?.queueFrameTask(engine?.setEntityTransformRotation(id, rotation.storage64));
  }
}
