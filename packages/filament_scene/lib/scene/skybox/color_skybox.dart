part of 'skybox.dart';

/// An object that represents skybox based that shows a color only.
class ColorSkybox extends Skybox {
  ColorSkybox({required super.color});

  @override
  SkyboxType get type => SkyboxType.color;
}
