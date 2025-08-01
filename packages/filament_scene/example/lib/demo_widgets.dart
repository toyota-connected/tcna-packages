import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/shape_and_object_creators.dart';

const defaultTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.black,
  shadows: [
    Shadow(offset: Offset(-1.5, -1.5), color: Colors.white),
    Shadow(offset: Offset(1.5, -1.5), color: Colors.white),
    Shadow(offset: Offset(1.5, 1.5), color: Colors.white),
    Shadow(offset: Offset(-1.5, 1.5), color: Colors.white),
  ],
);

typedef StateSetter = void Function(VoidCallback fn);

class ViewSettingsWidget extends StatefulWidget {
  final FilamentViewApi filament;

  const ViewSettingsWidget({Key? key, required this.filament})
    : super(key: key);

  @override
  _ViewSettingsWidgetState createState() => _ViewSettingsWidgetState();
}

class _ViewSettingsWidgetState extends State<ViewSettingsWidget> {
  bool _toggleShapes = true;
  bool _toggleColliderVisuals = false;

  int _quality = 4;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 16,
      children: [
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
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.filament.toggleDebugColliderViewsInScene(
                _toggleColliderVisuals,
              );
              _toggleColliderVisuals = !_toggleColliderVisuals;
            });
          },
          child: Text(
            _toggleColliderVisuals
                ? 'Toggle Colliders: On'
                : 'Toggle Colliders: Off',
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _quality = (_quality + 1) % 5; // Cycle through 0-4
              widget.filament.changeViewQualitySettings();
            });
          },
          child: Text('Quality ($_quality)'),
        ),
      ],
    );
  }
}

class LightSettingsWidget extends StatefulWidget {
  final FilamentViewApi filament;

  const LightSettingsWidget({Key? key, required this.filament})
    : super(key: key);

  @override
  _LightSettingsWidgetState createState() => _LightSettingsWidgetState();
}

class _LightSettingsWidgetState extends State<LightSettingsWidget> {
  Color _directLightColor = Colors.white;
  double _directIntensity = 300000000;
  final double _minIntensity = 500000;
  final double _maxIntensity = 300000000;

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
                  final String colorString = _directLightColor.toHexString(
                    includeHashSign: true,
                  );

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
                      final String colorString = _directLightColor.toHexString(
                        includeHashSign: true,
                      );

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
        ],
      ),
    );
  }
}
