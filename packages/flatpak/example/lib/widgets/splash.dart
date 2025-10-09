import 'package:flatpak_flutter_example/services/AppProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../responsive.dart';
import 'navigation_menu.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late AnimationController _subtitleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeToGradientAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;

  static const Map<String, List<String>> categories = {
    'Popular Apps': [
      'org.mozilla.firefox',
      'com.google.Chrome',
      'com.visualstudio.code',
      'com.spotify.Client',
      'com.discordapp.Discord',
      'org.libreoffice.LibreOffice',
      'org.gimp.GIMP',
      'org.telegram.desktop',
      'org.videolan.VLC',
      'com.obsproject.Studio',
    ],
    'Productivity': [
      'org.libreoffice.LibreOffice',
      'com.wps.Office',
      'md.obsidian.Obsidian',
      'com.slack.Slack',
      'com.microsoft.Teams',
      'us.zoom.Zoom',
      'org.mozilla.Thunderbird',
      'org.gnome.Calendar',
    ],
    'Development': [
      'com.visualstudio.code',
      'org.gnome.Builder',
      'com.jetbrains.IntelliJ-IDEA-Community',
      'com.jetbrains.PyCharm-Community',
      'org.eclipse.Java',
      'org.gnome.TextEditor',
    ],
    'Graphics & Photography': [
      'org.blender.Blender',
      'org.krita.Krita',
      'org.shotcut.Shotcut',
      'org.gnome.design.Palette',
      'org.freecadweb.FreeCAD',
      'com.github.maoschanz.drawing',
    ],
    'Audio & Video': [
      'org.videolan.VLC',
      'com.obsproject.Studio',
      'org.audacityteam.Audacity',
      'com.spotify.Client',
      'org.gnome.Rhythmbox3',
      'fr.handbrake.ghb',
    ],
    'Gaming': [
      'com.valvesoftware.Steam',
      'com.discordapp.Discord',
      'org.mamedev.MAME',
      'org.DolphinEmu.dolphin-emu',
      'org.gnome.Chess',
      'org.supertux.SuperTux',
    ],
  };

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8,curve: Curves.easeInOut)));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6,curve: Curves.elasticOut)));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.fastEaseInToSlowEaseOut)));

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    ));

    _subtitleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeInOut,
    ));

    _fadeToGradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _splashInit();
    });

  }


  Future<void> _splashInit() async {
    try {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      final appsProvider = Provider.of<AppsProvider>(context, listen: false);

      appStateProvider.clearError();
      appStateProvider.setInitialize(true);
      _animationController.forward();

      await appsProvider.initialize();

      await Future.delayed(const Duration(seconds: 2));
      _subtitleController.forward();
      await _loadAllCategories(appsProvider);
      appStateProvider.setInitialize(false);
      await Future.delayed(const Duration(milliseconds: 500));
      await _fadeController.forward();


      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NavigationMenu()),
        );
      }

    } catch (e) {
      final appStateProvider = Provider.of<AppStateProvider>(context, listen: false);
      appStateProvider.setInitialize(false);
      appStateProvider.setError(e.toString());
    }
  }

  Future<void> _loadAllCategories(AppsProvider appsProvider) async {
    for (final entry in categories.entries) {
      try {
        await appsProvider.loadCategoryApps(entry.key, entry.value);
      } catch (e) {
        print('Error loading category ${entry.key}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppStateProvider>(
          builder: (context, appStateProvider, child) {
            return Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _animationController,
                  _fadeController,
                ]),
                builder: (context,child) {
                  return Stack(
                    children:[
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[

                                  Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: SvgPicture.asset(
                                        'assets/logos/AGL.svg',
                                        width: 168,
                                        height: 36,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  SlideTransition(
                                    position: _slideAnimation,
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                              colors: [Color(0x00000000), Color(0xFF33D17A)],
                                              begin: Alignment.bottomRight,
                                              end: Alignment.topLeft,
                                            ).createShader(bounds),
                                        child: Text(
                                          'Store',
                                          style: TextStyle(
                                            fontSize: Responsive.scaleWithConstraints(
                                              context,
                                              40,
                                              minSize: 36,
                                              maxSize: 72,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,

                                            letterSpacing: -0.5,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                ],

                              ),

                              const SizedBox(height: 16),
                              AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _subtitleSlideAnimation,
                                    _subtitleFadeAnimation
                                  ]),
                                  builder: (context,child) {
                                    return SlideTransition(
                                        position: _subtitleSlideAnimation,
                                      child: Opacity(
                                          opacity:_subtitleFadeAnimation.value,
                                        child: Text(
                                          'AGL Store powered by Automotive Grade Linux',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black.withValues(alpha: 0.7),
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                              ),
                            ],
                          ),
                        ),
                    ),
                    Opacity(
                      opacity: _fadeToGradientAnimation.value,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: const BoxDecoration(
                        gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF070E20),
                          Color(0xFF1E3B86),
                          ],
                          ),
                          ),
                      ),
                    ),
                  ],
                  );
                }
              ),
            );
          },
        ),
    );
  }


  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }
}