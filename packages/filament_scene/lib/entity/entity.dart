
import 'package:collection/collection.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/scene/scene.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/foundation.dart';

typedef EntityGUID = int;

class Entity {
  final EntityGUID id;
  final String? name;

  late final Scene scene;

  EntityGUID? _parentId;
  Entity? get parent => scene.getEntity(_parentId!);

  Iterable<EntityGUID> _children = <EntityGUID>[];
  Iterable<Entity> get children => _children.map((final id) => scene.getEntity(id)!);
  /// List of children to be passed from the constructor. Only using at scene initialization.
  Iterable<Entity> tmpChildren = <Entity>[];

  Entity({
    required this.id,
    this.name,
    final EntityGUID? parentId,
    final Iterable<Entity> children = const <Entity>[],
  }) 
  // ;
  :
    _parentId = parentId,
    tmpChildren = children {
    // Make sure that direct children don't directly define a parentId
    assert(
      children.every((final child) => child._parentId == null),
      'Direct children should not have a parentId set. When adding children, leave the parentId null.',
    );
  }


  // TODO: set parent

  // TODO: add/remove child

  /// Returns a child entity with a given [name]
  Entity? getChildByName(final String name) => children.firstWhereOrNull((final child) => child.name == name);




  /*
   *  Serialization
   */
  @mustCallSuper
  JsonObject toJson() => <String, dynamic>{
    'guid': id,
    'name': name,
    'children': tmpChildren.map<JsonObject>((final child) => child.toJson()).toList(),
  };

  @nonVirtual
  /// Flattens its children tree into a single list of entities.
  List<JsonObject> toFlatJson({final bool isParent = true}) {
    final List<JsonObject> flattenedChildren = <JsonObject>[];

    for (final Entity child in tmpChildren) {
      final children = child.toFlatJson(isParent: false);
      for(final JsonObject child in children) {
        child['parentId'] ??= id; // if already set, it's a grandchild

        child.remove('children');
        flattenedChildren.add(child);
      }
    }

    final JsonObject thisJson = toJson();
    if(isParent) thisJson['children'] = null;

    final data = <JsonObject>[
      thisJson,
      ...flattenedChildren,
    ];

    return data;
  }

  @override @nonVirtual
  /// Returns a string representation of this object, including all of its fields (based on the [toJson] method).
  /// Overriding is not necessary, as it will call the subclass' [toJson] method to get the fields.
  String toString() {
    // ignore: no_runtimetype_tostring
    return '$runtimeType(${toJson().entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Entity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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

  @override @mustCallSuper
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'position': position.toJson(),
    'scale': scale.toJson(),
    'rotation': rotation.toJson(),
  };
}
