import 'package:flutter/material.dart';
import 'package:p2p_updater_client/config.dart';
import 'package:p2p_updater_client/util.dart';

class InstalledFile {
  InstalledFile(
      {required this.name,
      required this.path,
      required this.type,
      required this.hash,
      required this.version,
      required this.lastError,
      required this.installed});

  final String name;
  final String path;
  final String type;
  final String hash;
  final String version;
  final String lastError;
  final bool installed;
}

class Installed {
  Installed({required this.config});

  List<InstalledFile> targets = [];
  final Config config;

  Future<void> construct() async {
    targets = <InstalledFile>[];

    for (var i = 0; i < config.updateTargets.length; i++) {
      final target = config.updateTargets[i];
      final path = getRealPath(target.versionedFile);
      final (version, error) = await getFileVersion(path);
      final (hash, error2) = await getFileHash(path);
      bool installed = false;
      if (error.isEmpty && error2.isEmpty) {
        installed = true;
      }

      targets.add(InstalledFile(
          name: target.name,
          path: path,
          type: target.type,
          hash: hash,
          version: version,
          lastError: error,
          installed: installed));
    }
  }
}
