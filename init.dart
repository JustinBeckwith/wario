import 'dart:io';
import 'package:colorize/colorize.dart';
import './utils.dart';

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

cloneRepo(Directory dir, String repo) async {
  var cloneUri = 'git@github.com:${repo}.git';
  color('Cloning ${repo} ...', front: Styles.CYAN);
  var results = await Process.run('git', ['clone', cloneUri], workingDirectory: dir.path);
  if (results.exitCode != 0) {
    color('Error cloning ${repo}', front: Styles.RED, isBold: true);
    color(results.stderr, front: Styles.RED, isBold: true);
  }
}
