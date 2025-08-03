import 'package:flutter/material.dart' hide Material, Texture;
import 'package:filament_scene/filament_scene.dart';
import 'dart:math';
import 'utils.dart';

const String litMat = "assets/materials/lit.filamat";
const String texturedMat = "assets/materials/textured_pbr.filamat";

////////////////////////////////////////////////////////////////////////
Material poGetLitMaterial(Color? colorOveride) {
  return Material.asset(
    litMat,
    //usually the material file contains values for these properties,
    //but if we want to customize it we can like that.
    parameters: [
      //update base color property with color
      MaterialParameter.color(color: colorOveride ?? Colors.white, name: "baseColor"),
      //update roughness property with it's value
      MaterialParameter.float(value: .8, name: "roughness"),
      //update metallicproperty with it's value
      MaterialParameter.float(value: .0, name: "metallic"),
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
