import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'config.dart';
import 'process_runner.dart';
import 'utils.dart';

Future<void> syncRepos(
  WarioConfig config, {
  http.Client? client,
  ProcessRunner processRunner = runProcess,
}) async {
  if (!config.exists) {
    stderr.writeln(
      'No config file was found at ${config.configPath}. '
      'Please create it with either a "repos" list or an "org" plus "filter" '
      'before running `wario sync`.',
    );
    return;
  }

  final dir = await prepare(config.cloneDirectory);
  final repos = await getRepoList(config, client: client);

  stdout.writeln('Syncing ${repos.length} repos into ${dir.path}...');
  for (final repo in repos) {
    await syncRepo(
      dir,
      repo.repo,
      processRunner: processRunner,
    );
  }
}

Future<Directory> prepare(String rootPath) async {
  final root = Directory(rootPath);
  if (!await root.exists()) {
    await root.create(recursive: true);
    stdout.writeln('Created directory ${root.path}.');
  }
  return root;
}

Future<void> syncRepo(
  Directory dir,
  String repo, {
  ProcessRunner processRunner = runProcess,
}) async {
  final repoDirectory = Directory(path.join(dir.path, repo.split('/').last));
  late final ProcessResult results;

  if (await repoDirectory.exists()) {
    stdout.writeln('Updating $repo ...');
    results = await processRunner(
      'git',
      ['pull', '--ff-only'],
      workingDirectory: repoDirectory.path,
    );
  } else {
    final cloneUri = Uri.https('github.com', '/$repo.git').toString();
    stdout.writeln('Cloning $repo ...');
    results = await processRunner(
      'git',
      ['clone', cloneUri],
      workingDirectory: dir.path,
    );
  }

  if (results.exitCode != 0) {
    stderr.writeln('Error syncing $repo');
    stderr.writeln(results.stderr);
  }
}
