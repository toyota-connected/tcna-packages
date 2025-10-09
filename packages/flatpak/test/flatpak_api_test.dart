import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatpak_flutter/src/messages.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlatpakApi Tests', () {
    late FlatpakApi api;

    setUp(() {
      api = FlatpakApi();
    });

    tearDown(() {
      // Clear all handlers
      final channels = [
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getVersion',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getDefaultArch',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getSupportedArches',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getUserInstallation',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getSystemInstallations',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.remoteAdd',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.remoteRemove',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getApplicationsInstalled',
        'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.applicationInstall',
      ];
      
      for (final channelName in channels) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          BasicMessageChannel<Object?>(channelName, FlatpakApi.pigeonChannelCodec),
          null,
        );
      }
    });

    group('Version and Architecture', () {
      test('getVersion returns correct version string', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getVersion',
            FlatpakApi.pigeonChannelCodec, // Access through class name
          ),
          (Object? message) async {
            // Return the version in the format Pigeon expects
            return <Object?>['1.15.4'];
          },
        );

        final version = await api.getVersion();

        expect(version, isA<String>());
        expect(version, equals('1.15.4'));
        expect(version, isNotEmpty);
        print('Flatpak version: $version');
      });

      test('getDefaultArch returns correct architecture', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getDefaultArch',
            FlatpakApi.pigeonChannelCodec, 
          ),
          (Object? message) async {
            return <Object?>['x86_64'];
          },
        );

        final arch = await api.getDefaultArch();

        expect(arch, equals('x86_64'));
        print('Default architecture: $arch');
      });

      test('getSupportedArches returns list of architectures', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getSupportedArches',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            return <Object?>[['x86_64', 'aarch64', 'i386']];
          },
        );

        final arches = await api.getSupportedArches();

        expect(arches, equals(['x86_64', 'aarch64', 'i386']));
        expect(arches.length, equals(3));
        print('Supported architectures: $arches');
      });
    });

    group('Installation Management', () {
      test('getUserInstallation returns valid installation', () async {
        final mockInstallation = Installation(
          id: 'user',
          displayName: 'User Installation',
          path: '/home/user/.local/share/flatpak',
          noInteraction: false,
          isUser: true,
          priority: 0,
          defaultLanguages: ['en'],
          defaultLocale: ['en_US.UTF-8'],
          remotes: [],
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getUserInstallation',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            return <Object?>[mockInstallation];
          },
        );

        final installation = await api.getUserInstallation();

        expect(installation.id, equals('user'));
        expect(installation.isUser, isTrue);
        expect(installation.displayName, equals('User Installation'));
        print('User installation: ${installation.displayName}');
      });

      test('getSystemInstallations returns list of installations', () async {
        final mockInstallation = Installation(
          id: 'system',
          displayName: 'System Installation',
          path: '/var/lib/flatpak',
          noInteraction: false,
          isUser: false,
          priority: 1,
          defaultLanguages: ['en'],
          defaultLocale: ['en_US.UTF-8'],
          remotes: [],
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getSystemInstallations',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            return <Object?>[[mockInstallation]];
          },
        );

        final installations = await api.getSystemInstallations();

        expect(installations, isA<List<Installation>>());
        expect(installations.length, equals(1));

        final installation = installations.first;
        expect(installation.id, equals('system'));
        expect(installation.isUser, isFalse);
        print('System installations count: ${installations.length}');
      });
    });

    group('Remote Management', () {
      test('remoteAdd successfully adds remote', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.remoteAdd',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            // Verify the message contains a Remote object
            final args = message as List<Object?>;
            expect(args.length, equals(1));
            
            final remote = args[0] as Remote;
            expect(remote.name, equals('flathub'));
            expect(remote.url.startsWith('https://'), isTrue);
            
            return <Object?>[true];
          },
        );

        final remote = Remote(
          name: 'flathub',
          url: 'https://dl.flathub.org/repo/',
          collectionId: 'org.flathub.Stable',
          title: 'Flathub',
          comment: 'Central repository of Flatpak applications',
          description: 'Flathub is the place to get and distribute apps for Linux.',
          homepage: 'https://flathub.org/',
          icon: '',
          defaultBranch: 'stable',
          mainRef: '',
          remoteType: 'static',
          filter: '',
          appstreamTimestamp: '',
          appstreamDir: '',
          gpgVerify: true,
          noEnumerate: false,
          noDeps: false,
          disabled: false,
          prio: 1,
        );

        final result = await api.remoteAdd(remote);
        expect(result, isTrue);
      });

      test('remoteRemove successfully removes remote', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.remoteRemove',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            final args = message as List<Object?>;
            final remoteId = args[0] as String;
            
            return <Object?>[remoteId == 'flathub'];
          },
        );

        final result = await api.remoteRemove('flathub');
        expect(result, isTrue);

        final failResult = await api.remoteRemove('non-existent');
        expect(failResult, isFalse);
      });
    });

    group('Application Operations', () {
      test('get installed applications should return list', () async {
        final mockApp = Application(
          name: 'Firefox',
          id: 'org.mozilla.firefox',
          summary: 'Firefox Web Browser',
          version: '121.0.1',
          origin: 'flathub',
          license: 'MPL-2.0',
          installedSize: 268435456,
          deployDir: '/var/lib/flatpak/app/org.mozilla.firefox',
          isCurrent: true,
          contentRatingType: 'oars-1.1',
          contentRating: {'violence-cartoon': 'none'},
          latestCommit: 'abc123def456',
          eol: '',
          eolRebase: '',
          subpaths: [],
          metadata: '[Application]\nname=org.mozilla.firefox',
          appdata: '<application><id>org.mozilla.firefox</id></application>',
        );

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getApplicationsInstalled',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            return <Object?>[[mockApp]];
          },
        );

        final apps = await api.getApplicationsInstalled();

        expect(apps, isA<List<Application>>());
        expect(apps.length, equals(1));

        final app = apps.first;
        expect(app.id, equals('org.mozilla.firefox'));
        expect(app.name, equals('Firefox'));
        expect(app.installedSize, greaterThan(0));
        print('Installed apps: ${apps.length}');
      });

      test('applicationInstall succeeds for valid app ID', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.applicationInstall',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            final args = message as List<Object?>;
            final appId = args[0] as String;
            
            return <Object?>[appId.contains('.')];
          },
        );

        final result = await api.applicationInstall('org.example.TestApp');
        expect(result, isTrue);

        final failResult = await api.applicationInstall('invalid-id');
        expect(failResult, isFalse);
      });
    });

    group('Error Handling', () {
      test('platform exceptions are properly thrown', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getVersion',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            return <Object?>['UNAVAILABLE', 'Flatpak not found', null];
          },
        );

        expect(
          () => api.getVersion(),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'UNAVAILABLE')
              .having((e) => e.message, 'message', 'Flatpak not found')),
        );
      });

      test('null responses throw appropriate errors', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
          const BasicMessageChannel<Object?>(
            'dev.flutter.pigeon.flatpak_flutter.FlatpakApi.getVersion',
            FlatpakApi.pigeonChannelCodec,
          ),
          (Object? message) async {
            return null;
          },
        );

        expect(
          () => api.getVersion(),
          throwsA(isA<PlatformException>()
              .having((e) => e.code, 'code', 'channel-error')),
        );
      });
    });
  });

  group('Data Model Tests', () {
    test('Remote data class', () {
      final remote = Remote(
        name: 'test',
        url: 'https://example.com',
        collectionId: 'com.example.Test',
        title: 'Test Remote',
        comment: 'Test comment',
        description: 'Test description',
        homepage: 'https://example.com',
        icon: '',
        defaultBranch: 'stable',
        mainRef: 'app/com.example.Test/x86_64/stable',
        remoteType: 'static',
        filter: '',
        appstreamTimestamp: '1234567890',
        appstreamDir: '/tmp/test',
        gpgVerify: true,
        noEnumerate: false,
        noDeps: false,
        disabled: false,
        prio: 1,
      );

      expect(remote.name, equals('test'));
      expect(remote.gpgVerify, isTrue);
      expect(remote.prio, equals(1));
    });

    test('Application data class', () {
      final app = Application(
        name: 'Test App',
        id: 'com.example.TestApp',
        summary: 'A test application',
        version: '1.0.0',
        origin: 'flathub',
        license: 'GPL-3.0',
        installedSize: 1048576,
        deployDir: '/var/lib/flatpak/app/com.example.TestApp',
        isCurrent: true,
        contentRatingType: 'oars-1.1',
        contentRating: {'violence-cartoon': 'none'},
        latestCommit: 'abc123def456',
        eol: '',
        eolRebase: '',
        subpaths: [],
        metadata: '[Application]\nname=com.example.TestApp',
        appdata: '<application><id>com.example.TestApp</id></application>',
      );

      expect(app.id, equals('com.example.TestApp'));
      expect(app.installedSize, equals(1048576));
      expect(app.isCurrent, isTrue);
    });

    test('Installation data class', () {
      final installation = Installation(
        id: 'system',
        displayName: 'System Installation',
        path: '/var/lib/flatpak',
        noInteraction: false,
        isUser: false,
        priority: 1,
        defaultLanguages: ['en', 'es'],
        defaultLocale: ['en_US.UTF-8'],
        remotes: [],
      );

      expect(installation.isUser, isFalse);
      expect(installation.priority, equals(1));
      expect(installation.defaultLanguages, contains('en'));
    });
  });

  group('Serialization Tests', () {
    test('Remote encode/decode', () {
      final original = Remote(
        name: 'flathub',
        url: 'https://dl.flathub.org/repo/',
        collectionId: 'org.flathub.Stable',
        title: 'Flathub',
        comment: 'Central repository',
        description: 'Repository description',
        homepage: 'https://flathub.org/',
        icon: 'https://flathub.org/icon.png',
        defaultBranch: 'stable',
        mainRef: '',
        remoteType: 'static',
        filter: '',
        appstreamTimestamp: '1640995200',
        appstreamDir: '/var/lib/flatpak/repo/appstream/x86_64',
        gpgVerify: true,
        noEnumerate: false,
        noDeps: false,
        disabled: false,
        prio: 1,
      );

      final encoded = original.encode();
      final decoded = Remote.decode(encoded);

      expect(decoded.name, equals(original.name));
      expect(decoded.url, equals(original.url));
      expect(decoded.gpgVerify, equals(original.gpgVerify));
      expect(decoded.prio, equals(original.prio));
    });

    test('Application encode/decode with content rating', () {
      final contentRating = {
        'violence-cartoon': 'none',
        'violence-realistic': 'mild',
        'language-profanity': 'moderate',
      };

      final original = Application(
        name: 'Firefox',
        id: 'org.mozilla.firefox',
        summary: 'Firefox Web Browser',
        version: '121.0.1',
        origin: 'flathub',
        license: 'MPL-2.0',
        installedSize: 268435456,
        deployDir: '/var/lib/flatpak/app/org.mozilla.firefox',
        isCurrent: true,
        contentRatingType: 'oars-1.1',
        contentRating: contentRating,
        latestCommit: 'abc123def456ghi789',
        eol: '',
        eolRebase: '',
        subpaths: ['/share/icons', '/share/applications'],
        metadata: '[Application]\nname=org.mozilla.firefox\nruntime=org.freedesktop.Platform/x86_64/23.08',
        appdata: '<application><id>org.mozilla.firefox</id><name>Firefox</name></application>',
      );

      final encoded = original.encode();
      final decoded = Application.decode(encoded);

      expect(decoded.contentRating['violence-cartoon'], equals('none'));
      expect(decoded.contentRating['language-profanity'], equals('moderate'));
      expect(decoded.subpaths, contains('/share/icons'));
      expect(decoded.metadata, contains('org.freedesktop.Platform'));
    });
  });
}