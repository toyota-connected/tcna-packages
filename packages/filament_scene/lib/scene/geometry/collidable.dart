part of 'geometry.dart';

class Collidable {
  bool isStatic;
  // Assumed to always be true at the moment
  bool shouldMatchAttachedObject;

  // Add properties for future layer, mask, and shape types/extensions if needed

  Collidable({
    this.isStatic = true, 
    this.shouldMatchAttachedObject = true,
  });

  // Convert the object to JSON
  Map<String, dynamic> toJson() => {
        'collidable_isStatic': isStatic,
        'collidable_shouldMatchAttachedObject': shouldMatchAttachedObject,
      };

  @override
  String toString() =>
      'Collidable(collidable_isStatic: $isStatic, collidable_shouldMatchAttachedObject: $shouldMatchAttachedObject)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Collidable &&
        other.isStatic == isStatic &&
        other.shouldMatchAttachedObject == shouldMatchAttachedObject;
  }

  @override
  int get hashCode =>
      isStatic.hashCode ^ shouldMatchAttachedObject.hashCode;
}