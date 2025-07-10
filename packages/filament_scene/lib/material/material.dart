library material;

import 'dart:ui';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/foundation.dart';

part 'texture/texture.dart';
part 'texture/texture_sampler.dart';

/// Material types base on filamant general parameters.
/// See also:
/// * https://google.github.io/filament/Materials.html
enum MaterialType {
  /// Material value presented as color.
  color("COLOR"),

  /// Single boolean or Vector of 2 to 4 booleans
  /// used for material bool type, bool2,bool3,bool4 types
  /// Material value presented as bool.
  bool("BOOL"),

  /// Material value presented as Vector of 2 to 4 booleans.
  boolVector("BOOL_VECTOR"),

  /// Material value presented as float.
  float("FLOAT"),

  /// Material value presented as Vector of 2 to 4 booleans.
  floatVector("FLOAT_VECTOR"),

  /// Material value presented as int.
  int("INT"),

  /// Material value presented as Vector of 2 to 4 booleans.
  intVector("INT_VECTOR"),

  /// Material value presented as 3x3 matrix.
  mat3("MAT3"),

  /// Material value presented as 4x4 matrix.
  mat4("MAT4"),

  /// Material value presented as texture.
  texture("TEXTURE");

  final String value;
  const MaterialType(this.value);

  static MaterialType from(final String value) => MaterialType.values.asNameMap()[value]!;
}

/// An object that defines the visual appearance of a surface.
/// Filament offers a customizable material system
/// that you can use to create both simple and complex materials.
/// Materials are defined in a .mat file that describes all the information required by a material.
/// To use the .mat file in the app, Use matc tool in filament to convert .mat files to .filmat files.
/// For more information about materials, see the filament material documentation
/// * https://google.github.io/filament/Materials.html
/// * https://google.github.io/filament/Material%20Properties.pdf
class Material {
  /// Asset path of the .filmat material file
  String? assetPath;

  /// url of the .filmat material file
  String? url;

  ///Material parameters that can be used.
  List<MaterialParameter>? parameters;

  /// Creates material object from the .filmat material file from assets
  Material.asset(this.assetPath, {this.parameters});

  /// Creates material object from the .filmat material file from url.
  Material.url(this.url, {this.parameters});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'assetPath': assetPath,
    'url': url,
    'parameters': parameters?.map((final param) => param.toJson()).toList(),
  };

  @override
  String toString() {
    return 'Material(assetPath: $assetPath, url: $url, parameters: $parameters)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Material &&
        other.assetPath == assetPath &&
        other.url == url &&
        listEquals(other.parameters, parameters);
  }

  @override
  int get hashCode => assetPath.hashCode ^ url.hashCode ^ parameters.hashCode;
}

/// An object that represents material parameters that are defined in the .mat file.
class MaterialParameter {
  /// Name of the material parameter defined in the .mat file
  String name;

  /// value of the material parameter.
  dynamic value;

  /// type of the material parameter.
  MaterialType type = MaterialType.float;

  /// create a material parameter of color type.
  MaterialParameter.color({required final Color color, required this.name}) {
    value = color.toHex();
    type = MaterialType.color;
  }

  /// create a material parameter of float type.
  MaterialParameter.float({required double this.value, required this.name}) {
    type = MaterialType.float;
  }

  /// create a material parameter of float Vector type.
  /// It takes list of max 4 double elements as parameter.
  MaterialParameter.floatVector({required List<double> this.value, required this.name}) {
    type = MaterialType.floatVector;
  }

  /// create a material parameter of bool type.
  MaterialParameter.bool({required bool this.value, required this.name}) {
    type = MaterialType.bool;
  }

  /// create a material parameter of bool vector type.
  /// It takes list of max 4 bool elements as parameter.
  MaterialParameter.boolVector({required List<bool> this.value, required this.name}) {
    type = MaterialType.boolVector;
  }

  /// create a material parameter of int type.
  MaterialParameter.int({required num this.value, required this.name}) {
    type = MaterialType.int;
  }

  /// create a material parameter of int vector type.
  /// It takes list of max 4 int elements as parameter.
  MaterialParameter.intVector({required List<num> this.value, required this.name}) {
    type = MaterialType.intVector;
  }

  /// create a material parameter of 3x3 matrix type.
  ///It takes list of 9 double elements as parameter.
  MaterialParameter.mat3({required List<double> this.value, required this.name}) {
    type = MaterialType.mat3;
  }

  /// create a material parameter of 4x4 matrix type.
  ///It takes list of 16 double elements as parameter.
  MaterialParameter.mat4({required List<double> this.value, required this.name}) {
    type = MaterialType.mat4;
  }

  /// create a material parameter of texture type.
  MaterialParameter.texture({required Texture? this.value, required this.name}) {
    type = MaterialType.texture;
  }

  /// create a material parameter of color type with baseColor parameter name.
  MaterialParameter.baseColor({required final Color color, this.name = 'baseColor'}) {
    value = color.toHex();
    type = MaterialType.color;
  }

  /// create a material parameter of float type with metallic parameter name.
  MaterialParameter.metallic({required double this.value, this.name = 'metallic'}) {
    type = MaterialType.float;
  }

  /// create a material parameter of float type with roughness parameter name.
  MaterialParameter.roughness({required double this.value, this.name = 'roughness'}) {
    type = MaterialType.float;
  }

  Map<String, dynamic> toJson() {
    dynamic valueJson;

    if (type == MaterialType.texture) {
      if (value is Texture) {
        valueJson = (value as Texture?)?.toJson();
      } else {
        throw UnsupportedError(
          "Type '${value.runtimeType} is not supported as a value for 'MaterialType.texture'",
        );
      }
    } else {
      valueJson = value;
    }

    return <String, dynamic>{'name': name, 'value': valueJson, 'type': type.value};
  }

  @override
  String toString() {
    return 'MaterialParameter(name: $name, value: $value, type: $type)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is MaterialParameter &&
        other.name == name &&
        other.value == value &&
        other.type == type;
  }

  @override
  int get hashCode => name.hashCode ^ value.hashCode ^ type.hashCode;
}
