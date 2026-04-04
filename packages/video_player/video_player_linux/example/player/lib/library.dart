import 'package:flutter/material.dart';

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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Media'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlCtrl,
                  decoration: InputDecoration(
                    labelText:
                        source == MediaSource.asset ? 'Asset Path' : 'URL',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<MediaSource>(
                  segments: const [
                    ButtonSegment(
                      value: MediaSource.network,
                      label: Text('Network'),
                      icon: Icon(Icons.cloud),
                    ),
                    ButtonSegment(
                      value: MediaSource.asset,
                      label: Text('Local Asset'),
                      icon: Icon(Icons.folder),
                    ),
                  ],
                  selected: {source},
                  onSelectionChanged: (sel) {
                    setDialogState(() => source = sel.first);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
    );
  }

  void _deleteItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Media Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Media'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Icon(
                        item.source == MediaSource.asset
                            ? Icons.folder
                            : Icons.cloud,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _deleteItem(index),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: item.url.isNotEmpty
                              ? () => widget.onPlay(item)
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
