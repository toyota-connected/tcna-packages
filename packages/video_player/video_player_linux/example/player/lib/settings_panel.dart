// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Right slide-out tabbed settings drawer for the video_player_linux example.
//
// Design language:
//   • Deep black surface, warm gold accent (#c4a26e) on enabled features.
//   • Each feature is a Card whose header shows the on/off state at a
//     glance. Controls are revealed only when the feature is enabled —
//     panels stay short and uncluttered.
//   • Read-only / informational data lives at the bottom of each tab so
//     it never competes with active controls.
//   • Tabs that don't apply to the current media (Subtitles, Video for
//     audio-only sources) are hidden entirely.

import 'dart:ui';

import 'package:flutter/material.dart';

import 'mini_controller.dart';

const Color _kAccent = Color(0xFFC4A26E);
const Color _kSurface = Color(0xEE0E0E12);
const Color _kSurfaceCard = Color(0xCC1A1A20);
const Color _kBorder = Color(0x22FFFFFF);
const Color _kMuted = Color(0x99FFFFFF);

enum SettingsTab { audio, subtitles, video, network }

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.controller,
    required this.onClose,
    this.initialTab = SettingsTab.audio,
  });

  final MiniController controller;
  final VoidCallback onClose;
  final SettingsTab initialTab;

  static const double width = 420;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late SettingsTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  List<SettingsTab> _availableTabs() {
    final ctrl = widget.controller;
    return [
      SettingsTab.audio,
      if (!ctrl.isAudioOnly) SettingsTab.subtitles,
      if (!ctrl.isAudioOnly) SettingsTab.video,
      SettingsTab.network,
    ];
  }

  IconData _icon(SettingsTab t) {
    switch (t) {
      case SettingsTab.audio:
        return Icons.graphic_eq_rounded;
      case SettingsTab.subtitles:
        return Icons.closed_caption_rounded;
      case SettingsTab.video:
        return Icons.tune_rounded;
      case SettingsTab.network:
        return Icons.cell_tower_rounded;
    }
  }

  String _label(SettingsTab t) {
    switch (t) {
      case SettingsTab.audio:
        return 'Audio';
      case SettingsTab.subtitles:
        return 'Subtitles';
      case SettingsTab.video:
        return 'Picture';
      case SettingsTab.network:
        return 'Stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _availableTabs();
    if (!tabs.contains(_tab)) _tab = tabs.first;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => Container(
            width: SettingsPanel.width,
            color: _kSurface,
            child: Theme(
              data: _panelTheme(context),
              child: Column(
                children: [
                  _buildHeader(context, tabs),
                  const Divider(height: 1, color: _kBorder),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: SingleChildScrollView(
                        key: ValueKey(_tab),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: _buildTab(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _panelTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: _kAccent,
        secondary: _kAccent,
        surface: _kSurface,
        onSurface: Colors.white,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: _kAccent,
        thumbColor: _kAccent,
        inactiveTrackColor: Color(0x33FFFFFF),
        overlayColor: Color(0x33C4A26E),
        trackHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? _kAccent : Colors.white70,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? _kAccent.withValues(alpha: 0.4)
              : const Color(0x33FFFFFF),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<SettingsTab> tabs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: _kAccent,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: widget.onClose,
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final t in tabs)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TabButton(
                    icon: _icon(t),
                    label: _label(t),
                    selected: _tab == t,
                    onTap: () => setState(() => _tab = t),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context) {
    switch (_tab) {
      case SettingsTab.audio:
        return _AudioTab(controller: widget.controller);
      case SettingsTab.subtitles:
        return _SubtitlesTab(controller: widget.controller);
      case SettingsTab.video:
        return _VideoTab(controller: widget.controller);
      case SettingsTab.network:
        return _NetworkTab(controller: widget.controller);
    }
  }
}

// ─────────────────────────── Tab button ───────────────────────────

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kAccent : _kBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: selected ? _kAccent : _kMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _kAccent : _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── AUDIO TAB ───────────────────────────

class _AudioTab extends StatelessWidget {
  const _AudioTab({required this.controller});
  final MiniController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audio track — only when more than one is available.
        if (c.audioTrackCount > 1) ...[
          _SectionLabel('Track'),
          _Card(
            child: Column(
              children: [
                for (int i = 0; i < c.audioTrackCount; i++)
                  _RadioRow(
                    title: 'Track ${i + 1}',
                    selected: false, // current-track not exposed yet
                    onTap: () => c.setAudioTrack(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        _SectionLabel('Output'),
        _Card(
          child: Column(
            children: [
              _SegmentedRow<int>(
                label: 'Channels',
                value: c.audioChannels ?? 2,
                segments: const {
                  1: 'Mono',
                  2: 'Stereo',
                  6: '5.1',
                  8: '7.1',
                },
                onChanged: c.setOutputChannels,
              ),
              const _CardDivider(),
              _SwitchRow(
                title: 'Mute',
                value: c.muted,
                onChanged: c.setMute,
              ),
              const _CardDivider(),
              _SwitchRow(
                title: 'HDMI Passthrough',
                subtitle: 'Bitstream AC3/DTS to external decoder',
                value: c.passthrough,
                onChanged: c.setAudioPassthrough,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        _SectionLabel('Channel Mix'),
        _MixPresetCard(controller: c),
        const SizedBox(height: 18),

        _ToggleableSection(
          label: 'Equalizer',
          enabled: c.equalizerBands.any((b) => b != 0),
          onToggle: (enable) {
            if (enable) {
              c.setEqualizer(List<double>.filled(10, 0.0));
            } else {
              c.setEqualizer(List<double>.filled(10, 0.0));
            }
          },
          summary: c.equalizerBands.any((b) => b != 0) ? 'Custom' : 'Flat',
          child: _Equalizer(controller: c),
        ),
        const SizedBox(height: 18),

        _AVOffsetCard(controller: c),
      ],
    );
  }
}

class _MixPresetCard extends StatefulWidget {
  const _MixPresetCard({required this.controller});
  final MiniController controller;
  @override
  State<_MixPresetCard> createState() => _MixPresetCardState();
}

class _MixPresetCardState extends State<_MixPresetCard> {
  String _current = 'stereo';
  static const _presets = <String, String>{
    'stereo': 'Stereo',
    'driver': 'Driver Focus',
    'night': 'Night',
    'rear': 'Rear Cabin',
    'surround': 'Surround Pass',
  };

  static const _descriptions = <String, String>{
    'stereo': 'ITU-R BS.775 standard downmix',
    'driver': 'Boosted dialog for the driver seat',
    'night': 'Reduced dynamic range for late listening',
    'rear': 'Optimised for rear-cabin speakers',
    'surround': 'Pass through to a 5.1 amplifier',
  };

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              _descriptions[_current]!,
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in _presets.entries)
                  _Chip(
                    label: entry.value,
                    selected: entry.key == _current,
                    onTap: () {
                      setState(() => _current = entry.key);
                      widget.controller.setChannelMixPreset(entry.key);
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

class _Equalizer extends StatefulWidget {
  const _Equalizer({required this.controller});
  final MiniController controller;
  @override
  State<_Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<_Equalizer> {
  static const _labels = [
    '29', '60', '120', '240', '470',
    '950', '1.9k', '3.8k', '7.5k', '14k',
  ];

  void _setBand(int i, double v) {
    final next = List<double>.from(widget.controller.equalizerBands);
    next[i] = v;
    widget.controller.setEqualizer(next);
  }

  @override
  Widget build(BuildContext context) {
    final bands = widget.controller.equalizerBands;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < 10; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          bands[i] == 0
                              ? '0'
                              : '${bands[i] > 0 ? '+' : ''}${bands[i].toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: bands[i] == 0 ? _kMuted : _kAccent,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                              ),
                              child: Slider(
                                value: bands[i],
                                min: -24,
                                max: 12,
                                onChanged: (v) => _setBand(i, v),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final l in _labels)
                Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: _kMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reset', style: TextStyle(fontSize: 12)),
              onPressed: () =>
                  widget.controller.setEqualizer(List<double>.filled(10, 0.0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AVOffsetCard extends StatefulWidget {
  const _AVOffsetCard({required this.controller});
  final MiniController controller;
  @override
  State<_AVOffsetCard> createState() => _AVOffsetCardState();
}

class _AVOffsetCardState extends State<_AVOffsetCard> {
  double _ms = 0;

  @override
  Widget build(BuildContext context) {
    final on = _ms != 0;
    return _ToggleableSection(
      label: 'A/V Sync Offset',
      enabled: on,
      summary: '${_ms.toInt()} ms',
      onToggle: (e) {
        if (!e) {
          setState(() => _ms = 0);
          widget.controller.setAVOffset(0);
        } else {
          // Nudge to a tiny value so the slider is visible.
          setState(() => _ms = 10);
          widget.controller.setAVOffset(10);
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                const Text('−500', style: TextStyle(color: _kMuted, fontSize: 10)),
                Expanded(
                  child: Slider(
                    value: _ms,
                    min: -500,
                    max: 500,
                    divisions: 100,
                    onChanged: (v) => setState(() => _ms = v),
                    onChangeEnd: (v) =>
                        widget.controller.setAVOffset(v.toInt()),
                  ),
                ),
                const Text('+500', style: TextStyle(color: _kMuted, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Compensate for Bluetooth or external DAC latency',
              style: TextStyle(color: _kMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── SUBTITLES TAB ───────────────────────────

class _SubtitlesTab extends StatefulWidget {
  const _SubtitlesTab({required this.controller});
  final MiniController controller;
  @override
  State<_SubtitlesTab> createState() => _SubtitlesTabState();
}

class _SubtitlesTabState extends State<_SubtitlesTab> {
  bool _enabled = false;
  int _trackCount = 0;
  int? _currentTrack;
  String _font = 'Sans 18';
  bool _showExternal = false;
  final TextEditingController _uri = TextEditingController();
  final TextEditingController _fontCtrl =
      TextEditingController(text: 'Sans 18');

  @override
  void initState() {
    super.initState();
    widget.controller.subtitleTrackCount().then((n) {
      if (mounted) setState(() => _trackCount = n);
    });
  }

  @override
  void dispose() {
    _uri.dispose();
    _fontCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ToggleableSection(
          label: 'Subtitles',
          enabled: _enabled,
          summary: _enabled
              ? (_trackCount > 0 ? '$_trackCount track${_trackCount == 1 ? '' : 's'}' : 'On')
              : 'Off',
          onToggle: (v) {
            setState(() => _enabled = v);
            widget.controller.setSubtitlesEnabled(v);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_trackCount == 0)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Text(
                      'No embedded subtitle tracks.\nAdd an external file below.',
                      style: TextStyle(color: _kMuted, fontSize: 12),
                    ),
                  )
                else
                  for (int i = 0; i < _trackCount; i++)
                    _RadioRow(
                      title: 'Track ${i + 1}',
                      selected: _currentTrack == i,
                      onTap: () {
                        setState(() => _currentTrack = i);
                        widget.controller.setSubtitleTrack(i);
                      },
                    ),
                const _CardDivider(),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  title: const Text('Font',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  trailing: Text(_font,
                      style: const TextStyle(color: _kMuted, fontSize: 12)),
                  onTap: () => _showFontEditor(context),
                ),
                ListTile(
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  leading: const Icon(Icons.attach_file_rounded,
                      size: 16, color: _kMuted),
                  title: const Text('External file',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  trailing: Icon(
                    _showExternal ? Icons.expand_less : Icons.expand_more,
                    color: _kMuted,
                  ),
                  onTap: () => setState(() => _showExternal = !_showExternal),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _showExternal
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                    child: TextField(
                      controller: _uri,
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'file:///path/to/subs.srt',
                        hintStyle:
                            TextStyle(color: _kMuted, fontFamily: 'monospace'),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: widget.controller.setSubtitleUri,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFontEditor(BuildContext context) async {
    final next = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kSurface,
        title: const Text('Subtitle Font', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _fontCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Sans Bold 18',
            hintStyle: TextStyle(color: _kMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_fontCtrl.text),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    if (next != null && next.isNotEmpty) {
      setState(() => _font = next);
      widget.controller.setSubtitleFont(next);
    }
  }
}

// ─────────────────────────── VIDEO TAB ───────────────────────────

class _VideoTab extends StatefulWidget {
  const _VideoTab({required this.controller});
  final MiniController controller;
  @override
  State<_VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends State<_VideoTab> {
  int _scale = 1;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final isCustom = c.videoBrightness != 0 ||
        c.videoContrast != 1 ||
        c.videoSaturation != 1 ||
        c.videoHue != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Scaling'),
        _Card(
          child: _SegmentedRow<int>(
            label: 'Quality',
            value: _scale,
            segments: const {
              0: 'Fast',
              1: 'Bilinear',
              4: 'Lanczos',
            },
            onChanged: (v) {
              setState(() => _scale = v);
              c.setScaleMethod(v);
            },
          ),
        ),
        const SizedBox(height: 18),
        _ToggleableSection(
          label: 'Image Adjustments',
          enabled: isCustom,
          summary: isCustom ? 'Custom' : 'Default',
          onToggle: (e) {
            if (e) {
              // tiny nudge so user sees it's "on"
              c.setVideoBalance(brightness: 0.01);
            } else {
              c.setVideoBalance(
                  brightness: 0, contrast: 1, saturation: 1, hue: 0);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              children: [
                _BalanceSlider(
                  label: 'Brightness',
                  icon: Icons.brightness_6_rounded,
                  value: c.videoBrightness,
                  min: -1,
                  max: 1,
                  identity: 0,
                  onChanged: (v) => c.setVideoBalance(brightness: v),
                ),
                _BalanceSlider(
                  label: 'Contrast',
                  icon: Icons.contrast_rounded,
                  value: c.videoContrast,
                  min: 0,
                  max: 2,
                  identity: 1,
                  onChanged: (v) => c.setVideoBalance(contrast: v),
                ),
                _BalanceSlider(
                  label: 'Saturation',
                  icon: Icons.palette_rounded,
                  value: c.videoSaturation,
                  min: 0,
                  max: 2,
                  identity: 1,
                  onChanged: (v) => c.setVideoBalance(saturation: v),
                ),
                _BalanceSlider(
                  label: 'Hue',
                  icon: Icons.colorize_rounded,
                  value: c.videoHue,
                  min: -1,
                  max: 1,
                  identity: 0,
                  onChanged: (v) => c.setVideoBalance(hue: v),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    onPressed: () => c.setVideoBalance(
                        brightness: 0, contrast: 1, saturation: 1, hue: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceSlider extends StatelessWidget {
  const _BalanceSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.identity,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final double identity;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final modified = (value - identity).abs() > 0.001;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: modified ? _kAccent : _kMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: modified ? Colors.white : _kMuted,
                )),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── NETWORK TAB ───────────────────────────

class _NetworkTab extends StatelessWidget {
  const _NetworkTab({required this.controller});
  final MiniController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Now Playing'),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.title != null)
                  Text(
                    c.title!,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                if (c.artist != null) ...[
                  const SizedBox(height: 2),
                  Text(c.artist!,
                      style: const TextStyle(color: _kMuted, fontSize: 12)),
                ],
                if (c.album != null) ...[
                  const SizedBox(height: 2),
                  Text(c.album!,
                      style: const TextStyle(color: _kMuted, fontSize: 12)),
                ],
                if (c.title == null && c.artist == null && c.album == null)
                  const Text('—',
                      style: TextStyle(color: _kMuted, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _SectionLabel('Stream'),
        _Card(
          child: Column(
            children: [
              _InfoRow('Codec', c.audioCodec ?? '—'),
              const _CardDivider(),
              _InfoRow('Channels', _channelsLabel(c.audioChannels)),
              const _CardDivider(),
              _InfoRow(
                'Sample rate',
                c.audioSampleRate != null
                    ? '${(c.audioSampleRate! / 1000).toStringAsFixed(1)} kHz'
                    : '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionLabel('Source'),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              c.dataSource,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: _kMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: _kMuted),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Network tuning is configured at deployment time via '
                  'VIDEO_PLAYER_* environment variables.',
                  style: TextStyle(color: _kMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _channelsLabel(int? n) {
    if (n == null) return '—';
    switch (n) {
      case 1:
        return 'Mono';
      case 2:
        return 'Stereo';
      case 6:
        return '5.1';
      case 8:
        return '7.1';
      default:
        return '$n ch';
    }
  }
}

// ─────────────────────────── Shared atoms ───────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: _kAccent,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: _kBorder);
}

/// A card with a built-in master toggle. Children are revealed only when
/// `enabled` is true. The header always shows `summary` text on the right
/// so the user can see the current state at a glance.
class _ToggleableSection extends StatelessWidget {
  const _ToggleableSection({
    required this.label,
    required this.enabled,
    required this.summary,
    required this.onToggle,
    required this.child,
  });

  final String label;
  final bool enabled;
  final String summary;
  final ValueChanged<bool> onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? _kAccent.withValues(alpha: 0.5) : _kBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggle(!enabled),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: TextStyle(
                            fontSize: 11,
                            color: enabled ? _kAccent : _kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: enabled, onChanged: onToggle),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: enabled
                ? Column(
                    children: [
                      const _CardDivider(),
                      child,
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 13, color: Colors.white)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 11, color: _kMuted)),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.segments,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> segments;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in segments.entries)
                _Chip(
                  label: entry.value,
                  selected: entry.key == value,
                  onTap: () => onChanged(entry.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? _kAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _kAccent : _kBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? _kAccent : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: selected ? _kAccent : _kMuted,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : Colors.white70,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(color: _kMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
