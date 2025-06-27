import 'package:filament_scene/entity/entity.dart' show EntityGUID;

/*
 *  GUID generator
 */

EntityGUID kNullGuid = -1;

int _counter = 0;
const int _preamble = 0; // even number for Dart (C++ has odd)
const int _increment = 2;

/// Generates a new GUID.
EntityGUID generateGuid() {
  final int id = ++_counter * _increment + _preamble;

  // print("[generateGuid-dart] generated ID: $id");

  return id;
}
