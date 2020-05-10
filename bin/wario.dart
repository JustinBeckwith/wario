import 'dart:io';
import '../lib/init.dart';
import '../lib/exec.dart';

void main(List<String> arguments) {
  if (arguments.length == 0) {
    showUsage();
  }
  print(arguments);
  final command = arguments[0];
  switch(command) {
    case 'init':
      final language = arguments[2];
      init(language);
      break;
    case 'exec':
      final cmd = arguments.sublist(2);
      exec(cmd);
      break;
  }
}

void showUsage() {
  print(
'''\$ wario
  - init       Clone all repositories
  - exec       Run a command in each directory
  - reset      Fetch all upstreams, and perform a hard reset
''');
  exit(-1);
}
