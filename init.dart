import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:json_object/json_object.dart';
import 'package:colorize/colorize.dart';

init(String language) async {
  final dir = await prepare();
  final List<Repo> repos = await getRepoList();
  color('Cloning ${repos.length} repos into ${dir.path}...', front: Styles.CYAN, isBold: true);
  for(var repo in repos) {
    if (repo.language == language) {
      await cloneRepo(dir, repo.repo);
    }
  }
}

prepare() async {
  var root = new Directory('.wario');
  var exists = await root.exists();
  if (!exists) {
    root = await (new Directory('.wario')).create();
    color('Created directory ${root.path}.', front: Styles.CYAN, isBold: true);
  }
  return root;
}

getRepoList() async {
  const url = 'https://raw.githubusercontent.com/JustinBeckwith/sloth/master/repos.json';
  color('Fetching repos from ${url}.', front: Styles.CYAN, isBold: true);
  final res = await http.get(url);
  final RepoResponse data = new JsonObject.fromJsonString(res.body);
  return data.repos;
}

cloneRepo(Directory dir, String repo) async {
  var cloneUri = 'git@github.com:${repo}.git';
  color('Cloning ${repo} ...', front: Styles.CYAN);
  var results = await Process.run('git', ['clone', cloneUri], workingDirectory: dir.path);
  if (results.exitCode != 0) {
    color('Error cloning ${repo}', front: Styles.RED, isBold: true);
    color(results.stderr, front: Styles.RED, isBold: true);
  }
}

abstract class RepoResponse {
  List<Repo> repos;
}

abstract class Repo {
  String repo;
  String language;
}
