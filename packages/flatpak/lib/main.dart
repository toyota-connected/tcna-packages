import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:flatpak_flutter/src/oars_rating.dart';
import 'package:flutter/material.dart';
import 'package:ini/ini.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _version = "";
  String _defaultArch = "";
  List<String?> _supportedArches = List.empty();

  final api = FlatpakApi();

  void _printRemote(String tag, Remote remote) {
    if (tag.isNotEmpty) {
      print("\t[$tag]");
    }
    if (remote.name.isNotEmpty) {
      print("\tname: ${remote.name}");
    }
    if (remote.url.isNotEmpty) {
      print("\turl: ${remote.url}");
    }
    if (remote.collectionId.isNotEmpty) {
      print("\tcollectionId: ${remote.collectionId}");
    }
    if (remote.title.isNotEmpty) {
      print("\ttitle: ${remote.title}");
    }
    if (remote.comment.isNotEmpty) {
      print("\tcomment: ${remote.comment}");
    }
    if (remote.description.isNotEmpty) {
      print("\tdescription: ${remote.description}");
    }
    if (remote.homepage.isNotEmpty) {
      print("\thomepage: ${remote.homepage}");
    }
    if (remote.icon.isNotEmpty) {
      print("\ticon: ${remote.icon}");
    }
    if (remote.defaultBranch.isNotEmpty) {
      print("\tdefaultBranch: ${remote.defaultBranch}");
    }
    if (remote.mainRef.isNotEmpty) {
      print("\tmainRef: ${remote.mainRef}");
    }
    if (remote.remoteType.isNotEmpty) {
      print("\tremoteType: ${remote.remoteType}");
    }
    if (remote.filter.isNotEmpty) {
      print("\tfilter: ${remote.filter}");
    }

    final appstreamTimestamp = DateTime.parse(remote.appstreamTimestamp);
    print("\tappstreamTimestamp: $appstreamTimestamp");

    if (remote.appstreamDir.isNotEmpty) {
      print("\tappstreamDir: ${remote.appstreamDir}");
    }
    print("\tgpgVerify: ${remote.gpgVerify}");
    print("\tnoEnumerate: ${remote.noEnumerate}");
    print("\tnoDeps: ${remote.noDeps}");
    print("\tdisabled: ${remote.disabled}");
    print("\tprio: ${remote.prio}");
  }

  void _printInstallation(String tag, Installation installation) {
    if (tag.isNotEmpty) {
      print("[$tag]");
    }
    if (installation.id.isNotEmpty) {
      print("id: ${installation.id}");
    }
    if (installation.displayName.isNotEmpty) {
      print("display_name: ${installation.displayName}");
    }
    if (installation.path.isNotEmpty) {
      print("path: ${installation.path}");
    }
    print("noInteraction: ${installation.noInteraction}");
    print("isUser: ${installation.isUser}");
    print("priority: ${installation.priority}");
    for (String language in installation.defaultLanguages) {
      if (language.isNotEmpty) {
        print("language: $language");
      }
    }
    for (String locale in installation.defaultLocale) {
      if (locale.isNotEmpty) {
        print("locale: $locale");
      }
    }
    print("Remote Count: ${installation.remotes.length}");
    for (Remote remote in installation.remotes) {
      _printRemote("Remote", remote);
    }
  }

  String? _xPathQuery(XmlDocument document, String query) {
    final nodes = document.xpath(query);
    for (final node in nodes) {
      if (node.nodeType == XmlNodeType.ATTRIBUTE) {
        return node.value.toString();
      } else if (node.nodeType == XmlNodeType.ELEMENT) {
        return node.firstChild.toString();
      }
    }
    return null;
  }

  String? _getDesktopIdFilePath(String desktopId) {
    final environment = Platform.environment;
    if (!environment.containsKey("XDG_DATA_DIRS")) {
      print('XDG_DATA_DIRS is not set.');
      return null;
    }
    final xdgDataDirs = environment["XDG_DATA_DIRS"];
    if (xdgDataDirs != null) {
      final dirs = xdgDataDirs.split(":");
      for (String dir in dirs) {
        String path = "$dir/applications/$desktopId";
        if (File(path).existsSync()) {
          return path;
        }
      }
    }
    return null;
  }

  double _bytesToMib(int bytes) {
    const int bytesInMib = 1024 * 1024; // 1 MiB = 1024 * 1024 bytes
    return bytes / bytesInMib;
  }

  void _incrementCounter() async {
    _version = await api.getVersion();
    _defaultArch = await api.getDefaultArch();
    _supportedArches = await api.getSupportedArches();

    final systemInstallations = await api.getSystemInstallations();
    for (Installation installation in systemInstallations) {
      _printInstallation("System Installation", installation);
    }

    final installation = await api.getUserInstallation();
    _printInstallation("User Installation", installation);

    final applications = await api.getApplicationsInstalled();
    for (Application application in applications) {
      print("[Application]");
      print("name: ${application.name}");
      print("id: ${application.id}");
      print("summary: ${application.summary}");
      print("version: ${application.version}");
      print("origin: ${application.origin}");
      print("license: ${application.license}");
      print(
          "installed_size: ${_bytesToMib(application.installedSize).toStringAsFixed(2)} MiB");
      print("deploy_dir: ${application.deployDir}");
      print("is_current: ${application.isCurrent}");
      print("content_rating_type: ${application.contentRatingType}");
      if (application.contentRating.isNotEmpty) {
        Map<String, dynamic> ratingsMap = {
          for (var entry in application.contentRating.entries)
            if (entry.key != null) entry.key!: entry.value
        };
        if (application.contentRatingType == "oars-1.1") {
          final ratings = ContentRatingOarsOneDotOne.fromJson(ratingsMap);
          ratings.printRatings(application.contentRatingType);
        } else if (application.contentRatingType == "oars-1.0") {
          final ratings = ContentRatingOarsOneDotZero.fromJson(ratingsMap);
          ratings.printRatings(application.contentRatingType);
        }
      }
      print("latest_commit: ${application.latestCommit}");
      print("eol: ${application.eol}");
      print("eol_rebase: ${application.eolRebase}");
      for (String subpath in application.subpaths) {
        print("subpath: $subpath");
      }

      if (application.metadata.isNotEmpty) {
        final metaData = Config.fromStrings(application.metadata.split('\n'));
        print("metadata:");
        final sections = metaData.sections();
        for (String section in sections) {
          print("\tsection: $section");
        }
      }

      if (application.appdata.isNotEmpty) {
        final document = XmlDocument.parse(application.appdata);
        print("appdata");

        final origin = _xPathQuery(document, "//components[1]/@origin");
        final version = _xPathQuery(document, "//components[1]/@version");
        final type =
            _xPathQuery(document, "//components[1]/component[1]/@type");
        final id = _xPathQuery(document, "//components[1]/component[1]/id");
        final name =
            _xPathQuery(document, "//components[1]/component[1]/name[not(@*)]");
        final summary = _xPathQuery(
            document, "//components[1]/component[1]/summary[not(@*)]");
        final description = _xPathQuery(
            document, "//components[1]/component[1]/description[not(@*)]/p");

        final pkgname =
            _xPathQuery(document, "//components[1]/component[1]/pkgname");
        final sourcePkgname = _xPathQuery(
            document, "//components[1]/component[1]/source_pkgname");
        final projectLicense = _xPathQuery(
            document, "//components[1]/component[1]/project_license");

        if (origin != null && origin.isNotEmpty) {
          print("\torigin: $origin");
        }
        if (version != null && version.isNotEmpty) {
          print("\tversion: $version");
        }
        if (type != null && type.isNotEmpty) {
          print("\ttype: $type");
        }
        if (id != null && id.isNotEmpty) {
          print("\tid: $id");
        }
        if (name != null && name.isNotEmpty) {
          print("\tname: $name");
        }
        if (summary != null && summary.isNotEmpty) {
          print("\tsummary: $summary");
        }
        if (description != null && description.isNotEmpty) {
          print("\tdescription: $description");
        }
        if (pkgname != null && pkgname.isNotEmpty) {
          print("\tpkgname: $pkgname");
        }
        if (sourcePkgname != null && sourcePkgname.isNotEmpty) {
          print("\tsourcePkgname: $sourcePkgname");
        }
        if (projectLicense != null && projectLicense.isNotEmpty) {
          print("\tprojectLicense: $projectLicense");
        }

        if (type == "desktop" || type == "desktop-application") {
          final iconFile = _xPathQuery(document,
              "//components[1]/component[1]/icon[@type='cached' and @height='64' and @width='64']");
          final iconPath =
              "${application.deployDir}/files/share/app-info/icons/flatpak/64x64/${iconFile!}";
          if (File(iconPath).existsSync()) {
            print("\ticon: $iconPath");
          } else {
            print("Icon 64x64 file is missing.");
          }

          final desktopId = _xPathQuery(document,
              "//components[1]/component[1]/launchable[@type='desktop-id']");
          if (desktopId != null && desktopId.isNotEmpty) {
            final desktopIdFilePath = _getDesktopIdFilePath(desktopId);
            if (desktopIdFilePath != null && desktopIdFilePath.isNotEmpty) {
              print("\tlaunchable: $desktopIdFilePath");
              File(desktopIdFilePath)
                  .readAsLines()
                  .then((lines) => Config.fromStrings(lines))
                  .then((value) {
                final sections = value.sections();
                print("desktopId:");
                for (String section in sections) {
                  print("\tsection: $section");
                }
              });
            }
          }
          for (Installation installation in [installation, ...systemInstallations]) {
            for (Remote remote in installation.remotes) {
              if (!remote.disabled) {
                try {
                  final remoteApplications = await api.getApplicationsRemote(remote.name);
                  if (remoteApplications.isNotEmpty) {
                    print("\n[Remote Applications from ${remote.name}]");
                    print("Remote: ${remote.name} (${remote.url})");
                    print("Applications count: ${remoteApplications.length}");
                    
                    for (Application app in remoteApplications) {
                      print("\t[Remote Application]");
                      print("\tname: ${app.name}");
                      print("\tid: ${app.id}");
                      print("\tsummary: ${app.summary}");
                      print("\tversion: ${app.version}");
                      print("\torigin: ${app.origin}");
                      print("\tlicense: ${app.license}");
                      print("\tinstalled_size: ${_bytesToMib(app.installedSize).toStringAsFixed(2)} MiB");
                      print("\tdeploy_dir: ${app.deployDir}");
                      print("\tis_current: ${app.isCurrent}");
                      print("\tcontent_rating_type: ${app.contentRatingType}");
                      if (app.contentRating.isNotEmpty) {
                        print("\tcontent_rating: ${app.contentRating}");
                      }
                      print("\tlatest_commit: ${app.latestCommit}");
                      print("\teol: ${app.eol}");
                      print("\teol_rebase: ${app.eolRebase}");
                      for (String subpath in app.subpaths) {
                        print("\tsubpath: $subpath");
                      }
                      if (app.metadata.isNotEmpty) {
                        print("\tmetadata: ${app.metadata}");
                      }
                      if (app.appdata.isNotEmpty) {
                        print("\tappdata: ${app.appdata}");
                      }
                      print("");
                    }
                  }
                } catch (e) {
                  print("Error getting applications from remote ${remote.name}: $e");
                }
              }
            }
          }
        }
      }
    }

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Version:',
            ),
            Text(
              _version,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Text(
              'Default Arch:',
            ),
            Text(
              _defaultArch,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Text(
              'Supported Arches:',
            ),
            Text(
              _supportedArches.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
