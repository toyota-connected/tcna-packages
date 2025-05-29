# filament_scene example

## 'Playground' scene

This scene demonstrates various 3D rendering capabilities and interactive features.

1. Models
   - Three models loaded (garage, Sequoia, and fox)
   - Fox includes animation capabilities
   - Sequoia features collision detection and material changes on click

2. Basic Shapes
   - Plane, sphere and cube with dynamic scaling
   - Collision detection enabled on all shapes
   - Overridden guids for message handling
   - Shared material system with click-based material updates

3. Lighting System
   - Centralized point light with dynamic UI control
   - Four moving point lights creating cross-pattern illumination

4. Event System
   - Frame render callback for light position updates
   - Mouse click collision callback for material modifications

5. Dynamic Features
   - Real-time Filament quality setting adjustments
   - Toggle shape rendering
   - Toggle collision visualization

## 'Radar' scene

A specialized scene focusing on:
- Model instancing capabilities
- Real-time transform updates

## 'Settings' scene

A testing environment for advanced features:
- Bidirectional Flutter UI communication
- Fog effects
- Screen-space reflections