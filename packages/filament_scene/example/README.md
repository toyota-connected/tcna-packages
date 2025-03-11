# filament_scene example

## 'Playground' scene

In the scene we have the following:

1. We have three models loaded (garage, Sequoia, and a fox).
* The Fox has animation abilities.
* The Sequoia has collision abilities. On click, changes material.

2. We have shapes loaded of a plane, sphere and cube
* Dynamic scaling.
* Collision on all shapes.
* Overridden guids for sending messages.
* All having same shared material, on click, setting a different material value.

3. Lights
* A center point light that you can change dynamically with the UI.
* 4 points lights that criss-cross around the room.

4. Callbacks implemented 
* Frame Render callback that updates light locations.
* Collision happened on mouse click callback that changes the materials on objects.

5. Able to change the quality settings in filament dynamically.
6. Can turn on/off rendering of shapes.
7. Can turn on/off rendering of collidables.

## 'Radar' scene

Tests model instancing and real-time transform updating.

## 'Settings' scene

Tests:

- Bidirectional Flutter UI communication
- Fog
- Screen-space reflections