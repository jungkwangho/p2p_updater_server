import 'dart:io';
import 'package:intl/intl.dart';

class SimpleLog {
  SimpleLog();

  late File logfile;
  late DateFormat timestampFormat;

  void initLogger(String logpath) {
    logfile = File(logpath);
    timestampFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
  }

  void write(String level, String data) {
    final now = DateTime.now();
    logfile.writeAsStringSync(
        "[${timestampFormat.format(now)}.${now.millisecond.toString().padLeft(3, "0")}][$level] $data\n",
        mode: FileMode.append,
        flush: false);
  }

  void d(String data) {
    write("DEBUG", data);
  }

  void t(String data) {
    write("TRACE", data);
  }

  void i(String data) {
    write("INFO ", data);
  }

  void w(String data) {
    write("WARN ", data);
  }

  void e(String data) {
    write("ERROR", data);
  }

  void f(String data) {
    write("FATAL", data);
  }
}

final logger = SimpleLog();
