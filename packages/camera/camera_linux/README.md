# Camera Linux Plugin

The Linux implementation of [`camera`][camera].

*Note*: This plugin is under development.
See [missing implementations and limitations](#missing-features-on-the-linux-platform).

## Usage

### Depend on the package

This package is not an [endorsed][endorsed-federated-plugin]
implementation of the [`camera`][camera] plugin, so in addition to depending
on [`camera`][camera] you'll need to
[add `camera_linux` to your pubspec.yaml explicitly][install].
Once you do, you can use the [`camera`][camera] APIs as you normally would.

## Missing features on the Linux platform

### Device orientation

Device orientation detection is not yet implemented.

### Pause and Resume video recording

Pausing and resuming the video recording is not yet supported.

### Exposure mode, point and offset

Support for exposure mode and offset is not yet implemented.

Exposure points are not supported yet.

### Focus mode and point

Support for focus mode and point is not yet implemented.

### Flash mode

Support for flash mode is not yet implemented.

Focus points are not yet supported.

### Streaming of frames

Support for image streaming is not yet implemented.

## Error handling

Camera errors can be listened using the platform's `onCameraError` method.

Listening to errors is important, and in certain situations,
disposing of the camera is the only way to reset the situation.

<!-- Links -->

[camera]: https://pub.dev/packages/camera
[endorsed-federated-plugin]: https://flutter.dev/to/endorsed-federated-plugin
