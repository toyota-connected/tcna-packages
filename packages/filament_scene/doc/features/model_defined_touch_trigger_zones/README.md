# Model-defined touch trigger zones.

`filament_scene` package provides a way to define touch trigger zones in your 3D scenes.

This feature allows 3D artists to independently define touch triggers in their 3D models without programmer intervention and associate an "event name" with them. When imported into a `filament_scene` app, the engine will automaticall generate colliders for these zones and trigger events when the user touches them.

## Usage

This manual will cover how to use this feature with Blender and GLB model files. No additional plugins or tools are required.

### 1. Prepare Blender

Open Blender. On the top-right side you should see a "Scene" panel and a list of objects in your scene. Select them and delete them.

![](./image%20(1).png)

![](./image%20(2).png)

### 2. Import a GLB/GLTF model

In the top-left corner, click on `File` > `Import` > `glTF 2.0 (.glb/.gltf)` and select a model file to import.

No particular import options are required.

![](./image%20(3).png)

The object should show up in the scene. If you notice it's not centered on (0, 0, 0), correct that before proceeding.

![](./image%20(4).png)

### 3. Add a touch trigger zone to the model

From the top-right "Scene" panel, select any object you want to add a touch trigger zone to. 

![](<Screenshot From 2025-07-15 05-35-53.png>)

Then, in the bottom-right "Properties" panel, select the `Object Properties` tab (the orange square icon - it should be open by default) and scroll down to the `Custom Properties` section.

Open the `Custom Properties` section and click on `Add` to add a new property. Then set the parameters as follows:

![alt text](<Screenshot From 2025-07-15 05-36-39.png>)

- Type: `String`
- Property Name: `fs_touchEvent`
- Default value: (none)
- Description: (optional, no effect)

Press `OK`. You should now see a `fs_touchEvent` property in the list.

![alt text](<Screenshot From 2025-07-15 05-36-52.png>)

In the text field next to it, enter the name of the touch trigger.
You can use the same name for many objects, but if you want to trigger different effects for different objects, you should use different names.

When you're done, you will need to communicate this name to a developer. It's possible they might choose a name first and tell it to you afterwards. It's good to have a list of agreed-upon names and descriptions of effects they trigger to avoid confusion in the team.

### 4. Export the model

In the top-left corner, click on `File` > `Export` > `glTF 2.0 (.glb/.gltf)` and select a file name to export to.

![alt text](<image (5).png>)

**IMPORTANT!** In the right-side panel of the `Export` dialog, open the `Include` section and make sure the `Custom Properties` checkbox is checked. **This is required for the touch trigger zones to work.**

![alt text](<image (6).png>)

### 5. (developers) Import the model into a `filament_scene` app

Just include the GLB file in the `assets` folder, and instantiate a `Model` entity with its path in `assetPath`.

### 6. (developers) Listen for touch events

In the `onTriggerEvent` callback of your `StatefulSceneView` many different events can be handled. To make sure you're handling the "model-defined touch trigger zone" event, first check the `eventName` parameter. If it's equal to `touchObject`, you can cast the dynamic `eventData` to a `CollisionEvent`. In `eventData.results[0].name` you will find the name of the touch trigger zone you defined in Blender!

![alt text](<Screenshot From 2025-07-15 05-39-20.png>)