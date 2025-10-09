import 'package:flutter/material.dart';
import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:provider/provider.dart';
import '../services/AppProvider.dart';
import '../services/flatpak_service.dart';
import '../widgets/appscreen_content.dart';
import '../widgets/appscreen_head.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key,required this.application,});
  final Application application;



  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final FlatpakService _flatpakService = FlatpakService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appsInit();
    });
  }

  Future<void> _appsInit() async{
    final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
    final appsProvider = Provider.of<AppsProvider>(context, listen: false);
    appStateProvider.clearError();
    appStateProvider.setInitialize(true);
    if (appsProvider.availableRemotes.isEmpty) {
      await appsProvider.initialize();
    }
    await appsProvider.refreshInstallationStatus();
    appStateProvider.setInitialize(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppscreanHead(appname: widget.application.name,
      ) ,
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(24.0),
        child: Container(
            child: AppscreenContent(app: widget.application,),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}