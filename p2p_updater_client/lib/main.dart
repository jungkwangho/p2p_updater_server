import 'dart:async';
import 'dart:io';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:p2p_updater_client/simplelog.dart';
import 'package:win32/win32.dart' as win32;
import 'package:flutter/material.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:p2p_updater_client/installed.dart';
import 'package:p2p_updater_client/util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:p2p_updater_client/config.dart';
import 'package:p2p_updater_client/requests.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/*
TODO


설치파일 ---------------
설치시 원본 인스톨러 저장
업데이터 설치전 기존 업데이터 rename

서비스 --------------
업데이터 종료시 NC 실행하기
서비스에서 업데이터 실행하기 
설치 직후에는 rename된 updater가 존재하고 이때는 이미 업데이터가 실행중이므로 updater를 실행하지 않는다.

*/
const dummy_config = """{
  "servers":[
    {
      "ip": "127.0.0.1",
      "port": 8088
    }
  ],
  "update targets":[
    {
      "name": "nexess client",
      "versioned file": "PROGRAMFILES/INITECH/INISAFE Nexess Client/STANDARD/IniNxClient.exe",
      "type": "package"
    }
  ],
  "use report": true
}""";

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await FlutterSingleInstance.platform.isFirstInstance()) {
    final logdir = await getApplicationDocumentsDirectory();
    final logpath = p.join(logdir.path, "NCUpdater.log");
    logger.initLogger(logpath);

    HttpOverrides.global = MyHttpOverrides();

    WidgetsFlutterBinding.ensureInitialized();

    final dir = await getApplicationDocumentsDirectory();
    runApp(MaterialApp(home: Scaffold(body: MyApp(basepath: dir.path))));
  } else {
    print("App is already running");
    exit(0);
  }
}

class MyApp extends StatefulWidget {
  MyApp({super.key, required this.basepath});

  late Config _config;
  late Installed _installed;
  late Updates _updates;
  final String basepath;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool targetsConstructed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    //
    _loadConfig();

    _constructTargetList().then((value) => setState(() {
          targetsConstructed = true;
          _startPeriodicWork();
        }));
  }

  @override
  void dispose() {
    _endPeriodicWork();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.i("build called");

    final cnt = widget._config.updateTargets.length;

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text("업데이트 대상:$cnt 개"),
          Expanded(
            child: ListView.builder(
              itemCount: cnt,
              itemBuilder: _buildUpdateTargets,
            ),
          )
        ],
      ),
    );
  }

  void _loadConfig() {
    widget._config = Config.loadConfig(widget.basepath);
    //widget._config = Config.fromJson(jsonDecode(dummy_config));
    // widget._config.saveConfig(widget.basepath);

    //final path = "${widget.basepath}\\NexessDClient.exe";

    /*
    try {
      final verb = 'open'.toNativeUtf16();
      final process = path.toNativeUtf16();
      final params = ''.toNativeUtf16();
      final nullParams = ''.toNativeUtf16();
      ShellExecute(0, verb, process, params, nullParams, SW_SHOW);
    } catch (_) {}
    */
    /*
    Process.start(path, [], runInShell: true); // run하고 차이가 뭘까?
    */

    //print(dirname(Platform.script.toFilePath()));
  }

  Future<void> _constructTargetList() async {
    widget._installed = Installed(config: widget._config);
    return widget._installed.construct();
  }

  Widget _buildUpdateTargets(BuildContext context, int index) {
    final item = widget._config.updateTargets[index];
    InstalledFile? file;
    if (widget._installed.targets.isNotEmpty &&
        index < widget._installed.targets.length) {
      file = widget._installed.targets[index];
    }

    return ListTile(
      leading: const Icon(Icons.file_download),
      title: Text(
        (file != null) ? '${file.name} ${file.version}' : item.name,
      ),
      subtitle: Text(
        (file != null) ? file.path : item.versionedFile,
      ),
    );
  }

  void _startPeriodicWork() {
    if (widget._config.autoStart) {
      _timer = Timer(const Duration(seconds: 1), () {
        _doUpdate();
      });
    }
  }

  void _endPeriodicWork() {
    _timer?.cancel();
  }

  void _doUpdate() async {
    assert(targetsConstructed);

    final urlbase =
        await _getAvailableServer(widget._config.useTls ? "https" : "http");
    if (urlbase.isEmpty) {
      logger.e("No avaiable server exists.");

      //runExecutable();
      exit(0);
    }

    widget._updates = Updates(urlbase: urlbase, installed: widget._installed);

    widget._updates.checkUpdates().then((value) => setState(() {
          logger.i("checkUpdates end");

          widget._updates.downloadUpdates().then((value) => setState(() {
                logger.i("dowloadUpdates end");

                widget._updates.executeUpdates().then((value) => setState(() {
                      logger.i("executeUpdates end");

                      if (widget._config.useReport) {
                        widget._updates
                            .reportResults()
                            .then((value) => setState(() {
                                  logger.i("reportResults end");

                                  //runExecutable();
                                  exit(0);
                                }));
                      } else {
                        logger.i("reportResults skipped");

                        //runExecutable();
                        exit(0);
                      }
                    }));
              }));
        }));
  }

  Future<String> _getAvailableServer(String protocol) async {
    for (var i = 0; i < widget._config.servers.length; i++) {
      try {
        final server = widget._config.servers[i];
        final addr = '$protocol://${server.ip}:${server.port}';
        final resp = await http.get(Uri.parse('$addr/hello'));
        if (resp.body.contains('Server OK.')) {
          return addr;
        }
      } catch (e) {
        logger.e(e.toString());
      }
    }
    return '';
  }

  void runExecutable() async {
    final runPath = getRealPath(widget._config.run);
    logger.i("runExecutable: $runPath");
    try {
      final verb = 'open'.toNativeUtf16();
      final process = runPath.toNativeUtf16();
      final params = ''.toNativeUtf16();
      final nullParams = ''.toNativeUtf16();
      win32.ShellExecute(0, verb, process, params, nullParams, win32.SW_SHOW);
    } catch (e) {
      logger.e(e.toString());
    }
  }
}
