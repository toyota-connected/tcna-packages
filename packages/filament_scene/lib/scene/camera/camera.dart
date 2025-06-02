library camera;

import 'dart:core';

import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/utils/serialization.dart';

part 'exposure.dart';
part 'projection.dart';
part 'lens_projection.dart';

///Camera Modes that operates on.
///Three modes are supported: ORBIT, MAP, and FREE_FLIGHT.
enum CameraMode {
  orbit("ORBIT"),
  map("MAP"),
  freeFlight("FREE_FLIGHT"),
  autoOrbit("AUTO_ORBIT"),
  inertiaAndGestures("INERTIA_AND_GESTURES");

  final String value;
  const CameraMode(this.value);

  static CameraMode from(final String? mode) => CameraMode.values.asNameMap()[mode] ?? CameraMode.orbit;
}

///Denotes a field-of-view direction.
enum Fov {
  /// The field-of-view angle is defined on the vertical axis.
  vertical("VERTICAL"),

  /// The field-of-view angle is defined on the horizontal axis.
  horizontal("HORIZONTAL");

  final String value;
  const Fov(this.value);

  static Fov from(final String? fov) => Fov.values.asNameMap()[fov] ?? Fov.vertical;
}



/// An object that controls camera, it describes what mode it operates on, position, exposure and more.
class Camera {
  /// An object that control camera Exposure.
  Exposure? exposure;

  ///An object that controls camera projection matrix.
  Projection? projection;

  ///An object that control camera and set it's projection matrix from the focal length.
  LensProjection? lensProjection;

  /// Sets an additional matrix that scales the projection matrix.
  ///This is useful to adjust the aspect ratio of the camera independent from its projection.
  /// Its sent as List of 2 double elements :
  ///     * xscaling  horizontal scaling to be applied after the projection matrix.
  //      * yscaling  vertical scaling to be applied after the projection matrix.
  List<double>? scaling;

  ///      Sets an additional matrix that shifts (translates) the projection matrix.
  ///     The shift parameters are specified in NDC coordinates.
  /// Its sent as List of 2 double elements :
  ///      *  xshift    horizontal shift in NDC coordinates applied after the projection
  ///      *  yshift    vertical shift in NDC coordinates applied after the projection
  List<double>? shift;

  ///Mode of the camera that operates on.
  CameraMode? _mode;

  ///The world-space position of interest, which defaults to (x:0,y:0,z:-4).
  Vector3? targetPosition;

  ///The orientation for the home position, which defaults to (x:0,y:1,z:0).
  Vector3? upVector;

  ///The scroll delta multiplier, which defaults to 0.01.
  double? zoomSpeed;
  //orbit
  ///The initial eye position in world space for ORBIT mode.
  ///This defaults to (x:0,y:0,z:1).
  Vector3? orbitHomePosition;

  ///Sets the multiplier with viewport delta for ORBIT mode.This defaults to 0.01
  ///List of 2 double :[x,y]
  List<double>? orbitSpeed;

  ///The FOV axis that's held constant when the viewport changes.
  ///This defaults to Vertical.
  Fov? fovDirection;

  ///The full FOV (not the half-angle) in the degrees.
  ///This defaults to 33.
  double? fovDegrees;

  ///The distance to the far plane, which defaults to 5000.
  double? farPlane;
  //map

  ///The ground plane size used to compute the home position for MAP mode.
  ///This defaults to 512 x 512
  List<double>? mapExtent;

  ///Constrains the zoom-in level. Defaults to 0.
  double? mapMinDistance;
  //freeflight
  ///The initial eye position in world space for FREE_FLIGHT mode.
  ///Defaults to (x:0,y:0,z:0).
  Vector3? flightStartPosition;

  ///The initial orientation in pitch and yaw for FREE_FLIGHT mode.
  ///Defaults to [0,0].
  List<double>? flightStartOrientation;

  ///The maximum camera translation speed in world units per second for FREE_FLIGHT mode.
  ///Defaults to 10.
  double? flightMaxMoveSpeed;

  ///The number of speed steps adjustable with scroll wheel for FREE_FLIGHT mode.
  /// Defaults to 80.
  num? flightSpeedSteps;

  ///Applies a deceleration to camera movement in FREE_FLIGHT mode. Defaults to 0 (no damping).
  ///Lower values give slower damping times. A good default is 15.0. Too high a value may lead to instability.
  double? flightMoveDamping;

  ///The ground plane equation used for ray casts. This is a plane equation as in Ax + By + Cz + D = 0. Defaults to (0, 0, 1, 0).
  List<double>? groundPlane;

/// Used for when the camera is in inertia & gesture mode
double? inertia_rotationSpeed;
double? inertia_velocityFactor;
double? inertia_decayFactor;
double? pan_angleCapX;
double? pan_angleCapY;
// how close can you zoom in.
double? zoom_minCap;
// max that you're able to zoom out.
double? zoom_maxCap;

  ///Creates a camera on orbit mode.
  Camera.orbit({
    this.exposure,
    this.projection,
    this.lensProjection,
    this.scaling,
    this.shift,
    this.targetPosition,
    this.upVector,
    this.zoomSpeed,
    this.groundPlane,
    this.orbitHomePosition,
    this.orbitSpeed,
    this.fovDirection,
    this.fovDegrees,
    this.farPlane,
  }) {
    _mode = CameraMode.orbit;
  }

  ///Creates a camera on map mode.
  Camera.map({
    this.exposure,
    this.projection,
    this.lensProjection,
    this.scaling,
    this.shift,
    this.targetPosition,
    this.upVector,
    this.zoomSpeed,
    this.groundPlane,
    this.mapExtent,
    this.mapMinDistance,
  }) {
    _mode = CameraMode.map;
  }

  ///Creates a camera on free flight mode.
  Camera.freeFlight({
    this.exposure,
    this.projection,
    this.lensProjection,
    this.scaling,
    this.shift,
    this.targetPosition,
    this.upVector,
    this.zoomSpeed,
    this.groundPlane,
    this.flightStartPosition,
    this.flightStartOrientation,
    this.flightMaxMoveSpeed,
    this.flightSpeedSteps,
    this.flightMoveDamping,
  }) {
    _mode = CameraMode.freeFlight;
  }

Camera.autoOrbit({
      this.exposure,
      this.projection,
      this.lensProjection,
      this.scaling,
      this.shift,
      this.targetPosition,
      this.upVector,
      this.zoomSpeed,
      this.orbitHomePosition,
      this.groundPlane,
      this.flightStartPosition,
      this.flightStartOrientation,
      this.flightMaxMoveSpeed,
      this.flightSpeedSteps,
      this.flightMoveDamping,
    }) {
      _mode = CameraMode.autoOrbit;
    }

    Camera.inertiaAndGestures({
          this.exposure,
          this.projection,
          this.lensProjection,
          this.scaling,
          this.shift,
          this.targetPosition,
          this.orbitHomePosition,
          this.upVector,
          this.zoomSpeed,
          this.groundPlane,
          this.flightStartPosition,
          this.flightStartOrientation,
          this.flightMaxMoveSpeed,
          this.flightSpeedSteps,
          this.flightMoveDamping,
          this.inertia_rotationSpeed,
          this.inertia_velocityFactor,
          this.inertia_decayFactor,
          this.pan_angleCapX,
          this.pan_angleCapY,
          this.zoom_minCap,
          this.zoom_maxCap,
        }) {
          _mode = CameraMode.inertiaAndGestures;
        }

  // TODO(kerberjg): replace with serialization lib

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "exposure": exposure?.toJson(),
      "projection": projection?.toJson(),
      "lensProjection": lensProjection?.toJson(),
      "scaling": scaling,
      "shift": shift,
      "mode": _mode?.value,
      "targetPosition": targetPosition?.toJson(),
      "upVector": upVector?.toJson(),
      "zoomSpeed": zoomSpeed,
      "orbitHomePosition": orbitHomePosition?.toJson(),
      "orbitSpeed": orbitSpeed,
      "fovDirection": fovDirection?.value,
      "fovDegrees": fovDegrees,
      "farPlane": farPlane,
      "mapExtent": mapExtent,
      "mapMinDistance": mapMinDistance,
      "flightStartPosition": flightStartPosition?.toJson(),
      "flightStartOrientation": flightStartOrientation,
      "flightMaxMoveSpeed": flightMaxMoveSpeed,
      "flightSpeedSteps": flightSpeedSteps,
      "flightMoveDamping": flightMoveDamping,
      "groundPlane": groundPlane,
      "inertia_rotationSpeed" : inertia_rotationSpeed,
      "inertia_velocityFactor" : inertia_velocityFactor,
      "inertia_decayFactor" : inertia_decayFactor,
      "pan_angleCapX" : pan_angleCapX,
      "pan_angleCapY" : pan_angleCapY,
      "zoom_minCap" : zoom_minCap,
      "zoom_maxCap" : zoom_maxCap,
    };
  }

  @override
  String toString() {
    return 'Camera(exposure: $exposure, projection: $projection, lensProjection: $lensProjection, scaling: $scaling, shift: $shift, mode: $_mode, targetPosition: $targetPosition, upVector: $upVector, zoomSpeed: $zoomSpeed, orbitHomePosition: $orbitHomePosition, orbitSpeed: $orbitSpeed, fovDirection: $fovDirection, fovDegrees: $fovDegrees, farPlane: $farPlane, mapExtent: $mapExtent, mapMinDistance: $mapMinDistance, flightStartPosition: $flightStartPosition, flightStartOrientation: $flightStartOrientation, flightMaxMoveSpeed: $flightMaxMoveSpeed, flightSpeedSteps: $flightSpeedSteps, flightMoveDamping: $flightMoveDamping, groundPlane: $groundPlane)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Camera &&
        other.exposure == exposure &&
        other.projection == projection &&
        other.lensProjection == lensProjection &&
        other.scaling == scaling &&
        other.shift == shift &&
        other._mode == _mode &&
        other.targetPosition == targetPosition &&
        other.upVector == upVector &&
        other.zoomSpeed == zoomSpeed &&
        other.orbitHomePosition == orbitHomePosition &&
        other.orbitSpeed == orbitSpeed &&
        other.fovDirection == fovDirection &&
        other.fovDegrees == fovDegrees &&
        other.farPlane == farPlane &&
        other.mapExtent == mapExtent &&
        other.mapMinDistance == mapMinDistance &&
        other.flightStartPosition == flightStartPosition &&
        other.flightStartOrientation == flightStartOrientation &&
        other.flightMaxMoveSpeed == flightMaxMoveSpeed &&
        other.flightSpeedSteps == flightSpeedSteps &&
        other.flightMoveDamping == flightMoveDamping &&
        other.groundPlane == groundPlane;
  }

  @override
  int get hashCode {
    return exposure.hashCode ^
        projection.hashCode ^
        lensProjection.hashCode ^
        scaling.hashCode ^
        shift.hashCode ^
        _mode.hashCode ^
        targetPosition.hashCode ^
        upVector.hashCode ^
        zoomSpeed.hashCode ^
        orbitHomePosition.hashCode ^
        orbitSpeed.hashCode ^
        fovDirection.hashCode ^
        fovDegrees.hashCode ^
        farPlane.hashCode ^
        mapExtent.hashCode ^
        mapMinDistance.hashCode ^
        flightStartPosition.hashCode ^
        flightStartOrientation.hashCode ^
        flightMaxMoveSpeed.hashCode ^
        flightSpeedSteps.hashCode ^
        flightMoveDamping.hashCode ^
        groundPlane.hashCode;
  }
}
