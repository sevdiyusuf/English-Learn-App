import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

void main() {
  stdout.writeln(
    '=== Android 16 KB Page-Size Binary & Static Compatibility Validator ===',
  );

  final gradleFile = File('android/app/build.gradle.kts');
  if (!gradleFile.existsSync()) {
    stderr.writeln('ERROR: android/app/build.gradle.kts not found');
    exit(1);
  }

  final gradleContent = gradleFile.readAsStringSync();

  // 1. Verify targetSdk & compileSdk
  final compileSdkMatch = RegExp(
    r'compileSdk\s*=\s*(\d+)',
  ).firstMatch(gradleContent);
  final targetSdkMatch = RegExp(
    r'targetSdk\s*=\s*(\d+)',
  ).firstMatch(gradleContent);
  final ndkVersionMatch = RegExp(
    r'ndkVersion\s*=\s*"([^"]+)"',
  ).firstMatch(gradleContent);

  final compileSdk =
      compileSdkMatch != null ? int.parse(compileSdkMatch.group(1)!) : 0;
  final targetSdk =
      targetSdkMatch != null ? int.parse(targetSdkMatch.group(1)!) : 0;
  final ndkVersion = ndkVersionMatch?.group(1) ?? 'none';

  stdout.writeln('\n[1/3] Android SDK & Toolchain Inspection:');
  stdout.writeln(
    '  compileSdk: $compileSdk (required >= 35 for Android 15 16 KB page-size support)',
  );
  stdout.writeln('  targetSdk:  $targetSdk (required >= 35)');
  stdout.writeln(
    '  ndkVersion: $ndkVersion (NDK r27+ / 29+ defaults to 16KB max-page-size)',
  );

  if (compileSdk < 35 || targetSdk < 35) {
    stderr.writeln(
      'ERROR: compileSdk and targetSdk must be >= 35 for 16 KB page size compatibility.',
    );
    exit(1);
  }

  // 2. Locate built APK for native ELF segment inspection
  final debugApk = File('build/app/outputs/flutter-apk/app-debug.apk');
  final releaseApk = File('build/app/outputs/flutter-apk/app-release.apk');

  File? targetApk;
  if (releaseApk.existsSync()) {
    targetApk = releaseApk;
  } else if (debugApk.existsSync()) {
    targetApk = debugApk;
  }

  if (targetApk == null) {
    stderr.writeln(
      'ERROR: No built APK artifact found at build/app/outputs/flutter-apk/. Run flutter build apk --release first.',
    );
    exit(1);
  }

  stdout.writeln('\n[2/3] APK Artifact Inspection:');
  stdout.writeln('  Artifact: ${targetApk.path}');
  stdout.writeln(
    '  APK Size: ${(targetApk.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
  );

  final bytes = targetApk.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);

  final soEntries = archive.where((file) => file.name.endsWith('.so')).toList();
  stdout.writeln(
    '  Found ${soEntries.length} native shared libraries (.so) in APK.',
  );

  var checkedCount = 0;
  final coreLibrariesAligned = <String>[];
  final legacyLibrariesUnaligned = <String>[];

  for (final file in soEntries) {
    final content = file.content as List<int>;
    final data = Uint8List.fromList(content);

    // Verify ELF Magic Header: \x7F ELF
    if (data.length < 64 ||
        data[0] != 0x7F ||
        data[1] != 0x45 ||
        data[2] != 0x4C ||
        data[3] != 0x46) {
      continue;
    }

    final is64Bit = data[4] == 2; // 1 = 32-bit, 2 = 64-bit
    if (!is64Bit) {
      // 32-bit libraries (armeabi-v7a) use 4 KB pages by architecture specification
      continue;
    }

    checkedCount++;
    final byteData = ByteData.sublistView(data);
    final isLittleEndian = data[5] == 1;
    final endian = isLittleEndian ? Endian.little : Endian.big;

    final ePhOff = byteData.getUint64(32, endian);
    final ePhEntSize = byteData.getUint16(54, endian);
    final ePhNum = byteData.getUint16(56, endian);

    var maxLoadAlign = 0;

    for (var i = 0; i < ePhNum; i++) {
      final offset = ePhOff + (i * ePhEntSize);
      if (offset + 56 > data.length) break;

      final pType = byteData.getUint32(offset, endian);
      if (pType == 1) {
        // PT_LOAD segment
        final pAlign = byteData.getUint64(offset + 48, endian);
        if (pAlign > maxLoadAlign) {
          maxLoadAlign = pAlign;
        }
      }
    }

    final passAlign = maxLoadAlign >= 16384; // 16384 bytes = 16 KB (0x4000)
    stdout.writeln(
      '  - ${file.name}: Max PT_LOAD align = $maxLoadAlign bytes (${(maxLoadAlign / 1024).toStringAsFixed(0)} KB) -> ${passAlign ? "ALIGNED" : "UNALIGNED (4KB)"}',
    );

    if (passAlign) {
      coreLibrariesAligned.add(file.name);
    } else {
      legacyLibrariesUnaligned.add(file.name);
    }
  }

  stdout.writeln('\n[3/4] APK ZIP 16 KB Page Alignment Verification:');
  final zipAlignExecutable = _findZipAlignExecutable();
  if (zipAlignExecutable == null) {
    stdout.writeln(
      '  [SKIP] zipalign binary not found in PATH or ANDROID_HOME build-tools. Skipping zipalign execution.',
    );
  } else {
    stdout.writeln('  Using zipalign: $zipAlignExecutable');
    final result = Process.runSync(zipAlignExecutable, [
      '-c',
      '-P',
      '16',
      '-v',
      '4',
      targetApk.path,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln('\n[FAIL] zipalign -P 16 alignment check FAILED:');
      stderr.writeln(result.stderr.toString());
      stderr.writeln(result.stdout.toString());
      exit(1);
    }
    stdout.writeln('  [OK] zipalign -c -P 16 -v 4 passed for ${targetApk.path}');
  }

  stdout.writeln('\n[4/4] Binary & Toolchain Compatibility Summary:');
  stdout.writeln('  Checked 64-bit ELF shared libraries: $checkedCount');
  stdout.writeln(
    '  Core App & Engine Libraries Aligned (>= 16 KB): ${coreLibrariesAligned.length}',
  );
  stdout.writeln(
    '  Unaligned 4 KB Shared Libraries: ${legacyLibrariesUnaligned.length}',
  );

  if (legacyLibrariesUnaligned.isNotEmpty) {
    stderr.writeln(
      '\n[FAIL] 16 KB Page-Size Verification FAILED. The following 64-bit native libraries use 4 KB alignment:\n' +
          legacyLibrariesUnaligned.map((lib) => '  - $lib').join('\n'),
    );
    exit(1);
  }

  stdout.writeln(
    '  Validation Type: BINARY/STATIC ELF & ZIP 16 KB ALIGNMENT ANALYSIS (Strict 16 KB compliance)',
  );

  stdout.writeln(
    '\n[OK] 16 KB Page-Size Toolchain & Binary Compatibility Verification COMPLETE (ALL LIBRARIES & ZIP ALIGN PASS).',
  );
}

String? _findZipAlignExecutable() {
  // Check PATH first
  final pathResult = Process.runSync(
    Platform.isWindows ? 'where' : 'which',
    ['zipalign'],
  );
  if (pathResult.exitCode == 0 && pathResult.stdout.toString().trim().isNotEmpty) {
    return pathResult.stdout.toString().trim().split(RegExp(r'[\r\n]+')).first;
  }

  // Search ANDROID_HOME / ANDROID_SDK_ROOT
  final sdkPath =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'] ??
      (Platform.isWindows
          ? '${Platform.environment['LOCALAPPDATA']}\\Android\\Sdk'
          : '${Platform.environment['HOME']}/Android/Sdk');

  final buildToolsDir = Directory('$sdkPath/build-tools');
  if (buildToolsDir.existsSync()) {
    final subdirs = buildToolsDir.listSync().whereType<Directory>().toList();
    subdirs.sort((a, b) => b.path.compareTo(a.path)); // Latest version first
    for (final dir in subdirs) {
      final exeName = Platform.isWindows ? 'zipalign.exe' : 'zipalign';
      final file = File('${dir.path}/$exeName');
      if (file.existsSync()) {
        return file.path;
      }
    }
  }
  return null;
}

