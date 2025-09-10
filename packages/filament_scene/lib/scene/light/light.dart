import 'dart:ui';
import 'package:filament_scene/ecs/entity.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:vector_math/vector_math.dart';

/// Type of the direct that will be used in the scene.
enum LightType {
  /// Directional light that also draws a sun's disk in the sky.
  sun("SUN"),

  /// Directional light, emits light in a given direction.
  ///
  /// Directional lights have a direction, but don't have a position.
  /// All light rays are parallel and come from infinitely far away and from everywhere. Typically a directional light is used to simulate the sun.
  /// Directional lights and spot lights are able to cast shadows.
  /// To create a directional light use LightType.DIRECTIONAL or LightType.SUN, both are similar,
  /// but the later also draws a sun's disk in the sky and its reflection on glossy objects.
  directional("DIRECTIONAL"),

  /// Point light, emits light from a position, in all directions.
  ///
  /// Unlike directional lights, point lights have a position but emit light in all directions.
  /// The intensity of the light diminishes with the inverse square of the distance to the light.
  point("POINT"),

  /// Physically correct spot light.
  ///
  /// A physically correct spot light is a little difficult to use because changing the outer angle of the cone changes the illumination levels,
  /// as the same amount of light is spread over a changing volume.
  /// The coupling of illumination and the outer cone means that an artist cannot tweak the influence cone of a spot light without also changing the perceived illumination.
  /// It therefore makes sense to provide artists with a parameter to disable this coupling.
  focusedSpot("FOCUSED_SPOT"),

  /// Spot light with coupling of outer cone and illumination disabled.
  ///
  /// A spot light is defined by a position, a direction and two cones, inner and outer.
  /// These two cones are used to define the angular falloff attenuation of the spot light
  /// and are defined by the angle from the center axis to where the falloff begins
  /// (i.e. cones are defined by their half-angle).
  ///
  /// Spot lights are similar to point lights but the light they emit is limited to a cone defined by spotLightCone and the light's direction.
  /// A spot light is therefore defined by a position, a direction and inner and outer cones.
  /// The spot light's influence is limited to inside the outer cone. The inner cone defines the light's falloff attenuation.
  spot("SPOT");

  final String value;
  const LightType(this.value);

  static LightType from(final String? value) =>
      LightType.values.asNameMap()[value] ?? LightType.directional;
}

/// An object that allows you to create a light source in the scene, such as a sun or street lights.
///
/// Defaults to Directional light with  colorTemperature = 6_500.0, intensity = 100_000.0f,
/// and direction = Direction(x:0.0, y:-1.0,z: 0.0), castShadows = true, cast light=false
class Light extends Entity {
  /// Denotes the type of the light being created.
  LightType type;

  /// Sets the initial color of a light.
  ///
  /// The light color is specified in the linear sRGB color-space.
  /// The default is white.
  Color? color;

  /// instead of passing color directly, you can pass the temperature, in Kelvin.
  /// Converts a correlated color temperature to a  RGB color in sRGB space.
  /// The temperature must be expressed in Kelvin and must be in the range 1,000K to 15,000K.
  ///
  /// Only one of temperature or color should be specified.
  double? colorTemperature;

  /// Sets the initial intensity of a light.
  ///
  /// This parameter depends on the LightType.
  /// For directional lights,it specifies the illuminance in lux (or lumen/m^2).
  /// For point lights and spot lights, it specifies the luminous power in lumen.
  /// For example, the sun's illuminance is about 100,000 lux.
  double? intensity;

  ///Sets the initial position of the light in world space.
  /// note: The Light's position is ignored for directional lights (LightManager.Type.DIRECTIONAL or LightManager.Type.SUN)
  ///
  /// Default is Position(x:0.0, y:0.0,z: 0.0).
  Vector3? position;

  /// Sets the initial direction of a light in world space.
  ///
  /// The light direction is specified in world space and should be a unit vector.
  /// Point lights: The direction is ignored.
  /// Spot lights: direction must be non-zero.
  ///
  /// Default is Direction(x:0.0, y:-1.0,z: 0.0).
  Vector3? direction;

  /// Whether this light casts light (enabled by default)
  ///
  /// In some situations it can be useful to have a light in the scene
  /// that doesn't actually emit light, but does cast shadows.
  bool? castLight;

  /// Enables or disables casting shadows from this Light.
  /// (disabled by default)
  bool? castShadows;

  /// Set the falloff distance for point lights and spot lights.
  ///
  /// At the falloff distance, the light has no more effect on objects.
  /// The falloff distance essentially defines a sphere of influence around the light,
  /// and therefore has an impact on performance.
  /// Larger falloffs might reduce performance significantly,especially when many lights are used.
  /// Try to avoid having a large number of light's spheres of influence overlap.
  /// The Light's falloff is ignored for directional lights (LightType.DIRECTIONAL or LightType.SUN)
  /// falloffRadius – Falloff distance in world units. Default is 1 meter.
  double? falloffRadius;

  /// Defines a spot light's inner cone angle in radian between 0 and pi/2 outer
  ///
  /// NOTE: The spot light cone is ignored for directional and point lights.
  double? spotLightConeInner;

  /// Defines a spot light's outer cone angle in radians between inner and pi/2
  ///
  /// NOTE: The spot light cone is ignored for directional and point lights.
  double? spotLightConeOuter;

  /// Defines the angular radius of the sun, in degrees, between 0.25° and 20.0°
  /// The Sun as seen from Earth has an angular size of 0.526° to 0.545°
  /// sunAngularRadius – sun's radius in degree. Default is 0.545°.
  double? sunAngularRadius;

  /// Defines the halo radius of the sun. The radius of the halo is defined as a multiplier of the sun angular radius.
  /// sunHaloSize – radius multiplier. Default is 10.0.
  double? sunHaloSize;

  /// Defines the halo falloff of the sun. The falloff is a dimensionless number used as an exponent.
  /// haloFalloff – halo falloff. Default is 80.0.
  double? sunHaloFalloff;

  // TODO(kerberjg): specify defaults in constructor as per docs above
  Light({
    required super.id,
    this.type = LightType.directional,
    this.color,
    this.colorTemperature,
    this.intensity,
    this.position,
    this.direction,
    this.castLight,
    this.castShadows,
    this.falloffRadius,
    this.spotLightConeInner,
    this.spotLightConeOuter,
    this.sunAngularRadius,
    this.sunHaloSize,
    this.sunHaloFalloff,
  }) : assert(
         color != null || colorTemperature != null,
         "Either color or colorTemperature must be specified, not both",
       ),
       // A non-zero direction is required for spot lights
       assert(
         type != LightType.spot || direction != null,
         "Direction must be specified for spot lights",
       );

  @override
  JsonObject toJson() => <String, dynamic>{
    ...super.toJson(),
    'type': type.value,
    'color': color?.toHex(),
    'colorTemperature': colorTemperature,
    'intensity': intensity,
    'position': position?.toJson(),
    'direction': direction?.toJson(),
    'castLight': castLight,
    'castShadows': castShadows,
    'falloffRadius': falloffRadius,
    'spotLightConeInner': spotLightConeInner,
    'spotLightConeOuter': spotLightConeOuter,
    'sunAngularRadius': sunAngularRadius,
    'sunHaloSize': sunHaloSize,
    'sunHaloFalloff': sunHaloFalloff,
  };
}
