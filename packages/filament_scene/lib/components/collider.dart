import 'package:filament_scene/utils/serialization.dart';

class Collider with Jsonable {
  bool isStatic;
  // Assumed to always be true at the moment
  bool shouldMatchAttachedObject;

  // Add properties for future layer, mask, and shape types/extensions if needed

  Collider({this.isStatic = true, this.shouldMatchAttachedObject = true});

  // Convert the object to JSON
  @override
  JsonObject toJson() => <String, dynamic>{
    'collider_isStatic': isStatic,
    'collider_shouldMatchAttachedObject': shouldMatchAttachedObject,
  };
}
