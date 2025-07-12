import 'package:filament_scene/camera/camera.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/shapes/shapes.dart';
import 'package:flutter/material.dart';
import 'package:my_fox_example/assets.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/math/utils.dart';

final List<EntityGUID> _radarConePieceGUID = [];
final List<EntityGUID> _radarSegmentPieceGUID = [];

class RadarSceneView extends StatefulSceneView {
  const RadarSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  @override
  _RadarSceneViewState createState() => _RadarSceneViewState();

  static final Map<String, EntityGUID> objectGuids = {'camera': generateGuid()};

  static final Camera _sceneCamera = Camera(
    id: objectGuids['camera']!,
    targetPoint: Vector3(-45, 1, 0),
    orbitAngles: Vector2(radians(-45), radians(-45)),
    targetDistance: 12,
    name: 'camera',
  );

  static List<Camera> getSceneCameras() {
    return [_sceneCamera];
  }

  static List<Model> getSceneModels() {
    final List<Model> models = [];

    for (int i = 0; i < 10; i++) {
      models.add(
        GlbModel.asset(
          assetPath: sequoiaAsset,
          position: Vector3(-40, 0, i * 5 - 25),
          scale: Vector3.all(1),
          rotation: Quaternion.identity(),
          collidable: null,
          animation: null,
          receiveShadows: true,
          castShadows: true,
          name: "sequoia_$i",
          id: generateGuid(),
          instancingMode: ModelInstancingType.instanced,
        ),
      );
    }

    models.add(
      GlbModel.asset(
        assetPath: roadAsset,
        position: Vector3(-40, 0, 0),
        scale: Vector3(.4, .1, .2),
        rotation: Quaternion.identity(),
        collidable: null,
        animation: null,
        receiveShadows: true,
        castShadows: false,
        name: "road",
        id: generateGuid(),
        instancingMode: ModelInstancingType.none,
      ),
    );

    EntityGUID id = generateGuid();
    _radarConePieceGUID.add(id);

    models.add(
      GlbModel.asset(
        id: id,
        assetPath: radarConeAsset,
        name: "radarCone",
        position: Vector3(-42.1, 1, 0),
        scale: Vector3(4, 1, 3),
        rotation: Quaternion.identity(),
        collidable: null,
        animation: null,
        receiveShadows: false,
        castShadows: false,
        instancingMode: ModelInstancingType.none,
      ),
    );

    // primary radar segment
    // models.add(poGetModel(
    //     radarSegmentAsset,
    //     Vector3(0, 0, 0),
    //     Vector3.all(1),
    //     Quaternion(0.0, 0, 0, 1),
    //     null,
    //     null,
    //     true,
    //     true,
    //     generateGuid(),
    //     true,
    //     true));

    for (int i = 0; i < 20; i++) {
      EntityGUID idForSegment = generateGuid();

      models.add(
        GlbModel.asset(
          id: idForSegment,
          assetPath: radarSegmentAsset,
          name: "radarSegment_$i",
          position: Vector3(-42.2, 0, 0),
          scale: Vector3(0, 0, 0),
          rotation: Quaternion(0.7071, 0, 0.7071, 0),
          collidable: null,
          animation: null,
          receiveShadows: true,
          castShadows: true,
          instancingMode: ModelInstancingType.instanced,
        ),
      );

      _radarSegmentPieceGUID.add(idForSegment);
    }

    return models;
  }

  static List<Shape> getSceneShapes() {
    final List<Shape> shapes = [];

    return shapes;
  }

  static List<Light> getSceneLights() {
    final List<Light> lights = [];

    return lights;
  }
}

class _RadarSceneViewState extends StatefulSceneViewState<RadarSceneView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              onTriggerEvent("doOneWaveSegment");
            });
          },
          child: const Text('Send Single Line out'),
        ),
        const SizedBox(width: 5),
        ElevatedButton(
          onPressed: () {
            setState(() {
              onTriggerEvent("do3RadarWaveSegments");
            });
          },
          child: const Text('Send Wave Out'),
        ),
        // Add more alternate buttons if needed
      ],
    );
  }

  @override
  void onCreate() {
    RadarSceneView._sceneCamera.setActive();

    widget.filament.setFogOptions(false);
  }

  @override
  void onDestroy() {}

  @override
  void onTriggerEvent(final String eventName, [final dynamic eventData]) {
    switch (eventName) {
      case "doOneWaveSegment":
        vDoOneWaveSegment(widget.filament);
        break;

      case "do3RadarWaveSegments":
        vDo3RadarWaveSegments(widget.filament);
        break;

      default:
        throw UnsupportedError(
          "event '$eventName' is not supported by $runtimeType",
        );
    }
  }

  @override
  void onUpdateFrame(FilamentViewApi filamentView, double deltaTime) {
    // print("update radar");

    // Process each segment in use
    for (int i = 0; i < inUse.length; i++) {
      SegmentData segment = inUse[i];

      // Update the elapsed time for the segment
      segment.elapsedTime += deltaTime;

      if (segment.elapsedTime > 2.5) {
        resetSegment(filamentView, segment.id);
        continue;
      }

      // Example logic: scale and move the segment outward
      double scaleFactor = (segment.elapsedTime * 0.6); // Example scale factor

      // If it's < 0, we turn the scale all the way off (set to 0)
      if (segment.elapsedTime < 0) {
        scaleFactor = 0.0;
      }

      double moveDistance =
          segment.elapsedTime * 12; // Example movement distance

      // Apply the position and scale changes
      _setPositionAndScale(filamentView, segment.id, moveDistance, scaleFactor);

      // Debugging: Print the update
      // print('vUpdate: Moving segment ${segment.id} to positionOffset: $moveDistance, scaleFactor: $scaleFactor');
    }
  }
}

// Define a class to hold both GUID and elapsed time for each segment
class SegmentData {
  EntityGUID id;
  double elapsedTime;

  SegmentData(this.id, this.elapsedTime);
}

// List of segments that are currently in use
List<SegmentData> inUse = [];

// List of segments that are free (available to use)
List<SegmentData> free = List.from(
  _radarSegmentPieceGUID.map((id) => SegmentData(id, 0.0)),
);

void vDoOneWaveSegment(FilamentViewApi filamentView) {
  if (free.isNotEmpty) {
    SegmentData segmentData = free.removeAt(0); // Get a free segment
    segmentData.elapsedTime = 0;
    inUse.add(segmentData); // Add to in-use list

    // Set the position and scale for this segment
    _setPositionAndScale(filamentView, segmentData.id, 0.0, 0.0);
    filamentView.turnOnVisualForEntity(segmentData.id); // turnOnVisualForEntity

    // if you want a specific color; note the game models i checked in dont have
    // materials on them.
    // Map<String, dynamic> ourJson = poGetRandomColorMaterialParam().toJson();
    // filamentView.changeMaterialParameter(ourJson, segmentData.id);

    // Debugging: Print the current state
    //print('vDoOneWaveSegment: Moved GUID to inUse: ${segmentData.id}');
  } else {
    // print('No free wave segments available.');
  }
}

void vDo3RadarWaveSegments(FilamentViewApi filamentView) {
  for (int i = 0; i < 3; i++) {
    if (free.isNotEmpty) {
      SegmentData segmentData = free.removeAt(0); // Get a free segment
      segmentData.elapsedTime = -i * 0.3; // Set elapsed time for each segment

      inUse.add(segmentData); // Add to in-use list

      // Set the position and scale for this segment
      _setPositionAndScale(filamentView, segmentData.id, 0.0, 0.0);
      filamentView.turnOnVisualForEntity(
        segmentData.id,
      ); // turnOnVisualForEntity

      // Debugging: Print the current state
      //print('vDo3RadarWaveSegments: Moved GUID to inUse: ${segmentData.id}');
    } else {
      // print('Not enough free segments available.');
      break;
    }
  }
}

void _setPositionAndScale(
  FilamentViewApi filamentView,
  EntityGUID id,
  double positionOffset,
  double scaleFactor,
) {
  // Placeholder function to set position and scale based on GUID
  // Add your custom logic for applying position and scale to the model
  //print("_setPositionAndScale: $id | positionOffset = $positionOffset, scaleFactor = $scaleFactor");

  filamentView.setEntityTransformPosition(
    id,
    Vector3(-42.2 - positionOffset, 1, 0).storage64,
  );

  /* if(scaleFactor == 0) {
    filamentView.turnOffVisualForEntity(id); // turnOnVisualForEntity

    return;
  } else {
    filamentView.turnOnVisualForEntity(id); // turnOnVisualForEntity
  }*/

  filamentView.setEntityTransformScale(
    id,
    Vector3(scaleFactor * 6, scaleFactor, scaleFactor).storage64,
  );
}

void resetSegment(FilamentViewApi filamentView, EntityGUID id) {
  // Move the segment back to the free list once it's done
  SegmentData? segmentData = inUse.firstWhere(
    (segment) => segment.id == id,
    orElse: () =>
        SegmentData(id, 0.0), // Provide a default object instead of null
  );

  if (segmentData.id == id) {
    // Only proceed if we found a matching segment
    inUse.remove(segmentData);
    free.add(segmentData); // Add the segment back to the free list

    filamentView.turnOffVisualForEntity(id); // turnOnVisualForEntity

    _setPositionAndScale(filamentView, id, 0, 0);

    //print('resetSegment: Moved $id back to free list.');
  } else {
    //print('resetSegment: GUID $id is not currently in use.');
  }
}
