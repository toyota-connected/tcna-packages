import 'dart:collection';
import 'dart:math';

import 'package:filament_scene/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:filament_scene/generated/messages.g.dart';
import 'package:fluorite_examples_demo/main.dart';
import 'package:fluorite_examples_demo/shape_and_object_creators.dart';

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
              widget.filament.queueFrameTask(widget.filament.toggleShapesInScene(_toggleShapes));
            });
          },
          child: Text(_toggleShapes ? 'Toggle Shapes: On' : 'Toggle Shapes: Off'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.filament.queueFrameTask(
                widget.filament.toggleDebugCollidableViewsInScene(_toggleColliderVisuals),
              );
              _toggleColliderVisuals = !_toggleColliderVisuals;
            });
          },
          child: Text(_toggleColliderVisuals ? 'Toggle Colliders: On' : 'Toggle Colliders: Off'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _quality = (_quality + 1) % 5; // Cycle through 0-4
              widget.filament.queueFrameTask(widget.filament.changeViewQualitySettings());
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

                  widget.filament.queueFrameTask(
                    widget.filament.changeLightColorByGUID(
                      centerPointLightGUID,
                      colorString,
                      _directIntensity.toInt(),
                    ),
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

                      widget.filament.queueFrameTask(
                        widget.filament.changeLightColorByGUID(
                          centerPointLightGUID,
                          colorString,
                          _directIntensity.toInt(),
                        ),
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
  static int expectedFPS = 60; // Expected FPS for the graph
  double get expectedFrameTime => 1000.0 / expectedFPS; // Expected frame time in milliseconds

  late final ListQueue<double> _fpsHistory;
  late final ListQueue<double> _totHistory;
  late final ListQueue<double> _cpuHistory;
  late final ListQueue<double> _gpuHistory;
  late final ListQueue<double> _scpHistory;
  late final ListQueue<double> _sysHistory;

  double avgFPS = 0;
  // Average frametime in milliseconds
  double avgTot = 0, avgCPU = 0, avgGPU = 0, avgScp = 0, avgSys = 0;
  // Max deviance from average
  double maxDevFPS = 0, maxDevTot = 0, maxDevCPU = 0, maxDevGPU = 0, maxDevScp = 0, maxDevSys = 0;

  @override
  void initState() {
    super.initState();

    // Set the expected FPS to the maximum refresh rate found
    double maxRefreshRate = -1;
    for (var display in WidgetsBinding.instance.platformDispatcher.displays) {
      maxRefreshRate = max(maxRefreshRate, display.refreshRate);
    }

    expectedFPS = maxRefreshRate.round();

    // Recreate queues
    _fpsHistory = ListQueue<double>(expectedFPS);
    _totHistory = ListQueue<double>(expectedFPS);
    _cpuHistory = ListQueue<double>(expectedFPS);
    _gpuHistory = ListQueue<double>(expectedFPS);
    _scpHistory = ListQueue<double>(expectedFPS);
    _sysHistory = ListQueue<double>(expectedFPS);

    // Add listener for profiling changes
    widget.data.addListener(() async {
      setState(() {
        // ignore: unnecessary_null_comparison
        if (_fpsHistory == null) return;

        // Add new values to history
        _fpsHistory.add(widget.data.value.fps);
        _cpuHistory.add(widget.data.value.cpuFrameTime);
        _gpuHistory.add(widget.data.value.gpuFrameTime);
        _scpHistory.add(widget.data.value.scriptFrameTime);
        _totHistory.add(_cpuHistory.last + _gpuHistory.last + _scpHistory.last);
        _sysHistory.add(widget.data.value.deltaTime * 1000 - _totHistory.last);

        // Maintain only the last 60 values
        if (_fpsHistory.length > expectedFPS) _fpsHistory.removeFirst();
        if (_totHistory.length > expectedFPS) _totHistory.removeFirst();
        if (_cpuHistory.length > expectedFPS) _cpuHistory.removeFirst();
        if (_gpuHistory.length > expectedFPS) _gpuHistory.removeFirst();
        if (_scpHistory.length > expectedFPS) _scpHistory.removeFirst();
        if (_sysHistory.length > expectedFPS) _sysHistory.removeFirst();

        // Update averages
        avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
        avgTot = _totHistory.reduce((a, b) => a + b) / _totHistory.length;
        avgCPU = _cpuHistory.reduce((a, b) => a + b) / _cpuHistory.length;
        avgGPU = _gpuHistory.reduce((a, b) => a + b) / _gpuHistory.length;
        avgScp = _scpHistory.reduce((a, b) => a + b) / _scpHistory.length;
        avgSys = _sysHistory.reduce((a, b) => a + b) / _sysHistory.length;

        // Update max deviance
        maxDevFPS = _fpsHistory.map((e) => (e - avgFPS).abs()).reduce(max);
        maxDevTot = _totHistory.map((e) => (e - avgTot).abs()).reduce(max);
        maxDevCPU = _cpuHistory.map((e) => (e - avgCPU).abs()).reduce(max);
        maxDevGPU = _gpuHistory.map((e) => (e - avgGPU).abs()).reduce(max);
        maxDevScp = _scpHistory.map((e) => (e - avgScp).abs()).reduce(max);
        maxDevSys = _sysHistory.map((e) => (e - avgSys).abs()).reduce(max);
      });
    });
  }

  static const double kPerfBarWidth = 2; // Width of each bar in the graph
  static const double kPerfBarHeight = 64; // Height of the graph
  static const double kPerfBarSpacing = 1; // Spacing between bars

  double get perfGraphWidth => expectedFPS * (kPerfBarWidth + kPerfBarSpacing);

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
        // ignore: unnecessary_null_comparison
        children: _fpsHistory == null
            ? <Widget>[
                const Text(
                  'Loading profiling data...',
                  style: TextStyle(fontFamily: 'Galmuri9', fontSize: 10, color: Colors.white),
                ),
              ]
            : [
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
                  'FPS: ${_fpsHistory.lastOrNull?.round() ?? 0} / $expectedFPS (±${maxDevFPS.toStringAsFixed(1)})\n'
                  '\n'
                  'Frametime: ${avgTot.toStringAsFixed(2)} ms (±${maxDevTot.toStringAsFixed(2)})\n'
                  'CPU      : ${avgCPU.toStringAsFixed(2)} ms (±${maxDevCPU.toStringAsFixed(2)})\n'
                  'GPU      : ${avgGPU.toStringAsFixed(2)} ms (±${maxDevGPU.toStringAsFixed(2)})\n'
                  'Script   : ${avgScp.toStringAsFixed(2)} ms (±${maxDevScp.toStringAsFixed(2)})',
                  style: const TextStyle(
                    fontFamily: 'Galmuri9', //
                    fontSize: 10, //
                    color: Colors.white, //
                  ),
                ),
                const SizedBox(height: 8),
                // white line
                SizedBox(
                  height: 1,
                  width: perfGraphWidth,
                  child: const ColoredBox(color: Colors.white),
                ),
                SizedBox(
                  height: kPerfBarHeight,
                  width: perfGraphWidth,
                  child: Stack(
                    alignment: Alignment.topLeft,
                    fit: StackFit.passthrough,
                    children: [
                      // Combined frametime bar chart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: (() {
                          final bars = <Widget>[];

                          for (int i = 0; i < _fpsHistory.length; i++) {
                            final double value = (_totHistory.elementAt(i)) / expectedFrameTime;

                            final sysDelay =
                                (_sysHistory.elementAt(i) - 1) >
                                (expectedFrameTime - _totHistory.elementAt(i));

                            bars.add(
                              Container(
                                key: ValueKey('perf_bar_$i'),
                                width: kPerfBarWidth,
                                height: kPerfBarHeight * min(value, 1),
                                margin: const EdgeInsets.only(right: 1),
                                color: // dart format off
                                  // Red if value > 1
                                  value > 1 ? Colors.red :
                                  // Orange if sysDelay
                                  sysDelay ? Colors.orangeAccent :
                                  // Yellow if value > 0.5
                                  value > 0.5 ? Colors.yellow :
                                  // Green otherwise
                                  Colors.green,
                                // dart format on
                              ),
                            );
                          }

                          return bars;
                        })(),
                      ),
                      // Chart labels
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // (100% marker)
                          Text(
                            "${expectedFrameTime.toStringAsFixed(1)}ms",
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
                          SizedBox(
                            height: 1,
                            width: perfGraphWidth,
                            child: const ColoredBox(color: kColorTransparentWhite),
                          ),
                          // (50% marker)
                          Text(
                            "${(expectedFrameTime / 2).toStringAsFixed(1)}ms",
                            style: const TextStyle(
                              fontFamily: 'Galmuri7',
                              fontSize: 8,
                              height: 1,
                              color: kColorTransparentWhite,
                            ),
                          ),
                          // spacing height / 2 - 8
                          const SizedBox(height: kPerfBarHeight / 2 - 8 - 8 - 1),
                          // (0% marker)
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
                SizedBox(
                  height: 1,
                  width: perfGraphWidth,
                  child: const ColoredBox(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'System delay: ${avgSys.toStringAsFixed(2)} ms (±${maxDevSys.toStringAsFixed(2)})',
                  style: TextStyle(
                    fontFamily: 'Galmuri9',
                    fontSize: 10,
                    // Glow red if delay causes low FPS
                    // dart format off
                    color:
                        ((_sysHistory.lastOrNull ?? 0) - 1) >
                        (expectedFrameTime - (_totHistory.lastOrNull ?? 0))
                          ? Colors.orangeAccent
                          : Colors.white,
                    // dart format on
                  ),
                ),
              ],
      ),
    ),
  );
}
