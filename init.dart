import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:json_object/json_object.dart';


init(String language) async {
  final dir = await prepare();
  final List<Repo> repos = await getRepoList();
  for(var repo in repos) {
    if (repo.language == language) {
      await cloneRepo(dir, repo.repo);
    }
  }
}

prepare() async {
  var dir = await (new Directory('.wario')).create();
  print(dir.path);
  return dir;
}

getRepoList() async {
  const url = 'https://raw.githubusercontent.com/JustinBeckwith/sloth/master/repos.json';
  final res = await http.get(url);
  print('status: ${res.statusCode}');
  final RepoResponse data = new JsonObject.fromJsonString(res.body);
  return data.repos;
}

cloneRepo(Directory dir, String repo) async {
  var cloneUri = 'git@github.com:${repo}.git';
  print('cloning ${repo}...');
  var results = await Process.run('git', ['clone', cloneUri], workingDirectory: dir.path);
  stderr.writeln(results.stderr);
}

abstract class RepoResponse {
  List<Repo> repos;
}

abstract class Repo {
  String repo;
  String language;
}
