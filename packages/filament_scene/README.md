# filament_scene

<!-- [![pub package](https://img.shields.io/pub/v/filament_scene.svg?color=1284C5)](https://pub.dev/packages/filament_scene) -->
<a href="https://github.com/toyota-connected/tcna-packages/blob/main/packages/filament_scene/LICENSE"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>

Game engine for Flutter, based on Google's [Filament](https://github.com/google/filament) 3D rendering engine.
It includes the scripting interface that interacts directly with [`ivi-homescreen-plugins/filament_view`](https://github.com/toyota-connected/ivi-homescreen-plugins/tree/v2.0/plugins/filament_view).

## Design & Purpose

`filament_scene` is a mobile/embedded optimized game engine focusing on touch-based interaction.

While its base features match larger modern game engines such as Unity/Unreal/Godot, it's optimized for low-overhead execution, quick loading times, and graphical fidelity - with the latter being enabled by Google's Filament PBR 3D renderer.

The engine API is written in Dart, and it integrates neatly with Flutter and its developer tooling, enabling quick development cycles and best-in-class developer experience.

Its engine core is implemented in C++ (see [`ivi-homescreen-plugins/filament_view`](https://github.com/toyota-connected/ivi-homescreen-plugins/tree/v2.0/plugins/filament_view)) to ensure optimal memory management, best optimization practices and enable you to benefit from native-level performance.

## Features

- Developer tooling
  - Flutter UI integration
- Models
  - Loading GLTF/GLB files
  - Model instancing
  - Animations
    - Play/Pause/Resume/Stop single animation
    - Enqueue/Clear Queue
    - Change speed
    - Set Looping
    - Callbacks
- Materials
  - (**TODO**) Runtime editing
  - Material instancing
  - Customizable shaders
- Interactivity
  - Camera gestures
  - Screen-space touch raycasts
  - Bidirectional communication with Flutter UI
- ECS
  - C++ implementation for optimal performance & efficiency
  - (**TODO**) Transform parenting
- Scene environment
  - Camera
    - Exposure
    - Physically-based lens projection
    - Perspective/Orthogonal projection
  - Skybox
    - Color
    - HDR
    - KTX
  - Bloom
  - Fog
  - Shadows
  - Lighting
    - Dynamic
      - Point/Spot/FocusedSpot/Directional/Sun 
    - Indirect (scene-wide)
      - Color (spherical harmonics)
      - HDR
      - KTX
- Shapes
  - Cube
  - Plane
  - Sphere
- Texture compression
  - Compile-time tooling

## Installation

*Documentation in progress. Package will be available on pub.dev soon.*

## Usage

You can integrate `filament_scene` in your Flutter app as a simple widget!

*Detailed usage instructions coming soon.*

## Docs & References

- [Manual](#) coming soon!
- [API Reference](#) coming soon!
- [Example code](https://github.com/toyota-connected/tcna-packages/tree/main/packages/filament_scene/example) - reference implementation including multiple example scenes

### Further reading

- [Filament](https://google.github.io/filament/Filament.html) - An in-depth explanation of real-time physically based rendering, the graphics capabilities and implementation of Filament
- [Materials](https://google.github.io/filament/Materials.html) - Full reference documentation for our material system
- [Material Properties](https://google.github.io/filament/Material%20Properties.pdf) - A reference sheet for the standard material model
- [Filament sample Android apps](https://github.com/google/filament/tree/main/android/samples) - Sample Android applications demonstrating Filament APIs
- [Getting Started with Filament on Android](https://medium.com/@philiprideout/getting-started-with-filament-on-android-d10b16f0ec67) by Philip Rideout