import 'package:filament_scene/filament_scene.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create an [Entity] and register it in [scene].
Entity _createEntity(
  final Scene scene,
  final EntityGUID id, {
  final String? name,
  final EntityGUID? parentId,
}) {
  final Entity entity = Entity(id: id, name: name, parentId: parentId);
  entity.scene = scene;
  scene.entities[id] = entity;
  return entity;
}

void main() {
  late Scene scene;

  setUp(() {
    scene = Scene();
  });

  group('Entity parent getter', () {
    test('returns null when parentId is null', () {
      final Entity entity = _createEntity(scene, 2);
      expect(entity.parent, isNull);
    });

    test('returns parent entity when parentId is set via constructor', () {
      final Entity parent = _createEntity(scene, 2, name: 'parent');
      final Entity child = _createEntity(scene, 4, parentId: 2);
      expect(child.parent, equals(parent));
    });
  });

  group('set parentId', () {
    test('sets parent and updates both sides', () {
      final Entity parent = _createEntity(scene, 2, name: 'parent');
      final Entity child = _createEntity(scene, 4, name: 'child');

      child.parentId = parent.id;

      expect(child.parentId, equals(2));
      expect(child.parent, equals(parent));
      expect(parent.children, contains(child));
    });

    test('is a no-op when setting same parentId', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child = _createEntity(scene, 4);

      child.parentId = parent.id;
      child.parentId = parent.id; // again — should not duplicate

      expect(parent.children.where((final e) => e.id == child.id).length, equals(1));
    });

    test('unparents when set to null', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child = _createEntity(scene, 4);

      child.parentId = parent.id;
      expect(parent.children, contains(child));

      child.parentId = null;
      expect(child.parentId, isNull);
      expect(child.parent, isNull);
      expect(parent.children, isNot(contains(child)));
    });

    test('reparents from old parent to new parent', () {
      final Entity oldParent = _createEntity(scene, 2, name: 'old');
      final Entity newParent = _createEntity(scene, 4, name: 'new');
      final Entity child = _createEntity(scene, 6, name: 'child');

      child.parentId = oldParent.id;
      expect(oldParent.children, contains(child));

      child.parentId = newParent.id;
      expect(oldParent.children, isNot(contains(child)));
      expect(newParent.children, contains(child));
      expect(child.parentId, equals(newParent.id));
    });
  });

  group('set parent (by reference)', () {
    test('sets parent entity by reference', () {
      final Entity parent = _createEntity(scene, 2, name: 'parent');
      final Entity child = _createEntity(scene, 4, name: 'child');

      child.parent = parent;

      expect(child.parentId, equals(parent.id));
      expect(child.parent, equals(parent));
      expect(parent.children, contains(child));
    });

    test('unparents when set to null', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child = _createEntity(scene, 4);

      child.parent = parent;
      child.parent = null;

      expect(child.parentId, isNull);
      expect(child.parent, isNull);
      expect(parent.children, isNot(contains(child)));
    });
  });

  group('addChild', () {
    test('adds child and sets parentId bidirectionally', () {
      final Entity parent = _createEntity(scene, 2, name: 'parent');
      final Entity child = _createEntity(scene, 4, name: 'child');

      parent.addChild(child);

      expect(child.parentId, equals(parent.id));
      expect(parent.children, contains(child));
    });

    test('is idempotent when child already belongs to parent', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child = _createEntity(scene, 4);

      parent.addChild(child);
      parent.addChild(child); // again

      expect(parent.children.where((final e) => e.id == child.id).length, equals(1));
    });

    test('reparents child from old parent', () {
      final Entity oldParent = _createEntity(scene, 2, name: 'old');
      final Entity newParent = _createEntity(scene, 4, name: 'new');
      final Entity child = _createEntity(scene, 6, name: 'child');

      oldParent.addChild(child);
      expect(oldParent.children, contains(child));

      newParent.addChild(child);
      expect(oldParent.children, isNot(contains(child)));
      expect(newParent.children, contains(child));
      expect(child.parentId, equals(newParent.id));
    });

    test('supports multiple children', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child1 = _createEntity(scene, 4, name: 'c1');
      final Entity child2 = _createEntity(scene, 6, name: 'c2');
      final Entity child3 = _createEntity(scene, 8, name: 'c3');

      parent.addChild(child1);
      parent.addChild(child2);
      parent.addChild(child3);

      expect(parent.children.length, equals(3));
      expect(parent.children, containsAll(<Entity>[child1, child2, child3]));
    });
  });

  group('removeChild', () {
    test('removes child and clears parentId', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child = _createEntity(scene, 4);

      parent.addChild(child);
      parent.removeChild(child);

      expect(child.parentId, isNull);
      expect(parent.children, isNot(contains(child)));
    });

    test('is a no-op for entity that is not a child', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity other = _createEntity(scene, 4);

      // should not throw or modify anything
      parent.removeChild(other);

      expect(other.parentId, isNull);
    });

    test('does not affect other children', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child1 = _createEntity(scene, 4, name: 'c1');
      final Entity child2 = _createEntity(scene, 6, name: 'c2');

      parent.addChild(child1);
      parent.addChild(child2);
      parent.removeChild(child1);

      expect(parent.children, isNot(contains(child1)));
      expect(parent.children, contains(child2));
      expect(parent.children.length, equals(1));
    });
  });

  group('getChildByName', () {
    test('returns child by name', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child = _createEntity(scene, 4, name: 'target');

      parent.addChild(child);

      expect(parent.getChildByName('target'), equals(child));
    });

    test('returns null when no match', () {
      final Entity parent = _createEntity(scene, 2);
      expect(parent.getChildByName('nonexistent'), isNull);
    });
  });

  group('hierarchy consistency', () {
    test('three-level hierarchy: grandparent -> parent -> child', () {
      final Entity grandparent = _createEntity(scene, 2, name: 'gp');
      final Entity parent = _createEntity(scene, 4, name: 'p');
      final Entity child = _createEntity(scene, 6, name: 'c');

      grandparent.addChild(parent);
      parent.addChild(child);

      expect(grandparent.children, contains(parent));
      expect(parent.children, contains(child));
      expect(child.parent, equals(parent));
      expect(parent.parent, equals(grandparent));
    });

    test('planetarium pattern: system -> orbit -> planet', () {
      // Mirrors the actual planetarium_scene.dart usage
      final Entity system = _createEntity(scene, 2, name: 'solar_system');
      final Entity earthOrbit = _createEntity(scene, 4, name: 'earth_orbit');
      final Entity earth = _createEntity(scene, 6, name: 'earth');
      final Entity moonOrbit = _createEntity(scene, 8, name: 'moon_orbit');
      final Entity moon = _createEntity(scene, 10, name: 'moon');

      system.addChild(earthOrbit);
      earthOrbit.addChild(earth);
      earthOrbit.addChild(moonOrbit);
      moonOrbit.addChild(moon);

      expect(system.children.length, equals(1));
      expect(earthOrbit.children.length, equals(2));
      expect(moonOrbit.children.length, equals(1));
      expect(moon.parent?.name, equals('moon_orbit'));
      expect(earth.parent?.name, equals('earth_orbit'));
      expect(earthOrbit.parent?.name, equals('solar_system'));
    });

    test('cross-method consistency: addChild and set parentId agree', () {
      final Entity parent = _createEntity(scene, 2);
      final Entity child1 = _createEntity(scene, 4, name: 'viaAdd');
      final Entity child2 = _createEntity(scene, 6, name: 'viaSet');

      parent.addChild(child1);
      child2.parentId = parent.id;

      expect(parent.children.length, equals(2));
      expect(child1.parentId, equals(parent.id));
      expect(child2.parentId, equals(parent.id));
    });
  });
}
