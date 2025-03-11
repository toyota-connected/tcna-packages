
import 'package:flutter/material.dart';
import 'package:my_fox_example/assets.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/scenes/scene_view.dart';
import 'package:my_fox_example/shape_and_object_creators.dart';
import 'package:filament_scene/filament_scene.dart';
import 'package:uuid/uuid.dart';



final List<String> _radarConePieceGUID = [];
final List<String> _radarSegmentPieceGUID = [];

class RadarSceneView extends StatefulSceneView {

  RadarSceneView({
    super.key,
    required super.filament,
    required super.frameController,
    required super.collisionController,
    required super.readinessController,
  }) : super();

  @override
  _RadarSceneViewState createState() => _RadarSceneViewState();

  static const Map<String, Uuid> objectGuids = {

  };

  static List<Model> getSceneModels() {
    final List<Model> models = [];

      for (int i = 0; i < 10; i++) {
    models.add(poGetModel(
        sequoiaAsset,
        Vector3.only(x: -40, y: 0, z: i * 5 - 25),
        Vector3.only(x: 1, y: 1, z: 1),
        Vector4(x: 0, y: 0, z: 0, w: 1),
        null,
        null,
        true,
        true,
        const Uuid().v4(),
        true,
        false));
  }

  models.add(poGetModel(
      roadAsset,
      Vector3.only(x: -40, y: 0, z: 0),
      Vector3.only(x: .4, y: .1, z: .2),
      Vector4(x: 0, y: 0, z: 0, w: 1),
      null,
      null,
      true,
      false,
      const Uuid().v4(),
      false,
      false));

  String guid = const Uuid().v4();
  _radarConePieceGUID.add(guid);

  models.add(poGetModel(
      radarConeAsset,
      Vector3.only(x: -42.1, y: 1, z: 0),
      Vector3.only(x: 4, y: 1, z: 3),
      Vector4(x: 0, y: 0, z: 0, w: 1),
      null,
      null,
      false,
      false,
      guid,
      false,
      false));

  // primary radar segment
  // models.add(poGetModel(
  //     radarSegmentAsset,
  //     Vector3.only(x: 0, y: 0, z: 0),
  //     Vector3.only(x: 1, y: 1, z: 1),
  //     Vector4(x: 0.0, y: 0, z: 0, w: 1),
  //     null,
  //     null,
  //     true,
  //     true,
  //     const Uuid().v4(),
  //     true,
  //     true));

  for (int i = 0; i < 20; i++) {
    String guidForSegment = const Uuid().v4();

    models.add(poGetModel(
        radarSegmentAsset,
        Vector3.only(x: -42.2, y: 0, z: 0),
        Vector3.only(x: 0, y: 0, z: 0),
        Vector4(x: 0.7071, y: 0, z: 0.7071, w: 0),
        null,
        null,
        true,
        true,
        guidForSegment,
        true,
        false));

    _radarSegmentPieceGUID.add(guidForSegment);
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
            // vDoOneWaveSegment(filamentViewApi);
            onTriggerEvent("doOneWaveSegment");
          });
        },
        child: const Text('Send Single Line out'),
      ),
      const SizedBox(width: 5),
      ElevatedButton(
        onPressed: () {
          setState(() {
            // vDo3RadarWaveSegments(filamentViewApi);
            onTriggerEvent("do3RadarWaveSegments");
          });
        },
        child: const Text('Send Wave Out'),
      ),
      // Add more alternate buttons if needed
    ]
    );
  }

  @override
  void onCreate() {
    widget.filament.changeCameraOrbitHomePosition(-40, 5, 0);
    widget.filament.changeCameraTargetPosition(-45, 0, 0);
    widget.filament.changeCameraFlightStartPosition(-25, 15, 0);

    widget.filament.setFogOptions(false);
  }

  @override
  void onDestroy() {}

  @override
  void onTriggerEvent(final String eventName, [final dynamic? eventData]) {
    switch(eventName) {
      case "doOneWaveSegment":
        vDoOneWaveSegment(widget.filament);
        break;
      
      case "do3RadarWaveSegments":
        vDo3RadarWaveSegments(widget.filament);
        break;

      default:
        throw UnsupportedError("event '$eventName' is not supported by $runtimeType");
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
        resetSegment(filamentView, segment.guid);
        continue;
      }

      // Example logic: scale and move the segment outward
      double scaleFactor = (segment.elapsedTime * 0.6); // Example scale factor

      // If it's < 0, we turn the scale all the way off (set to 0)
      if (segment.elapsedTime < 0) {
        scaleFactor = 0.0;
      }

      double moveDistance = segment.elapsedTime * 12; // Example movement distance

      // Apply the position and scale changes
      vSetPositionAndScale(filamentView, segment.guid, moveDistance, scaleFactor);

      // Debugging: Print the update
      // print('vUpdate: Moving segment ${segment.guid} to positionOffset: $moveDistance, scaleFactor: $scaleFactor');
    }
  }
}

// Define a class to hold both GUID and elapsed time for each segment
class SegmentData {
  String guid;
  double elapsedTime;

  SegmentData(this.guid, this.elapsedTime);
}

// List of segments that are currently in use
List<SegmentData> inUse = [];

// List of segments that are free (available to use)
List<SegmentData> free = List.from(_radarSegmentPieceGUID.map((guid) => SegmentData(guid, 0.0)));

void vDoOneWaveSegment(FilamentViewApi filamentView) {
  if (free.isNotEmpty) {
    SegmentData segmentData = free.removeAt(0); // Get a free segment
    segmentData.elapsedTime = 0;
    inUse.add(segmentData); // Add to in-use list

    // Set the position and scale for this segment
    vSetPositionAndScale(filamentView, segmentData.guid, 0.0, 0.0);
    filamentView
        .turnOnVisualForEntity(segmentData.guid); // turnOnVisualForEntity

    // if you want a specific color; note the game models i checked in dont have
    // materials on them.
    // Map<String, dynamic> ourJson = poGetRandomColorMaterialParam().toJson();
    // filamentView.changeMaterialParameter(ourJson, segmentData.guid);

    // Debugging: Print the current state
    //print('vDoOneWaveSegment: Moved GUID to inUse: ${segmentData.guid}');
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
      vSetPositionAndScale(filamentView, segmentData.guid, 0.0, 0.0);
      filamentView
          .turnOnVisualForEntity(segmentData.guid); // turnOnVisualForEntity

      // Debugging: Print the current state
      //print('vDo3RadarWaveSegments: Moved GUID to inUse: ${segmentData.guid}');
    } else {
      // print('Not enough free segments available.');
      break;
    }
  }
}

// TODO(kerberjg): this should be inside the filament frame update logic
@Deprecated("this should be inside the filament frame update logic")
void vSetPositionAndScale(FilamentViewApi filamentView, String guid,
    double positionOffset, double scaleFactor) {
  // Placeholder function to set position and scale based on GUID
  // Add your custom logic for applying position and scale to the model
  //print("vSetPositionAndScale: $guid | positionOffset = $positionOffset, scaleFactor = $scaleFactor");

  filamentView.changeTranslationByGUID(guid, -42.2 - positionOffset, 1, 0);

  /* if(scaleFactor == 0) {
    filamentView.turnOffVisualForEntity(guid); // turnOnVisualForEntity

    return;
  } else {
    filamentView.turnOnVisualForEntity(guid); // turnOnVisualForEntity
  }*/

  filamentView.changeScaleByGUID(
      guid, scaleFactor * 6, scaleFactor, scaleFactor);
}

void resetSegment(FilamentViewApi filamentView, String guid) {
  // Move the segment back to the free list once it's done
  SegmentData? segmentData = inUse.firstWhere((segment) => segment.guid == guid,
      orElse: () =>
          SegmentData(guid, 0.0) // Provide a default object instead of null
      );

  if (segmentData.guid == guid) {
    // Only proceed if we found a matching segment
    inUse.remove(segmentData);
    free.add(segmentData); // Add the segment back to the free list

    filamentView.turnOffVisualForEntity(guid); // turnOnVisualForEntity

    vSetPositionAndScale(filamentView, guid, 0, 0);

    //print('resetSegment: Moved $guid back to free list.');
  } else {
    //print('resetSegment: GUID $guid is not currently in use.');
  }
}
