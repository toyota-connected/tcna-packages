import 'package:equatable/equatable.dart';
import 'package:flatpak_flutter/src/messages.g.dart' as pigeon;

class Application extends Equatable {
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
  final Map<String, dynamic> contentRating;
  final String latestCommit;
  final String eol;
  final String eolRebase;
  final List<String> subpaths;
  final String metadata;
  final String appdata;

  const Application({
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

  String get shortId {
    if (id.startsWith('app/')) {
      final parts = id.split('/');
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    return id;
  }

  @override
  List<Object?> get props => [id];
}

class ApplicationModel extends Application {
  const ApplicationModel({
    required super.name,
    required super.id,
    required super.summary,
    required super.version,
    required super.origin,
    required super.license,
    required super.installedSize,
    required super.deployDir,
    required super.isCurrent,
    required super.contentRatingType,
    required super.contentRating,
    required super.latestCommit,
    required super.eol,
    required super.eolRebase,
    required super.subpaths,
    required super.metadata,
    required super.appdata,
  });

  factory ApplicationModel.fromPigeon(pigeon.Application app) {
    return ApplicationModel(
      name: app.name,
      id: app.id,
      summary: app.summary,
      version: app.version,
      origin: app.origin,
      license: app.license,
      installedSize: app.installedSize,
      deployDir: app.deployDir,
      isCurrent: app.isCurrent,
      contentRatingType: app.contentRatingType,
      contentRating: Map<String, dynamic>.from(app.contentRating),
      latestCommit: app.latestCommit,
      eol: app.eol,
      eolRebase: app.eolRebase,
      subpaths: List<String>.from(app.subpaths),
      metadata: app.metadata,
      appdata: app.appdata,
    );
  }
}
