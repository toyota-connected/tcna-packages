import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:my_fox_example/main.dart';
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

  const ViewSettingsWidget({Key? key, required this.filament}) : super(key: key);

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
          child: Text(_toggleShapes ? 'Toggle Shapes: On' : 'Toggle Shapes: Off'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.filament.toggleDebugCollidableViewsInScene(_toggleColliderVisuals);
              _toggleColliderVisuals = !_toggleColliderVisuals;
            });
          },
          child: Text(_toggleColliderVisuals ? 'Toggle Colliders: On' : 'Toggle Colliders: Off'),
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

  const LightSettingsWidget({Key? key, required this.filament}) : super(key: key);

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

class FrameProfilingOverlay extends StatefulWidget {
  final ValueNotifier<FrameProfilingData> data;

  const FrameProfilingOverlay({Key? key, required this.data}) : super(key: key);

  @override
  _FrameProfilingOverlayState createState() => _FrameProfilingOverlayState();
}

class _FrameProfilingOverlayState extends State<FrameProfilingOverlay> {
  final ListQueue<double> _fpsHistory = ListQueue<double>(60); // Store last 60 FPS values
  final ListQueue<double> _cpuHistory = ListQueue<double>(60); // Store last 60 CPU frame times
  final ListQueue<double> _gpuHistory = ListQueue<double>(60); // Store last 60 GPU frame times

  double avgFPS = 0;
  // Average CPU frametime in milliseconds
  double avgCPU = 0;
  // Average GPU frametime in milliseconds
  double avgGPU = 0;

  @override
  void initState() {
    super.initState();
    widget.data.addListener(() {
      setState(() {
        // Add new values to history
        _fpsHistory.add(widget.data.value.fps);
        _cpuHistory.add(widget.data.value.cpuFrameTime);
        _gpuHistory.add(widget.data.value.gpuFrameTime);

        // Maintain only the last 60 values
        if (_fpsHistory.length > 60) _fpsHistory.removeFirst();
        if (_cpuHistory.length > 60) _cpuHistory.removeFirst();
        if (_gpuHistory.length > 60) _gpuHistory.removeFirst();

        // Update averages
        avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
        avgCPU = _cpuHistory.reduce((a, b) => a + b) / _cpuHistory.length;
        avgGPU = _gpuHistory.reduce((a, b) => a + b) / _gpuHistory.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: true,
    // Display the FPS and frame times as text
    // Under, shows a graph of columns (32px tall, 8px wide) for each value
    child: Container(
      // height: 128,
      color: Colors.black.withAlpha(0x80),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS: ${avgFPS.toStringAsFixed(2)}\n'
            'CPU Frame Time: ${avgCPU.toStringAsFixed(2)} ms\n'
            'GPU Frame Time: ${avgGPU.toStringAsFixed(2)} ms',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          // white line
          Container(height: 1, width: 60 * 6, color: Colors.white),
          Container(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < _fpsHistory.length; i++)
                  Container(
                    width: 4,
                    height:
                        64 *
                        ((_cpuHistory.elementAt(i) + _gpuHistory.elementAt(i)) /
                            (1000 / _fpsHistory.elementAt(i))),
                    margin: const EdgeInsets.only(right: 2),
                    color: Colors.green,
                  ),
              ],
            ),
          ),
          // white line
          Container(height: 1, width: 60 * 6, color: Colors.white),
        ],
      ),
    ),
  );
}
