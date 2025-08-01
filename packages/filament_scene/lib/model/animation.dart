part of 'model.dart';

/// An object representing what animation to be played for current model.
class Animation {
  /// The Index of the Animation to be used.
  int? index;

  /// Decides whether to play the animation automatically or not.
  /// Default is true.
  bool autoPlay;

  /// If this animation loops constantly or not.
  /// Default to true;
  bool loop;

  // when animation is done if it should call to reset its pose to identity bones.
  bool resetToTPoseOnReset;

  // playback speed, defaults to 1, can speed up / slow down
  double playbackSpeed;

  // if you want to receive animation started/ended events.
  bool notifyOfAnimationEvents;

  /// creates animation object by index to be played.
  Animation.byIndex(
    this.index, {
    this.autoPlay = true,
    this.loop = true,
    this.resetToTPoseOnReset = false,
    this.playbackSpeed = 1.0,
    this.notifyOfAnimationEvents = false,
  });

  JsonObject toJson() => {
    'index': index,
    'autoPlay': autoPlay,
    'loop': loop,
    'resetToTPoseOnReset': resetToTPoseOnReset,
    'playbackSpeed': playbackSpeed,
    'notifyOfAnimationEvents': notifyOfAnimationEvents,
  };
}
