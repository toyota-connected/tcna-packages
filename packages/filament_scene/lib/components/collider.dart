class Collider {
  bool isStatic;
  // Assumed to always be true at the moment
  bool shouldMatchAttachedObject;

  // Add properties for future layer, mask, and shape types/extensions if needed

  Collider({this.isStatic = true, this.shouldMatchAttachedObject = true});

  // Convert the object to JSON
  Map<String, dynamic> toJson() => <String, dynamic>{
    'collider_isStatic': isStatic,
    'collider_shouldMatchAttachedObject': shouldMatchAttachedObject,
  };

  @override
  String toString() =>
      'Collider(collider_isStatic: $isStatic, collider_shouldMatchAttachedObject: $shouldMatchAttachedObject)';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Collider &&
        other.isStatic == isStatic &&
        other.shouldMatchAttachedObject == shouldMatchAttachedObject;
  }

  @override
  int get hashCode => isStatic.hashCode ^ shouldMatchAttachedObject.hashCode;
}
