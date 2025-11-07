import 'package:equatable/equatable.dart';
import 'package:flatpak_flutter/src/messages.g.dart' as pigeon;

class Remote extends Equatable {
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

  const Remote({
    required this.name,
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
    required this.prio,
  });

  @override
  List<Object?> get props => [name, url, collectionId];
}

class RemoteModel extends Remote {
  const RemoteModel({
    required super.name,
    required super.url,
    required super.collectionId,
    required super.title,
    required super.comment,
    required super.description,
    required super.homepage,
    required super.icon,
    required super.defaultBranch,
    required super.mainRef,
    required super.remoteType,
    required super.filter,
    required super.appstreamTimestamp,
    required super.appstreamDir,
    required super.gpgVerify,
    required super.noEnumerate,
    required super.noDeps,
    required super.disabled,
    required super.prio,
  });

  factory RemoteModel.fromPigeon(pigeon.Remote remote) {
    return RemoteModel(
      name: remote.name,
      url: remote.url,
      collectionId: remote.collectionId,
      title: remote.title,
      comment: remote.comment,
      description: remote.description,
      homepage: remote.homepage,
      icon: remote.icon,
      defaultBranch: remote.defaultBranch,
      mainRef: remote.mainRef,
      remoteType: remote.remoteType,
      filter: remote.filter,
      appstreamTimestamp: remote.appstreamTimestamp,
      appstreamDir: remote.appstreamDir,
      gpgVerify: remote.gpgVerify,
      noEnumerate: remote.noEnumerate,
      noDeps: remote.noDeps,
      disabled: remote.disabled,
      prio: remote.prio,
    );
  }

  pigeon.Remote toPigeon() {
    return pigeon.Remote(
      name: name,
      url: url,
      collectionId: collectionId,
      title: title,
      comment: comment,
      description: description,
      homepage: homepage,
      icon: icon,
      defaultBranch: defaultBranch,
      mainRef: mainRef,
      remoteType: remoteType,
      filter: filter,
      appstreamTimestamp: appstreamTimestamp,
      appstreamDir: appstreamDir,
      gpgVerify: gpgVerify,
      noEnumerate: noEnumerate,
      noDeps: noDeps,
      disabled: disabled,
      prio: prio,
    );
  }
}
