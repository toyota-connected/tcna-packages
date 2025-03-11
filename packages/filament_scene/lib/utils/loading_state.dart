import 'package:filament_scene/model/model.dart';
import 'package:filament_scene/scene/scene.dart';
import 'package:filament_scene/shapes/shapes.dart';

/// Represents the state of a [Model]/[Scene]/[Shape] object
enum LoadingState {
  /// Object is idle
  none("NONE"),

  /// Object is being loaded
  loading("LOADING"),

  /// Object has loaded successfully
  loaded("LOADED"),

  /// (used only for [Model])
  /// Object has failed loading, and the fallback [Model] has been successfully loaded instead
  fallbackLoaded("FALLBACK_LOADED"),

  /// (used only for [Model])
  /// Both the object and its fallback [Model] have failed to load
  error("ERROR");

  final String value;

  const LoadingState(this.value);

  static LoadingState from(final String? state) => LoadingState.values.asNameMap()[state] ?? LoadingState.none;
}
