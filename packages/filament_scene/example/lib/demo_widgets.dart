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

/// NOTE: DO NOT use a [RepaintBoundary] with this widget
class FrameProfilingOverlay extends StatefulWidget {
  final ValueNotifier<FrameProfilingData> data;

  const FrameProfilingOverlay({Key? key, required this.data}) : super(key: key);

  @override
  _FrameProfilingOverlayState createState() => _FrameProfilingOverlayState();
}

class _FrameProfilingOverlayState extends State<FrameProfilingOverlay> {
  static const int kExpectedFPS = 60; // Expected FPS for the graph
  static const double kExpectedFrameTime =
      1000 / kExpectedFPS; // Expected frame time in milliseconds

  final ListQueue<double> _fpsHistory = ListQueue<double>(kExpectedFPS); // Store last 60 FPS values
  final ListQueue<double> _cpuHistory = ListQueue<double>(
    kExpectedFPS,
  ); // Store last 60 CPU frame times
  final ListQueue<double> _gpuHistory = ListQueue<double>(
    kExpectedFPS,
  ); // Store last 60 GPU frame times
  final ListQueue<double> _scpHistory = ListQueue<double>(
    kExpectedFPS,
  ); // Store last 60 script frame times

  double avgFPS = 0;
  // Average CPU frametime in milliseconds
  double avgCPU = 0;
  // Average GPU frametime in milliseconds
  double avgGPU = 0;
  // Average script frametime in milliseconds
  double avgScp = 0;

  @override
  void initState() {
    super.initState();
    widget.data.addListener(() {
      setState(() {
        // Add new values to history
        _fpsHistory.add(widget.data.value.fps);
        _cpuHistory.add(widget.data.value.cpuFrameTime);
        _gpuHistory.add(widget.data.value.gpuFrameTime);
        _scpHistory.add(widget.data.value.scriptFrameTime);

        // Maintain only the last 60 values
        if (_fpsHistory.length > kExpectedFPS) _fpsHistory.removeFirst();
        if (_cpuHistory.length > kExpectedFPS) _cpuHistory.removeFirst();
        if (_gpuHistory.length > kExpectedFPS) _gpuHistory.removeFirst();
        if (_scpHistory.length > kExpectedFPS) _scpHistory.removeFirst();

        // Update averages
        avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
        avgCPU = _cpuHistory.reduce((a, b) => a + b) / _cpuHistory.length;
        avgGPU = _gpuHistory.reduce((a, b) => a + b) / _gpuHistory.length;
        avgScp = _scpHistory.reduce((a, b) => a + b) / _scpHistory.length;
      });
    });
  }

  static const double kPerfBarWidth = 2; // Width of each bar in the graph
  static const double kPerfBarHeight = 64; // Height of the graph
  static const double kPerfBarSpacing = 1; // Spacing between bars

  static const double kPerfGraphWidth = kExpectedFPS * (kPerfBarWidth + kPerfBarSpacing);

  static const Color kColorTransparentWhite = Color(0x80FFFFFF);

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
          const Text(
            'Fluorite Game Engine',
            style: TextStyle(
              fontFamily: 'Galmuri11', //
              fontSize: 12, //
              fontWeight: FontWeight.bold, //
              color: Colors.white, //
            ),
          ),
          Text(
            'FPS: ${avgFPS.toStringAsFixed(2)}\n'
            'CPU    frametime: ${avgCPU.toStringAsFixed(2)} ms\n'
            'GPU    frametime: ${avgGPU.toStringAsFixed(2)} ms\n'
            'Script frametime: ${avgScp.toStringAsFixed(2)} ms',
            style: const TextStyle(
              fontFamily: 'Galmuri9', //
              fontSize: 10, //
              color: Colors.white, //
            ),
          ),
          const SizedBox(height: 8),
          // white line
          const SizedBox(
            height: 1,
            width: kPerfGraphWidth,
            child: ColoredBox(color: Colors.white),
          ),
          SizedBox(
            height: kPerfBarHeight,
            width: kPerfGraphWidth,
            child: Stack(
              alignment: Alignment.topLeft,
              fit: StackFit.passthrough,
              children: [
                // Combined frametime bar chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < _fpsHistory.length; i++)
                      Container(
                        width: kPerfBarWidth,
                        // dart format off
                        height: kPerfBarHeight * (
                          _cpuHistory.elementAt(i) +
                          _gpuHistory.elementAt(i) +
                          _scpHistory.elementAt(i) //
                        ) / kExpectedFrameTime,
                        // dart format on
                        margin: const EdgeInsets.only(right: 1),
                        color: Colors.green,
                      ),
                  ],
                ),
                // Chart labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // (16.6ms marker)
                    Text(
                      "${kExpectedFrameTime.toStringAsFixed(1)}ms",
                      style: const TextStyle(
                        fontFamily: 'Galmuri7',
                        fontSize: 8,
                        height: 1,
                        color: kColorTransparentWhite,
                      ),
                    ),
                    // spacing height / 2 - 8
                    const SizedBox(height: kPerfBarHeight / 2 - 8 - 1),
                    // line
                    const SizedBox(
                      height: 1,
                      width: kPerfGraphWidth,
                      child: ColoredBox(color: kColorTransparentWhite),
                    ),
                    // (8.3ms marker)
                    Text(
                      "${(kExpectedFrameTime / 2).toStringAsFixed(1)}ms",
                      style: const TextStyle(
                        fontFamily: 'Galmuri7',
                        fontSize: 8,
                        height: 1,
                        color: kColorTransparentWhite,
                      ),
                    ),
                    // spacing height / 2 - 8
                    const SizedBox(height: kPerfBarHeight / 2 - 8 - 8 - 1),
                    // (0ms marker)
                    const Text(
                      "0ms",
                      style: TextStyle(
                        fontFamily: 'Galmuri7',
                        fontSize: 8,
                        height: 1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // white line
          const SizedBox(
            height: 1,
            width: kPerfGraphWidth,
            child: ColoredBox(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
