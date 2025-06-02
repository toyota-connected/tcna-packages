import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/shape_and_object_creators.dart';

const defaultTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.black,
  shadows: [
    Shadow(
      offset: Offset(-1.5, -1.5),
      color: Colors.white,
    ),
    Shadow(
      offset: Offset(1.5, -1.5),
      color: Colors.white,
    ),
    Shadow(
      offset: Offset(1.5, 1.5),
      color: Colors.white,
    ),
    Shadow(
      offset: Offset(-1.5, 1.5),
      color: Colors.white,
    ),
  ],
);

typedef StateSetter = void Function(VoidCallback fn);


class ViewSettingsWidget extends StatefulWidget {
  final FilamentViewApi filament;

  const ViewSettingsWidget({
    Key? key,
    required this.filament,
  }) : super(key: key);

  @override
  _ViewSettingsWidgetState createState() => _ViewSettingsWidgetState();
}

class _ViewSettingsWidgetState extends State<ViewSettingsWidget> {
  bool _autoRotate = false;
  bool _toggleShapes = true;
  bool _toggleCollidableVisuals = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _autoRotate = !_autoRotate;
              if (_autoRotate) {
                widget.filament.changeCameraMode("AUTO_ORBIT");
              } else {
                widget.filament.changeCameraMode("INERTIA_AND_GESTURES");
              }
            });
          },
          child: Text(
            _autoRotate ? 'Auto Orbit On' : 'Inertia & Gestures On',
          ),
        ),
        const SizedBox(width: 5),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.filament.resetInertiaCameraToDefaultValues();
            });
          },
          child: const Text('Reset'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _toggleShapes = !_toggleShapes;
              widget.filament.toggleShapesInScene(_toggleShapes);
            });
          },
          child: Text(
            _toggleShapes ? 'Toggle Shapes: On' : 'Toggle Shapes: Off',
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.filament.toggleDebugCollidableViewsInScene(
                _toggleCollidableVisuals,
              );
              _toggleCollidableVisuals = !_toggleCollidableVisuals;
            });
          },
          child: Text(
            _toggleCollidableVisuals
                ? 'Toggle Collidables: On'
                : 'Toggle Collidables: Off',
          ),
        ),
        const SizedBox(width: 5),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.filament.changeViewQualitySettings();
            });
          },
          child: const Text('Qual'),
        ),
      ]
    );
  }
}

class LightSettingsWidget extends StatefulWidget {
  final FilamentViewApi filament;

  const LightSettingsWidget({
    Key? key,
    required this.filament,
  }) : super(key: key);

  @override
  _LightSettingsWidgetState createState() => _LightSettingsWidgetState();
}

class _LightSettingsWidgetState extends State<LightSettingsWidget> {
  Color _directLightColor = Colors.white;
  double _directIntensity = 300000000;
  final double _minIntensity = 500000;
  final double _maxIntensity = 300000000;
  double _cameraRotation = 0;



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withAlpha(0x80),
      ),
      padding: const EdgeInsets.all(16),
      width: 320,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Direct Light', style: defaultTextStyle),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: ColorPicker(
              colorPickerWidth: 100,
              pickerColor: _directLightColor,
              onColorChanged: (Color color) {
                setState(() {
                  _directLightColor = color;
                  final String colorString = _directLightColor.toHexString(includeHashSign: true);

                  widget.filament.changeLightColorByGUID(
                    centerPointLightGUID,
                    colorString,
                    _directIntensity.toInt(),
                  );
                });
              },
              pickerAreaHeightPercent: 1.0,
              enableAlpha: false,
              displayThumbColor: false,
              portraitOnly: true,
              paletteType: PaletteType.hueWheel,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Intensity', style: defaultTextStyle),
                Slider(
                  value: _directIntensity,
                  min: _minIntensity,
                  max: _maxIntensity,
                  onChanged: (double value) {
                    setState(() {
                      _directIntensity = value;
                      final String colorString = _directLightColor.toHexString(includeHashSign: true);

                      widget.filament.changeLightColorByGUID(
                        centerPointLightGUID,
                        colorString,
                        _directIntensity.toInt(),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -- CAMERA ROTATION SLIDER --
          const Text('Camera Rotation', style: defaultTextStyle),
          Slider(
            value: _cameraRotation,
            min: 0,
            max: 600,
            onChanged: (double value) {
              setState(() {
                _cameraRotation = value;
                widget.filament.setCameraRotation(_cameraRotation / 100);
              });
            },
          ),
        ],
      ),
    );
  }
}