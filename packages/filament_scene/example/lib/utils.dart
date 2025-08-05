import 'package:flutter/material.dart';
import 'dart:math';
import 'shape_and_object_creators.dart';
import 'package:filament_scene/generated/messages.g.dart';

////////////////////////////////////////////////////////////////////////
Color getTrueRandomColor() {
  Random random = Random();

  // Generate random values for red, green, and blue channels
  int red = random.nextInt(256);
  int green = random.nextInt(256);
  int blue = random.nextInt(256);

  // Create and return a Color object
  return Color.fromARGB(255, red, green, blue);
}

////////////////////////////////////////////////////////////////////////////////
Color getRandomPresetColor() {
  // List of preset colors from the Flutter Material color palette
  List<Color> presetColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  // Create a random instance
  Random random = Random();

  // Select a random color from the list
  return presetColors[random.nextInt(presetColors.length)];
}

enum LightState { stationary, goToNextCorner, crissCross, scatter }

LightState currentState = LightState.stationary;

const double roomMin = -15.0;
const double roomMax = 15.0;

double currentTimeInState = 0.0;

////////////////////////////////////////////////////////////////////////////////
double lerp(double start, double end, double t) {
  return start + (end - start) * t;
}

double clamp(double value, double min, double max) {
  return value.clamp(min, max);
}

////////////////////////////////////////////////////////////////////////////////
void crissCross(double deltaTime, double speed, FilamentViewApi filamentView) {
  for (var light in lightsWeCanChangeParamsOn) {
    // Increment t based on deltaTime and speed
    light.t += deltaTime * speed;

    // If t reaches or exceeds 1.0, reset it and swap positions
    if (light.t >= 1.0) {
      light.t -= 1.0; // Handle any overflow

      // Swap start and opposite positions
      double tempX = light.startX;
      double tempZ = light.startZ;
      light.startX = light.oppositeX;
      light.startZ = light.oppositeZ;
      light.oppositeX = tempX;
      light.oppositeZ = tempZ;

      light.phase = 'done';
    }

    // Compute new position using lerp
    light.origin.x = lerp(light.startX, light.oppositeX, light.t);
    light.origin.z = lerp(light.startZ, light.oppositeZ, light.t);

    // Apply the new transform
    filamentView.changeLightTransformByGUID(
      light.id,
      light.origin.x,
      light.origin.y,
      light.origin.z,
      0,
      -1,
      0,
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
void updateLights(double deltaTime, FilamentViewApi filamentView) {
  switch (currentState) {
    case LightState.goToNextCorner:
      break;
    case LightState.crissCross:
      crissCross(deltaTime, .1, filamentView);
      break;
    case LightState.scatter:
      break;
    case LightState.stationary:
      break;
  }
}

////////////////////////////////////////////////////////////////////////////////
void transitionState(LightState newState) {
  currentState = newState;
}

////////////////////////////////////////////////////////////////////////////////
void vRunLightLoops(FilamentViewApi filamentView) {
  const double frameTime = 1 / 60.0; // Simulate 60 FPS
  updateLights(frameTime, filamentView);

  currentTimeInState += frameTime;

  // add time check here.
  if (currentState == LightState.stationary) {
    transitionState(LightState.crissCross);
  } // Transition state based on conditions

  if (currentState == LightState.crissCross) {
    // Check if all lights are done
    bool allDone = lightsWeCanChangeParamsOn.every((light) => light.phase == 'done');
    if (allDone) {
      // Reset lights for continuous crisscrossing or transition to next state
      for (var light in lightsWeCanChangeParamsOn) {
        // Reset phase to start over
        light.phase = 'moving';
      }

      // Optionally transition to another state
      // transitionState(LightState.scatter);
    }
  }
}
