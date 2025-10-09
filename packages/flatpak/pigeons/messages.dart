/*
 * Copyright 2024 Toyota Connected North America
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  cppHeaderOut: 'messages.g.h',
  cppSourceOut: 'messages.g.cc',
  cppOptions: CppOptions(
    namespace: 'flatpak_plugin',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
))
class Remote {
  final String name;
  final String url;
  final String collectionId;
  final String title;
  final String comment;
  final String description;
  final String homepage;
  final String icon;
  final String defaultBranch;
  final String mainRef;
  final String remoteType;
  final String filter;
  final String appstreamTimestamp;
  final String appstreamDir;

  final bool gpgVerify;
  final bool noEnumerate;
  final bool noDeps;
  final bool disabled;

  final int prio;

  Remote(
      {required this.name,
      required this.url,
      required this.collectionId,
      required this.title,
      required this.comment,
      required this.description,
      required this.homepage,
      required this.icon,
      required this.defaultBranch,
      required this.mainRef,
      required this.remoteType,
      required this.filter,
      required this.appstreamTimestamp,
      required this.appstreamDir,
      required this.gpgVerify,
      required this.noEnumerate,
      required this.noDeps,
      required this.disabled,
      required this.prio});
}

class Application {
  final String name;
  final String id;
  final String summary;
  final String version;
  final String origin;
  final String license;
  final int installedSize;
  final String deployDir;
  final bool isCurrent;
  final String contentRatingType;
  final Map<String?, Object?> contentRating;
  final String latestCommit;
  final String eol;
  final String eolRebase;
  final List<String> subpaths;
  final String metadata;
  final String appdata;

  Application({
    required this.name,
    required this.id,
    required this.summary,
    required this.version,
    required this.origin,
    required this.license,
    required this.installedSize,
    required this.deployDir,
    required this.isCurrent,
    required this.contentRatingType,
    required this.contentRating,
    required this.latestCommit,
    required this.eol,
    required this.eolRebase,
    required this.subpaths,
    required this.metadata,
    required this.appdata,
  });
}

class Installation {
  final String id;
  final String displayName;
  final String path;
  final bool noInteraction;
  final bool isUser;
  final int priority;
  List<String> defaultLanguages;
  List<String> defaultLocale;
  List<Remote> remotes;

  Installation({
    required this.id,
    required this.displayName,
    required this.path,
    required this.noInteraction,
    required this.isUser,
    required this.priority,
    required this.defaultLanguages,
    required this.defaultLocale,
    required this.remotes,
  });
}

@HostApi(dartHostTestHandler: 'TestHostFlatpakApi')
abstract class FlatpakApi {
  /// Get Flatpak version.
  String getVersion();

  /// Get the default flatpak arch
  String getDefaultArch();

  /// Get all arches supported by flatpak
  List<String?> getSupportedArches();

  /// Returns a list of Flatpak system installations.
  List<Installation> getSystemInstallations();

  /// Returns user flatpak installation.
  Installation getUserInstallation();

  /// Add a remote repository.
  bool remoteAdd(Remote configuration);

  /// Remove Remote configuration.
  bool remoteRemove(String id);

  /// Get a list of applications installed on machine.
  List<Application> getApplicationsInstalled();

  /// Get list of applications hosted on a remote.
  List<Application> getApplicationsRemote(String id);

  /// Install application of given id.
  bool applicationInstall(String id);

  /// Uninstall application with specified id.
  bool applicationUninstall(String id);

  /// Start application using specified configuration.
  bool applicationStart(String id);

  /// Stop application with given id.
  bool applicationStop(String id);
}