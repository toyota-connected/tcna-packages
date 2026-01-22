import 'package:flutter/material.dart';

enum FlatpakPermission {
  camera,
  microphone,
  speakers,
  location,
  notifications,
  usb,
  background,
  filesystemHome,
  filesystemHost,
  filesystemDownloads,
  network,
  x11,
  wayland,
}

extension FlatpakPermissionExtension on FlatpakPermission {
  String get name {
    switch (this) {
      case FlatpakPermission.camera:
        return 'camera';
      case FlatpakPermission.microphone:
        return 'microphone';
      case FlatpakPermission.speakers:
        return 'speakers';
      case FlatpakPermission.location:
        return 'location';
      case FlatpakPermission.notifications:
        return 'notifications';
      case FlatpakPermission.usb:
        return 'usb';
      case FlatpakPermission.background:
        return 'background';
      case FlatpakPermission.filesystemHome:
        return 'filesystem_home';
      case FlatpakPermission.filesystemHost:
        return 'filesystem_host';
      case FlatpakPermission.filesystemDownloads:
        return 'filesystem_downloads';
      case FlatpakPermission.network:
        return 'network';
      case FlatpakPermission.x11:
        return 'x11';
      case FlatpakPermission.wayland:
        return 'wayland';
    }
  }

  String get displayName {
    switch (this) {
      case FlatpakPermission.camera:
        return 'Camera';
      case FlatpakPermission.microphone:
        return 'Microphone';
      case FlatpakPermission.speakers:
        return 'Speakers';
      case FlatpakPermission.location:
        return 'Location';
      case FlatpakPermission.notifications:
        return 'Notifications';
      case FlatpakPermission.usb:
        return 'USB Devices';
      case FlatpakPermission.background:
        return 'Background Activity';
      case FlatpakPermission.filesystemHome:
        return 'Home Folder';
      case FlatpakPermission.filesystemHost:
        return 'All Files';
      case FlatpakPermission.filesystemDownloads:
        return 'Downloads Folder';
      case FlatpakPermission.network:
        return 'Network Access';
      case FlatpakPermission.x11:
        return 'Display (X11)';
      case FlatpakPermission.wayland:
        return 'Display (Wayland)';
    }
  }

  String get description {
    switch (this) {
      case FlatpakPermission.camera:
        return 'Take photos and record videos';
      case FlatpakPermission.microphone:
        return 'Record audio';
      case FlatpakPermission.speakers:
        return 'Play audio';
      case FlatpakPermission.location:
        return 'Access your location';
      case FlatpakPermission.notifications:
        return 'Show notifications';
      case FlatpakPermission.usb:
        return 'Access USB devices';
      case FlatpakPermission.background:
        return 'Run in background';
      case FlatpakPermission.filesystemHome:
        return 'Access files in your home folder';
      case FlatpakPermission.filesystemHost:
        return 'Access all files on your computer';
      case FlatpakPermission.filesystemDownloads:
        return 'Access files in Downloads folder';
      case FlatpakPermission.network:
        return 'Connect to the internet';
      case FlatpakPermission.x11:
        return 'Display windows on screen';
      case FlatpakPermission.wayland:
        return 'Display windows on screen';
    }
  }

  IconData get icon {
    switch (this) {
      case FlatpakPermission.camera:
        return Icons.camera_alt;
      case FlatpakPermission.microphone:
        return Icons.mic;
      case FlatpakPermission.speakers:
        return Icons.volume_up;
      case FlatpakPermission.location:
        return Icons.location_on;
      case FlatpakPermission.notifications:
        return Icons.notifications;
      case FlatpakPermission.usb:
        return Icons.usb;
      case FlatpakPermission.background:
        return Icons.play_circle_outline;
      case FlatpakPermission.filesystemHome:
        return Icons.folder;
      case FlatpakPermission.filesystemHost:
        return Icons.folder_open;
      case FlatpakPermission.filesystemDownloads:
        return Icons.download;
      case FlatpakPermission.network:
        return Icons.wifi;
      case FlatpakPermission.x11:
      case FlatpakPermission.wayland:
        return Icons.monitor;
    }
  }

  static FlatpakPermission? fromString(String name) {
    return FlatpakPermission.values.firstWhere(
          (p) => p.name == name,
      orElse: () => throw ArgumentError('Unknown permission: $name'),
    );
  }
}