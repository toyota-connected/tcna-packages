// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2020-2026 Toyota Connected North America
//
// Native-assets build hook for video_player_linux.
//
// Drives the project's CMake build to compile libvideo_player_linux.so,
// then declares the resulting shared library as a CodeAsset so Dart's
// `@Native` bindings (in lib/src/ffi/bindings.dart, at runtime via
// DynamicLibrary.process()) can resolve symbols without relying on the
// Flutter plugin system. This also makes the package usable in pure
// Dart FFI contexts (e.g. tooling, tests) where Flutter isn't loaded.
//
// Patterned after https://github.com/meta-flutter/appstream_dart/blob/main/hook/build.dart
// which itself follows https://github.com/jwinarske/pw_dart/blob/main/hook/build.dart

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    if (Platform.environment.containsKey('SKIP_NATIVE_BUILD')) {
      stderr.writeln('SKIP_NATIVE_BUILD set — skipping native build.');
      return;
    }

    final pkgRoot = input.packageRoot.toFilePath();
    final buildDir = input.outputDirectory.resolve('cmake/').toFilePath();

    await Directory(buildDir).create(recursive: true);

    final hasNinja = await _which('ninja');

    if (!File('${buildDir}CMakeCache.txt').existsSync()) {
      await _run('cmake', [
        '-S',
        pkgRoot,
        '-B',
        buildDir,
        '-DCMAKE_BUILD_TYPE=Release',
        '-DVIDEO_PLAYER_EMBEDDER=fl',
        '-DVIDEO_PLAYER_HOOK_BUILD=ON',
        // Hooks run before Flutter populates its plugin ephemeral, so
        // flutter_linux-1.0 pkg-config isn't on PKG_CONFIG_PATH here.
        // Build just the FFI core; the embedder glue is compiled by
        // Flutter's regular plugin pipeline via linux/CMakeLists.txt.
        '-DVIDEO_PLAYER_CORE_ONLY=ON',
        if (hasNinja) ...['-G', 'Ninja'],
      ]);
    }

    await _run('cmake', ['--build', buildDir, '--parallel']);

    // Core-only build names the library with a _core suffix to avoid
    // colliding with the full plugin .so Flutter's plugin pipeline
    // produces (see OUTPUT_NAME branch in CMakeLists.txt).
    final libFile = File('${buildDir}libvideo_player_linux_core.so');
    if (!libFile.existsSync()) {
      throw StateError(
          'libvideo_player_linux_core.so not found at ${libFile.path}');
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: 'src/ffi/bindings.dart',
        linkMode: DynamicLoadingBundled(),
        file: libFile.uri,
      ),
    );

    // Re-run the hook whenever any C/C++ source or CMake file changes.
    for (final dir in ['linux_cpp', 'linux']) {
      final d = Directory('$pkgRoot/$dir');
      if (!d.existsSync()) continue;
      for (final entity in d.listSync(recursive: true)) {
        if (entity is! File) continue;
        final p = entity.path;
        if (p.endsWith('.cpp') ||
            p.endsWith('.cc') ||
            p.endsWith('.c') ||
            p.endsWith('.hpp') ||
            p.endsWith('.h') ||
            p.endsWith('CMakeLists.txt')) {
          output.dependencies.add(entity.uri);
        }
      }
    }
    output.dependencies.add(Uri.file('$pkgRoot/CMakeLists.txt'));

    stderr.writeln('libvideo_player_linux built: ${libFile.path}');
  });
}

Future<void> _run(String exe, List<String> args) async {
  final p = await Process.start(exe, args, mode: ProcessStartMode.inheritStdio);
  final code = await p.exitCode;
  if (code != 0) {
    throw ProcessException(exe, args, 'exit code $code', code);
  }
}

Future<bool> _which(String exe) async {
  final r = await Process.run('which', [exe]);
  return r.exitCode == 0;
}
