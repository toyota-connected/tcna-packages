# flatpak_flutter

Flatpak support for Flutter

## Getting Started

Build flutter-auto or ivi-homescreen with `-DBUILD_PLUGIN_FLATPAK=ON`.

### Using workspace automation

* Setup embedded flutter workspace using workspace-automation

* Setup environment using `source ./setup_env.sh`

* Navigate to project under the app folder

* Launch VS Code using `code .`

* Select `Run and Debug`

* In the drop down combo box select `flatpak_flutter (Flutter Toyota homescreen)`.

### Using CLion

* clone ivi-homescreen repo

* clone ivi-homescreen-plugins repo adjacent to ivi-homescreen repo/folder

* Navigate to ivi-homescreen folder
```
clion .
```

* Configure CMake options with
```
-DBUILD_PLUGIN_FLATPAK=ON
-DPLUGINS_DIR=/home/tcna/CLionProjects/ivi-homescreen-plugins
```

* Configure `ivi-homescreen` target with workspace-automation generated bundle folder
```
-b /home/tcna/workspace-automation/app/flatpak_flutter/.desktop-homescreen
```

* Select `ivi-homescreen` target, and click debug


## References
- [ivi-homescreen](https://github.com/toyota-connected/ivi-homescreen)
- [ivi-homescreen-plugins](https://github.com/toyota-connected/ivi-homescreen-plugins)
- [Workspace Automation](https://github.com/meta-flutter/workspace-automation)
