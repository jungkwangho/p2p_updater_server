import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:p2p_updater_client/installed.dart';
import 'package:http/http.dart' as http;
import 'package:p2p_updater_client/util.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:p2p_updater_client/simplelog.dart';

class UpdateCheckRequest {
  const UpdateCheckRequest(
      {required this.type,
      required this.hash,
      required this.name,
      required this.version});

  final String type;
  final String hash;
  final String name;
  final String version;

  factory UpdateCheckRequest.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'type': String type,
        'hash': String hash,
        'name': String name,
        'version': String version,
      } =>
        UpdateCheckRequest(
          type: type2ServerType(type),
          hash: hash,
          name: name,
          version: version,
        ),
      _ => throw Exception('Failed to parse UpdateCheckRequest'),
    };
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'hash': hash,
        'name': name,
        'version': version,
      };
}

class UpdateCheckResponse {
  const UpdateCheckResponse(
      {required this.result,
      required this.msg,
      required this.type,
      required this.hash,
      required this.name,
      required this.version});

  final int result;
  final String msg;
  final String type;
  final String hash;
  final String name;
  final String version;

  factory UpdateCheckResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'result': int result,
        'msg': String msg,
        'type': String type,
        'hash': String hash,
        'name': String name,
        'version': String version,
      } =>
        UpdateCheckResponse(
          result: result,
          msg: msg,
          type: type,
          hash: hash,
          name: name,
          version: version,
        ),
      _ => throw Exception('Failed to parse UpdateCheckResponse'),
    };
  }

  Map<String, dynamic> toJson() => {
        'result': result,
        'msg': msg,
        'type': type,
        'hash': hash,
        'name': name,
        'version': version,
      };
}

class UpdateRequest {
  const UpdateRequest({required this.hash});

  final String hash;

  factory UpdateRequest.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'hash': String hash,
      } =>
        UpdateRequest(
          hash: hash,
        ),
      _ => throw Exception('Failed to parse UpdateRequest'),
    };
  }

  Map<String, dynamic> toJson() => {
        'hash': hash,
      };
}

class UpdateFile {
  UpdateFile({required this.hash, required this.downloadPath});

  final String hash;
  final String downloadPath;
  late int executeResult;
  late String errorMsg;
}

class ReportFile {
  const ReportFile(
      {required this.type,
      required this.hash,
      required this.name,
      required this.version});

  final String type;
  final String hash;
  final String name;
  final String version;

  factory ReportFile.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'type': String type,
        'hash': String hash,
        'name': String name,
        'version': String version,
      } =>
        ReportFile(
          type: type,
          hash: hash,
          name: name,
          version: version,
        ),
      _ => throw Exception('Failed to parse ReportFile'),
    };
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'hash': hash,
        'name': name,
        'version': version,
      };
}

class Report {
  const Report(
      {required this.oldF,
      required this.newF,
      required this.userId,
      required this.ip,
      required this.errCode,
      required this.errMsg});

  final ReportFile oldF;
  final ReportFile newF;
  final String userId;
  final String ip;
  final String errCode;
  final String errMsg;
  factory Report.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'old': ReportFile oldF,
        'new': ReportFile newF,
        'user_id': String userId,
        'ip': String ip,
        'err_code': String errCode,
        'err_msg': String errMsg,
      } =>
        Report(
          oldF: oldF,
          newF: newF,
          userId: userId,
          ip: ip,
          errCode: errCode,
          errMsg: errMsg,
        ),
      _ => throw Exception('Failed to parse Report'),
    };
  }

  Map<String, dynamic> toJson() => {
        'old': oldF,
        'new': newF,
        'user_id': userId,
        'ip': ip,
        'err_code': errCode,
        'err_msg': errMsg,
      };
}

class Updates {
  Updates({required this.urlbase, required this.installed});

  String urlbase;
  Installed installed;
  List<UpdateCheckResponse> checkResults = [];
  List<UpdateFile> updateFiles = [];

  Future<void> checkUpdates() async {
    for (var i = 0; i < installed.targets.length; i++) {
      final target = installed.targets[i];

      final updateCheckReq = UpdateCheckRequest(
          type: type2ServerType(target.type),
          hash: target.hash,
          name: target.name,
          version: target.version);

      http.Response? response;
      try {
        response = await http.post(
          Uri.parse('$urlbase/updatecheck'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(updateCheckReq),
        );
      } catch (e) {
        response = null;
      }

      late UpdateCheckResponse updateCheckRes;
      if (response == null) {
        updateCheckRes = UpdateCheckResponse(
            result: -1,
            msg: "Exception while request updatecheck",
            type: '',
            hash: '',
            name: updateCheckReq.name,
            version: updateCheckReq.version);
      } else {
        if (response.statusCode == 200) {
          updateCheckRes =
              UpdateCheckResponse.fromJson(jsonDecode(response.body));
        } else {
          updateCheckRes = UpdateCheckResponse(
              result: response.statusCode,
              msg: response.body,
              type: '',
              hash: '',
              name: updateCheckReq.name,
              version: updateCheckReq.version);
        }
      }

      checkResults.add(updateCheckRes);
    }
  }

  Future<void> downloadUpdates() async {
    for (var i = 0; i < checkResults.length; i++) {
      final todownload = checkResults[i];

      final updateReq = UpdateRequest(hash: todownload.hash);

      http.Response? response;
      // TODO: todownload.result 가 -1인지 확인해야 할까?
      try {
        response = await http.post(
          Uri.parse('$urlbase/update'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(updateReq),
        );
      } catch (e) {
        response = null;
      }

      late UpdateFile downloaded;
      if (response == null) {
        downloaded = UpdateFile(hash: todownload.hash, downloadPath: '');
        downloaded.errorMsg = 'Exception while request update';
      } else {
        if (response.statusCode == 200) {
          final hash = sha256.convert(response.bodyBytes);
          // 해쉬 일치 여부 확인
          if (hash.toString() == todownload.hash) {
            // 일치할 경우 파일로 저장
            final tempdir = await getApplicationDocumentsDirectory();
            final temppath =
                await getDownloadPath(tempdir.path, todownload.name);

            final f = await File(temppath).writeAsBytes(response.bodyBytes);
            final b = await f.exists();
            if (b) {
              downloaded =
                  UpdateFile(hash: todownload.hash, downloadPath: temppath);
              downloaded.errorMsg = '';
            } else {
              downloaded =
                  UpdateFile(hash: todownload.hash, downloadPath: temppath);
              downloaded.errorMsg = 'Deleted after download';
            }
          } else {
            downloaded = UpdateFile(hash: todownload.hash, downloadPath: '');
            downloaded.errorMsg = 'Download failed';
          }
        } else {
          downloaded = UpdateFile(hash: todownload.hash, downloadPath: '');
          downloaded.errorMsg = '${response.statusCode}: ${response.body}';
        }
      }

      updateFiles.add(downloaded);
    }
  }

  Future<void> executeUpdates() async {
    for (var i = 0; i < updateFiles.length; i++) {
      final updateFile = updateFiles[i];
      if (updateFile.errorMsg == '') {
        // 패키지 타입만 실행한다
        if (checkResults[i].type == "P") {
          final proc = await Process.start(updateFile.downloadPath, [],
              runInShell: true); // run하고 차이가 뭘까?

          updateFile.executeResult = await proc.exitCode;
        } else {
          updateFile.executeResult = 0; // don't execute, so result is 0
        }
      } else {
        updateFile.executeResult = -1;
      }
    }
  }

  (String, String) composeErrorInfo(
      UpdateCheckResponse checkResp, UpdateFile executeRes) {
    if (checkResp.result != 0) {
      return ('${checkResp.result}', checkResp.msg);
    } else if (executeRes.executeResult != 0) {
      return ('${executeRes.executeResult}', executeRes.errorMsg);
    } else {
      return ('0', '');
    }
  }

  Future<void> reportResults() async {
    for (var i = 0; i < updateFiles.length; i++) {
      final target = installed.targets[i];
      final checked = checkResults[i];
      final executed = updateFiles[i];

      final oldF = ReportFile(
          type: type2ServerType(target.type),
          hash: target.hash,
          name: target.name,
          version: target.version);

      final newF = ReportFile(
          type: checked.type,
          hash: checked.hash,
          name: checked.name,
          version: checked.version);

      final userId = getUserId();
      final ip = await getIp(true);
      final (errCode, errMsg) = composeErrorInfo(checked, executed);

      final report = Report(
          oldF: oldF,
          newF: newF,
          userId: userId,
          ip: ip,
          errCode: errCode,
          errMsg: errMsg);

      try {
        await http.post(
          Uri.parse('$urlbase/report'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(report),
        );
      } catch (e) {
        logger.f("An exception occured when trying report");
      }
    }
  }
}
