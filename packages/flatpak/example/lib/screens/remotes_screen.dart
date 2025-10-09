import 'package:flutter/material.dart';
import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../services/flatpak_service.dart';

class RemotesScreen extends StatefulWidget {
  const RemotesScreen({super.key});

  @override
  State<RemotesScreen> createState() => _RemotesScreenState();
}

class _RemotesScreenState extends State<RemotesScreen> {
  final FlatpakService _flatpakService = FlatpakService();
  bool _isLoading = false;
  String _currentRemote = '';
  String _errorMessage = '';
  final List<String> _availableRemotes = [];
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _add_remote(Remote remote) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _flatpakService.remoteAdd(remote);
      setState(() {
        _currentRemote = remote.name;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add remote: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _remove_remote(String remoteName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _flatpakService.remoteRemove(remoteName);
      setState(() {
        if (_currentRemote == remoteName) {
          _currentRemote = '';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to remove remote: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Remotes Mangement',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity
      ),
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Remotes Management'),
        ),
        // TODO: Implement the remote management UI
        // maybe use a ListView to display the available remotes, add remote and remove remote buttons
      ),

    );
  }
}