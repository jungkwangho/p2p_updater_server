// config
/*
{
  "servers":[
    {
      "ip": "127.0.0.1",
      "port": 8088
    }
  ],
  "update targets":[
    {
      "name": "nexess client",
      "versioned file": "%PROGRAM_FILES%\initech\INISAFE Nexess Client\STANDARD\IniNXClient.exe",
      "type": "package"
    }
  ],
  "use report": true
}
*/

import 'dart:convert';
import 'dart:io';
import 'package:pretty_json/pretty_json.dart';

class Server {
  const Server({required this.ip, required this.port});
  final String ip;
  final int port;

  factory Server.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'ip': String ip,
        'port': int port,
      } =>
        Server(
          ip: ip,
          port: port,
        ),
      _ => throw Exception('Failed to parse Server'),
    };
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'port': port,
      };
}

class UpdateTarget {
  const UpdateTarget(
      {required this.versionedFile, required this.name, required this.type});
  final String versionedFile;
  final String name;
  final String type;

  factory UpdateTarget.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'versioned file': String versionedFile,
        'name': String name,
        'type': String type,
      } =>
        UpdateTarget(
          versionedFile: versionedFile,
          name: name,
          type: type,
        ),
      _ => throw Exception('Failed to parse UpdateTarget'),
    };
  }

  Map<String, dynamic> toJson() => {
        'versioned file': versionedFile,
        'name': name,
        'type': type,
      };
}

class Config {
  const Config(
      {required this.servers,
      required this.updateTargets,
      required this.useReport,
      required this.autoStart,
      required this.run,
      required this.useTls});

  final List<Server> servers;
  final List<UpdateTarget> updateTargets;
  final bool useReport;
  final bool autoStart;
  final String run;
  final bool useTls;

  factory Config.loadConfig(String basepath) {
    try {
      final file = File("$basepath/config.json");

      final contents = file.readAsStringSync();

      return Config.fromJson(jsonDecode(contents));
    } catch (e) {
      throw Exception("Failed to load Config");
    }
  }

  void saveConfig(String basepath) {
    try {
      final file = File("$basepath/config.json");
      file.writeAsString(prettyJson(toJson(), indent: 2));
    } catch (e) {
      throw Exception("Failed to save Config");
    }
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    try {
      final serversList = json['servers'] as List<dynamic>?;
      final updateTargetsList = json['update targets'] as List<dynamic>?;

      return Config(
        servers: (serversList != null)
            ? serversList.map((server) => Server.fromJson(server)).toList()
            : <Server>[],
        updateTargets: (updateTargetsList != null)
            ? updateTargetsList
                .map((target) => UpdateTarget.fromJson(target))
                .toList()
            : <UpdateTarget>[],
        useReport: json['use report'],
        autoStart: json['auto start'],
        run: json['run'],
        useTls: json['use tls'],
      );
    } catch (e) {
      throw Exception('Failed to parse Config');
    }
  }

  Map<String, dynamic> toJson() => {
        'servers': servers.map((server) => server.toJson()).toList(),
        'update targets':
            updateTargets.map((updateTarget) => updateTarget.toJson()).toList(),
        'use report': useReport,
        'auto start': autoStart,
        'run': run,
        'use tls': useTls,
      };
}

/*
class CounterStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/counter.txt');
  }

  Future<int> readCounter() async {
    try {
      final file = await _localFile;

      final contents = await file.readAsString();

      return int.parse(contents);
    } catch (e) {
      return 0;
    }
  }

  Future<File> writeCounter(int counter) async {
    final file = await _localFile;

    return file.writeAsString('$counter');
  }
}
*/