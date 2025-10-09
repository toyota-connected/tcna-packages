import 'package:flutter_test/flutter_test.dart';
import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flatpak API Integration Tests', () {
    late FlatpakApi api;

    setUpAll(() {
      api = FlatpakApi();
    });

    group('System Information Tests', () {
      test('should get Flatpak version', () async {
        final version = await api.getVersion();
        
        expect(version, isNotEmpty);
        expect(version, matches(RegExp(r'^\d+\.\d+\.\d+')));
        print('Flatpak version: $version');
      });

      test('should get default architecture', () async {
        final arch = await api.getDefaultArch();
        
        expect(arch, isNotEmpty);
        expect(arch, matches(RegExp(r'^(x86_64|aarch64|armv7l|i386)$')));
        print('Default architecture: $arch');
      });

      test('should get supported architectures', () async {
        final arches = await api.getSupportedArches();
        
        expect(arches, isNotEmpty);
        expect(arches.every((arch) => arch != null && arch.isNotEmpty), isTrue);
        
        final validArches = ['x86_64', 'aarch64', 'armv7l', 'i386'];
        for (final arch in arches) {
          expect(validArches.contains(arch), isTrue, 
                 reason: 'Invalid architecture: $arch');
        }
        print('Supported architectures: $arches');
      });
    });

    group('Installation Tests', () {
      test('should get system installations', () async {
        final installations = await api.getSystemInstallations();
        
        expect(installations, isA<List<Installation>>());
        
        for (final installation in installations) {
          _validateInstallation(installation, isSystem: true);
        }
        print('Found ${installations.length} system installations');
      });

      test('should get user installation', () async {
        final installation = await api.getUserInstallation();
        
        _validateInstallation(installation, isSystem: false);
        expect(installation.isUser, isTrue);
        print('User installation: ${installation.displayName}');
      });
    });

    group('Remote Repository Tests', () {
      const testRemoteName = 'test-integration-remote';
      const testRemoteUrl = 'https://flathub.org/repo/flathub.flatpakrepo';

      tearDown(() async {
        try {
          await api.remoteRemove(testRemoteName);
        } catch (e) {
          // Ignore if remote doesn't exist
        }
      });

      test('should add and remove remote repository', () async {
        final remote = Remote(
          name: testRemoteName,
          url: testRemoteUrl,
          collectionId: '',
          title: 'Test Integration Remote',
          comment: 'Remote added during integration testing',
          description: 'Test remote for integration testing',
          homepage: 'https://example.com',
          icon: '',
          defaultBranch: 'stable',
          mainRef: '',
          remoteType: 'static',
          filter: '',
          appstreamTimestamp: DateTime.now().toIso8601String(),
          appstreamDir: '',
          gpgVerify: true,
          noEnumerate: false,
          noDeps: false,
          disabled: false,
          prio: 1,
        );

        // Test adding remote
        final addResult = await api.remoteAdd(remote);
        expect(addResult, isTrue);

        final installation = await api.getUserInstallation();
        final remoteNames = installation.remotes.map((r) => r.name).toList();
        expect(remoteNames, contains(testRemoteName));

        // Test removing remote
        final removeResult = await api.remoteRemove(testRemoteName);
        expect(removeResult, isTrue);

        final updatedInstallation = await api.getUserInstallation();
        final updatedRemoteNames = updatedInstallation.remotes.map((r) => r.name).toList();
        expect(updatedRemoteNames, isNot(contains(testRemoteName)));
      });

      test('should handle invalid remote operations', () async {
        expect(() => api.remoteRemove('non-existent-remote'), 
               throwsA(isA<Exception>()));
      });
    });

    group('Application Management Tests', () {
      test('should get installed applications', () async {
        final applications = await api.getApplicationsInstalled();
        
        expect(applications, isA<List<Application>>());
        
        for (final app in applications) {
          _validateApplication(app);
        }
        print('Found ${applications.length} installed applications');
        
        if (applications.isNotEmpty) {
          final firstApp = applications.first;
          print('Sample app: ${firstApp.name} (${firstApp.id})');
        }
      });

      test('should get applications from remote', () async {
        final installation = await api.getUserInstallation();
        
        if (installation.remotes.isNotEmpty) {
          final firstRemote = installation.remotes.first;
          
          try {
            final remoteApps = await api.getApplicationsRemote(firstRemote.name);
            expect(remoteApps, isA<List<Application>>());
            print('Found ${remoteApps.length} applications in remote: ${firstRemote.name}');
            for (final app in remoteApps) {
              _validateApplication(app, isRemote: true);
            }
          } catch (e) {
            print('Could not fetch apps from remote ${firstRemote.name}: $e');
          }
        } else {
          print('No remotes available for testing');
        }
      });

      test('should handle application lifecycle operations', () async {
        const testAppId = 'org.test.NonExistentApp';

        expect(() async => await api.applicationInstall(testAppId), 
               throwsA(isA<Exception>()));

        expect(() async => await api.applicationUninstall(testAppId), 
               throwsA(isA<Exception>()));

        expect(() async => await api.applicationStart(testAppId, null), 
               throwsA(isA<Exception>()));

        expect(() async => await api.applicationStop(testAppId), 
               throwsA(isA<Exception>()));
      });

      test('should test application operations on installed apps', () async {
        final applications = await api.getApplicationsInstalled();
        
        if (applications.isNotEmpty) {
          final testApp = applications.first;
          print('Testing operations on: ${testApp.name}');

          try {
            final config = <String?, Object?>{
              'env': <String, String>{'TEST_ENV': 'integration_test'},
            };
            
            final startResult = await api.applicationStart(testApp.id, config);
            print('Start result for ${testApp.name}: $startResult');
            expect(startResult, isTrue);
            
            await Future.delayed(const Duration(seconds: 1));
            
            // Test application stop
            final stopResult = await api.applicationStop(testApp.id);
            print('Stop result for ${testApp.name}: $stopResult');
            expect(stopResult, isTrue);
            
          } catch (e) {
            print('Application operation failed for ${testApp.name}: $e');
            expect(e, isA<Exception>());
          }
        } else {
          print('No installed applications available for testing');
        }
      });

      test('should properly validate application IDs', () async {
        expect(() async => await api.applicationStart('', null), 
               throwsA(isA<Exception>()));

        expect(() async => await api.applicationStop(''), 
               throwsA(isA<Exception>()));
      });
    });

    group('Data Integrity Tests', () {
      test('should maintain consistent data across API calls', () async {
        // Get installations multiple times and ensure consistency
        final installation1 = await api.getUserInstallation();
        final installation2 = await api.getUserInstallation();
        
        expect(installation1.id, equals(installation2.id));
        expect(installation1.path, equals(installation2.path));
        expect(installation1.remotes.length, equals(installation2.remotes.length));
      });

      test('should handle concurrent API calls', () async {
        final futures = <Future>[];
        
        // Make multiple concurrent calls
        for (int i = 0; i < 5; i++) {
          futures.add(api.getVersion());
          futures.add(api.getDefaultArch());
          futures.add(api.getSupportedArches());
        }
        
        final results = await Future.wait(futures);
        
        // Verify all version calls return the same result
        final versions = results.whereType<String>().where((r) => r.contains('.')).toList();
        expect(versions.every((v) => v == versions.first), isTrue);
      });
    });

    group('Error Handling Tests', () {
      test('should handle platform exceptions gracefully', () async {
        // Test with invalid inputs where applicable
        expect(() async => await api.remoteRemove(''), throwsA(isA<Exception>()));
        expect(() async => await api.applicationInstall(''), throwsA(isA<Exception>()));
        expect(() async => await api.applicationUninstall(''), throwsA(isA<Exception>()));
      });
    });
  });
}

void _validateInstallation(Installation installation, {required bool isSystem}) {
  expect(installation.id, isNotEmpty);
  expect(installation.path, isNotEmpty);
  expect(installation.isUser, equals(!isSystem));
  expect(installation.priority, isA<int>());
  expect(installation.defaultLanguages, isA<List<String>>());
  expect(installation.defaultLocale, isA<List<String>>());
  expect(installation.remotes, isA<List<Remote>>());
  
  for (final remote in installation.remotes) {
    _validateRemote(remote);
  }
}

void _validateRemote(Remote remote) {
  expect(remote.name, isNotEmpty);
  expect(remote.prio, isA<int>());
  expect(remote.gpgVerify, isA<bool>());
  expect(remote.noEnumerate, isA<bool>());
  expect(remote.noDeps, isA<bool>());
  expect(remote.disabled, isA<bool>());
  
  if (remote.appstreamTimestamp.isNotEmpty) {
    expect(() => DateTime.parse(remote.appstreamTimestamp), 
           returnsNormally);
  }
}

void _validateApplication(Application application,{bool isRemote = false}) {
  expect(application.name, isNotEmpty);
  expect(application.id, isNotEmpty);
  expect(application.installedSize, isA<int>());
  expect(application.isCurrent, isA<bool>());
  expect(application.contentRating, isA<Map<String?, Object?>>());
  expect(application.subpaths, isA<List<String>>());
  if(!isRemote) {
    expect(application.deployDir, isNotEmpty);
    expect(application.installedSize, greaterThanOrEqualTo(0));
  }
  
  if (application.contentRatingType.isNotEmpty) {
    expect(['oars-1.0', 'oars-1.1'], contains(application.contentRatingType));
  }
  
  if (application.version.isNotEmpty) {
    expect(application.version, matches(RegExp(r'^[\w\.\-\+]+$')));
  }
}