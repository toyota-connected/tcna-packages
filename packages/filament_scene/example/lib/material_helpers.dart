import 'package:filament_scene/math/vectors.dart';
import 'package:flutter/material.dart' hide Material, Texture;
import 'package:filament_scene/filament_scene.dart';
import 'dart:math';
import 'utils.dart';

const String litMat = "assets/materials/lit.filamat";
const String unlitMat = "assets/materials/unlit.filamat";
const String unlitUVMat = "assets/materials/unlitUV.filamat";
const String texturedMat = "assets/materials/textured_pbr.filamat";

////////////////////////////////////////////////////////////////////////
Material poGetLitMaterial(
  Color? colorOveride, {
  double alpha = 1.0,
  double roughness = 0.8,
  double metallic = 0.0,
  double reflectance = 0.5,
  Color emissiveColor = Colors.black,
  double emissiveIntensity = 1.0,
}) {
  return Material.asset(
    litMat,
    //usually the material file contains values for these properties,
    //but if we want to customize it we can like that.
    parameters: [
      //update base color property with color
      MaterialParameter.color(
        color: colorOveride?.withAlpha((alpha * 255).clamp(0, 255).round()) ?? Colors.white,
        name: "baseColor",
      ),
      MaterialParameter.color(
        color: emissiveColor.withAlpha((emissiveIntensity * 255).clamp(0, 255).round()),
        name: "emissive",
      ),
      //update roughness property with it's value
      MaterialParameter.float(value: roughness, name: "roughness"),
      //update metallicproperty with it's value
      MaterialParameter.float(value: metallic, name: "metallic"),
      //update reflectance property with it's value
      MaterialParameter.float(value: reflectance, name: "reflectance"),
    ],
  );
}

Material poGetUnlitMaterial(Color? color, {double alpha = 1.0}) {
  return Material.asset(
    unlitMat,
    parameters: [
      MaterialParameter.color(
        color: color?.withAlpha((alpha * 255).clamp(0, 255).round()) ?? Colors.white,
        name: "baseColor",
      ),
    ],
  );
}

Material poGetUnlitTexturedMaterial(
  String textureAssetPath, {
  Color? color,
  Vector2? uvOffset,
  Vector2? uvScale,
}) {
  return Material.asset(
    unlitUVMat,
    parameters: [
      MaterialParameter.texture(
        value: Texture.asset(
          textureAssetPath,
          type: TextureType.color,
          sampler: TextureSampler(anisotropy: 8),
        ),
        name: "baseMap",
      ),
      MaterialParameter.color(color: color ?? Colors.white, name: "baseColor"),
      if (uvOffset != null)
        MaterialParameter.floatVector(value: uvOffset.storage.toList(), name: "uvOffset"),
      if (uvScale != null)
        MaterialParameter.floatVector(value: uvScale.storage.toList(), name: "uvScale"),
    ],
  );
}

////////////////////////////////////////////////////////////////////////////////
Material poGetLitMaterialWithRandomValues() {
  Random random = Random();

  return Material.asset(
    litMat,
    //usually the material file contains values for these properties,
    //but if we want to customize it we can like that.
    parameters: [
      //update base color property with color
      MaterialParameter.color(color: getRandomPresetColor(), name: "baseColor"),
      //update roughness property with it's value
      MaterialParameter.float(value: random.nextDouble(), name: "roughness"),
      //update metallicproperty with it's value
      MaterialParameter.float(value: random.nextDouble(), name: "metallic"),
    ],
  );
}

////////////////////////////////////////////////////////////////////////////////
MaterialParameter poGetRandomColorMaterialParam() {
  return MaterialParameter.color(color: getRandomPresetColor(), name: "baseColor");
}

////////////////////////////////////////////////////////////////////////////////
Material poGetTexturedMaterial() {
  return Material.asset(
    texturedMat,
    parameters: [
      MaterialParameter.texture(
        value: Texture.asset(
          "assets/materials/texture/floor_basecolor.png",
          type: TextureType.color,
          sampler: TextureSampler(anisotropy: 8),
        ),
        name: "baseColor",
      ),
      MaterialParameter.texture(
        value: Texture.asset(
          "assets/materials/texture/floor_normal.png",
          type: TextureType.normal,
          sampler: TextureSampler(anisotropy: 8),
        ),
        name: "normal",
      ),
      MaterialParameter.texture(
        value: Texture.asset(
          "assets/materials/texture/floor_ao_roughness_metallic.png",
          type: TextureType.data,
          sampler: TextureSampler(anisotropy: 8),
        ),
        name: "aoRoughnessMetallic",
      ),
    ],
  );
}
