import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:json_object/json_object.dart';

void main(List<String> arguments) {
  if (arguments.length == 0) {
    showUsage();
  }
  print(arguments);
  final command = arguments[0];
  final language = arguments[2];
  switch(command) {
    case 'init':
      init(language);
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

init(String language) async {
  const url = 'https://raw.githubusercontent.com/JustinBeckwith/sloth/master/repos.json';
  final res = await http.get(url);
  print('status: ${res.statusCode}');
  final RepoResponse data = new JsonObject.fromJsonString(res.body);
  for(var repo in data.repos) {
    if (repo.language == language) {
      print(repo.repo);
    }
  }
}

abstract class RepoResponse {
  List<Repo> repos;
}

abstract class Repo {
  String repo;
  String language;
}
