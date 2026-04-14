// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Cinematic media library — matches the player chrome (deep black,
// warm gold accent).

import 'package:flutter/material.dart';

const Color _kAccent = Color(0xFFC4A26E);
const Color _kCanvas = Color(0xFF0A0A0C);
const Color _kCard = Color(0xCC141418);
const Color _kCardHover = Color(0xEE1C1C22);
const Color _kBorder = Color(0x22FFFFFF);
const Color _kBorderHot = Color(0x55C4A26E);
const Color _kMuted = Color(0x99FFFFFF);
const Color _kFaint = Color(0x44FFFFFF);

enum MediaSource { network, asset }

class MediaItem {
  MediaItem({
    required this.name,
    required this.url,
    this.source = MediaSource.network,
  });

  String name;
  String url;
  MediaSource source;

  MediaItem copy() => MediaItem(name: name, url: url, source: source);
}

final List<MediaItem> _defaultLibrary = [
  MediaItem(
    name: 'Big Buck Bunny',
    url:
        'https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4',
  ),
  MediaItem(
    name: 'Sintel Trailer (480p)',
    url: 'https://download.blender.org/durian/trailer/sintel_trailer-480p.mp4',
  ),
  MediaItem(
    name: 'Sintel Trailer (720p)',
    url: 'https://download.blender.org/durian/trailer/sintel_trailer-720p.mp4',
  ),
  MediaItem(
    name: 'Sintel Trailer (1080p)',
    url: 'https://download.blender.org/durian/trailer/sintel_trailer-1080p.mp4',
  ),
  MediaItem(
    name: 'Elephants Dream',
    url: 'https://archive.org/download/ElephantsDream/ed_1024_512kb.mp4',
  ),
  MediaItem(
    name: 'Bee (Flutter sample)',
    url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  ),
  MediaItem(
    name: 'Butterfly (Local Asset)',
    url: 'assets/Butterfly-209.mp4',
    source: MediaSource.asset,
  ),

  // ─── Audio-only test tracks ──────────────────────────────────────────
  //
  // The OGG Vorbis tracks below work with stock gst-plugins-base — no
  // extra codec install required. The MP3 tracks need an MP3 decoder
  // (gst-libav on Fedora: `sudo dnf install gstreamer1-libav`; verify
  // with `gst-inspect-1.0 avdec_mp3`).

  // Real-music Vorbis sample — longer playback for transport / EQ testing.
  MediaItem(
    name: 'Bach · BWV 543 Fugue (Vorbis)',
    url:
        'https://upload.wikimedia.org/wikipedia/commons/4/4e/BWV_543-fugue.ogg',
  ),
  // Longer MP3 — exercises seek / progress over a multi-MB file.
  MediaItem(
    name: 'SoundHelix Song 1 (MP3)',
    url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  ),
  // Live HTTP audio stream — unknown duration, no preroll seek.
  MediaItem(
    name: 'SomaFM · Groove Salad (MP3 live stream)',
    url: 'https://ice1.somafm.com/groovesalad-128-mp3',
  ),
  // KEXP Seattle — AAC stream (no gst-libav required, AAC ships in
  // gst-plugins-bad which is already pulled in by playbin).
  MediaItem(
    name: 'KEXP Seattle (AAC live stream)',
    url: 'https://kexp.streamguys1.com/kexp160.aac',
  ),
  // KEXP Seattle — MP3 fallback (needs gst-libav).
  MediaItem(
    name: 'KEXP Seattle (MP3 live stream)',
    url: 'https://kexp-mp3-128.streamguys1.com/kexp128.mp3',
  ),
];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.onPlay});

  final void Function(MediaItem item) onPlay;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final List<MediaItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _defaultLibrary.map((e) => e.copy()).toList();
  }

  void _addItem() {
    setState(() {
      _items.add(MediaItem(name: 'New Video', url: ''));
    });
    _editItem(_items.length - 1);
  }

  void _editItem(int index) {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final urlCtrl = TextEditingController(text: item.url);
    var source = item.source;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Theme(
          data: _dialogTheme(context),
          child: AlertDialog(
            backgroundColor: _kCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _kBorder),
            ),
            title: const Text(
              'Edit Media',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: _inputDecoration(
                      source == MediaSource.asset ? 'Asset Path' : 'URL',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SourceToggle(
                    selected: source,
                    onChanged: (s) => setDialogState(() => source = s),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: _kMuted)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    item.name = nameCtrl.text;
                    item.url = urlCtrl.text;
                    item.source = source;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  ThemeData _dialogTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      dialogTheme: const DialogThemeData(backgroundColor: _kCard),
      colorScheme: base.colorScheme.copyWith(
        primary: _kAccent,
        surface: _kCard,
        onSurface: Colors.white,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _kMuted),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCanvas,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LIBRARY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                        color: _kAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_items.length} item${_items.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              _AddButton(onPressed: _addItem),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _MediaCard(
                  item: item,
                  onPlay:
                      item.url.isNotEmpty ? () => widget.onPlay(item) : null,
                  onEdit: () => _editItem(index),
                  onDelete: () => _deleteItem(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Media card ───────────────────────────

class _MediaCard extends StatefulWidget {
  const _MediaCard({
    required this.item,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });
  final MediaItem item;
  final VoidCallback? onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isAsset = widget.item.source == MediaSource.asset;
    final disabled = widget.onPlay == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPlay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: _hovering ? _kCardHover : _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovering ? _kBorderHot : _kBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Source-icon medallion
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kAccent.withValues(alpha: _hovering ? 0.18 : 0.10),
                  border: Border.all(
                    color: _kAccent.withValues(alpha: _hovering ? 0.6 : 0.3),
                  ),
                ),
                child: Icon(
                  isAsset ? Icons.folder_rounded : Icons.cloud_outlined,
                  color: _kAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              // Title + URL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.item.url.isEmpty ? '—' : widget.item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Hover-only edit/delete actions
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: _hovering ? 1.0 : 0.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CardIcon(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                    _CardIcon(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Play badge — gold pill, dim when disabled
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: disabled
                      ? Colors.transparent
                      : (_hovering
                          ? _kAccent
                          : _kAccent.withValues(alpha: 0.18)),
                  border: Border.all(
                    color: disabled ? _kFaint : _kAccent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow,
                      size: 16,
                      color: disabled
                          ? _kFaint
                          : (_hovering ? Colors.black : _kAccent),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Play',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: disabled
                            ? _kFaint
                            : (_hovering ? Colors.black : _kAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Atoms ───────────────────────────

class _CardIcon extends StatelessWidget {
  const _CardIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: _kMuted),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kAccent.withValues(alpha: 0.6)),
          color: _kAccent.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_rounded, size: 16, color: _kAccent),
            SizedBox(width: 6),
            Text(
              'Add Media',
              style: TextStyle(
                color: _kAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceToggle extends StatelessWidget {
  const _SourceToggle({required this.selected, required this.onChanged});
  final MediaSource selected;
  final ValueChanged<MediaSource> onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SourcePill(
            icon: Icons.cloud_outlined,
            label: 'Network',
            selected: selected == MediaSource.network,
            onTap: () => onChanged(MediaSource.network),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SourcePill(
            icon: Icons.folder_rounded,
            label: 'Local Asset',
            selected: selected == MediaSource.asset,
            onTap: () => onChanged(MediaSource.asset),
          ),
        ),
      ],
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({
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
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? _kAccent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: selected ? _kAccent : _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? _kAccent : Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _kAccent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
