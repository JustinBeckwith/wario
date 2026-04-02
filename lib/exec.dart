import 'dart:io';

import 'config.dart';
import 'process_runner.dart';

const int defaultExecConcurrency = 5;

Future<void> execCommand(
  List<String> params,
  WarioConfig config, {
  ProcessRunner processRunner = runProcess,
  int concurrency = defaultExecConcurrency,
}) async {
  if (params.isEmpty) {
    throw ArgumentError('Provide a command to run after `wario exec --`.');
  }
  if (concurrency < 1) {
    throw ArgumentError.value(
      concurrency,
      'concurrency',
      'Concurrency must be at least 1.',
    );
  }

  final rootDir = Directory(config.cloneDirectory);
  if (!await rootDir.exists()) {
    stderr.writeln(
      'Clone directory ${rootDir.path} does not exist yet. Run `wario sync` first.',
    );
    return;
  }

  final directories = <Directory>[];
  final dirStream = rootDir.list();
  await for (final entity in dirStream) {
    final stat = await entity.stat();
    if (stat.type == FileSystemEntityType.directory && entity is Directory) {
      directories.add(entity);
    }
  }

  var nextIndex = 0;

  Future<void> worker() async {
    while (nextIndex < directories.length) {
      final directory = directories[nextIndex++];
      final results = await processRunner(
        params[0],
        params.sublist(1),
        workingDirectory: directory.path,
      );
      stdout.write(results.stdout);
      stderr.write(results.stderr);
    }
  }

  final workerCount =
      directories.length < concurrency ? directories.length : concurrency;

  await Future.wait([
    for (var i = 0; i < workerCount; i++) worker(),
  ]);
}
