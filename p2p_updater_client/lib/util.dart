import 'dart:io';
import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;
import 'package:windows_apps_infos/windows_apps_infos.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:p2p_updater_client/simplelog.dart';

Future<String> getTempPath() async {
  final dir = await getTemporaryDirectory();
  return dir.toString().replaceAll("'", "");
}

String getRealPath(String pathInConfig) {
  String dirProgramFilesX86 = '';
  String dirPublic = '';

  ffi.Pointer<Utf16> szPath = calloc.allocate<Utf16>(1024);
  win32.SHGetFolderPath(0, win32.CSIDL_PROGRAM_FILESX86, 0, 0, szPath);
  dirProgramFilesX86 = szPath.toDartString();
  win32.SHGetFolderPath(0, win32.CSIDL_COMMON_DESKTOPDIRECTORY, 0, 0, szPath);
  dirPublic = szPath.toDartString().replaceAll('Desktop', '');
  win32.free(szPath);

  if (pathInConfig.isNotEmpty) {
    String alias = '';
    String real = '';
    if (pathInConfig.contains('PROGRAMFILES')) {
      alias = "PROGRAMFILES";
      real = dirProgramFilesX86;
    } else if (pathInConfig.contains('PUBLIC')) {
      alias = 'PUBLIC';
      real = dirPublic;
    }
    return pathInConfig.replaceAll("/", "\\").replaceAll(alias, real);
  }
  return "";
}

Future<(String, String)> getFileVersion(String path) async {
  String version = '';
  String error = '';

  final exist = await File(path).exists();
  if (exist) {
    try {
      final info = await DeviceApps.getAppAllInfo(path: path);
      version = info.fileVersion.replaceAll(' ', '').replaceAll(',', '.');
    } catch (e) {
      error = e.toString();
    }
  } else {
    error = "File not exists: $path";
  }
  return (version, error);
}

Future<(String, String)> getFileHash(String path) async {
  String hash = '';
  String error = '';

  final exist = await File(path).exists();
  if (exist) {
    try {
      final f = File(path);
      final buffer = f.readAsBytesSync();
      hash = sha256.convert(buffer).toString();
    } catch (e) {
      logger.e("getFileHash: ${e.toString()}");
    }
  } else {
    error = "File not exists: $path";
    logger.e("getFileHash: $error");
  }
  return (hash, error);
}

String type2ServerType(String type) {
  if (type.toLowerCase() == "file") {
    return 'F';
  } else if (type.toLowerCase() == 'package') {
    return 'P';
  } else {
    return type;
  }
}

Future<String> getDownloadPath(String basedir, String filename) async {
  int i = 0;
  String temppath = p.join(basedir, filename);
  while (true) {
    final exists = await File(temppath).exists();
    if (exists) {
      temppath = p.join(basedir, '$i$filename');
    } else {
      break;
    }
    i++;
  }
  return temppath;
}

String getUserId() {
  const unLen = 256;
  return using<String>((arena) {
    final buffer =
        arena.allocate<Utf16>(ffi.sizeOf<ffi.Uint16>() * (unLen + 1));
    final bufferSize = arena.allocate<ffi.Uint32>(ffi.sizeOf<ffi.Uint32>());
    bufferSize.value = unLen + 1;
    final result = win32.GetUserName(buffer, bufferSize);
    if (result == 0) {
      win32.GetLastError();
      final exceptionDesc =
          'Failed to get win32 username: error 0x${result.toRadixString(16)}';
      logger.f(exceptionDesc);
      throw Exception(exceptionDesc);
    }
    return buffer.toDartString();
  });
}

Future<String> getIp(bool bInShortForm) async {
  String IPs = '';
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (!addr.isLoopback) {
        if (bInShortForm) {
          IPs += '${addr.address};';
        } else {
          IPs += "{ 'type': '${addr.type.name}', 'addr': '${addr.address}' }, ";
        }
      }
    }
  }

  if (bInShortForm) {
    IPs = IPs.substring(0, IPs.length - 1);
    return IPs;
  } else {
    IPs = IPs.substring(0, IPs.length - 2);
    return "[ $IPs ]";
  }
}
