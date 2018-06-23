import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main(List<String> arguments) {
  if (arguments.length == 0) {
    showUsage();
  }
  print(arguments);
  var command = arguments[0];
  switch(command) {
    case 'init':
      init();
      break;
  }
}

void showUsage() {
  print(
'''\$ wario
  - init   Clone all repositories
  - reset  Fetch all upstreams, and perform a hard reset
''');
  exit(-1);
}

init() async {
  const url = 'https://raw.githubusercontent.com/JustinBeckwith/sloth/master/repos.json';
  var res = await http.get(url);
  print('status: ${res.statusCode}');
  RepoResponse data = JSON.decode(res.body);
  print(data);
}

abstract class RepoResponse {
  List<Repo> repos;
}

abstract class Repo {
  String repo;
  String language;
}
