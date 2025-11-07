import 'package:equatable/equatable.dart';
import 'package:flatpak_flutter_example/data/models/remote_model.dart';
import 'package:flatpak_flutter/src/messages.g.dart' as pigeon;

class Installation extends Equatable {
  final String id;
  final String displayName;
  final String path;
  final bool noInteraction;
  final bool isUser;
  final int priority;
  final List<String> defaultLanguages;
  final List<String> defaultLocale;
  final List<Remote> remotes;

  const Installation({
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

  @override
  List<Object?> get props => [id, path];
}

class InstallationModel extends Installation {
  const InstallationModel({
    required super.id,
    required super.displayName,
    required super.path,
    required super.noInteraction,
    required super.isUser,
    required super.priority,
    required super.defaultLanguages,
    required super.defaultLocale,
    required super.remotes,
  });

  factory InstallationModel.fromPigeon(pigeon.Installation installation) {
    return InstallationModel(
      id: installation.id,
      displayName: installation.displayName,
      path: installation.path,
      noInteraction: installation.noInteraction,
      isUser: installation.isUser,
      priority: installation.priority,
      defaultLanguages: List<String>.from(installation.defaultLanguages),
      defaultLocale: List<String>.from(installation.defaultLocale),
      remotes: installation.remotes
          .map((r) => RemoteModel.fromPigeon(r))
          .toList(),
    );
  }
}
