import 'dart:io';

import 'package:args/args.dart';
import 'package:wario/config.dart';
import 'package:wario/exec.dart';
import 'package:wario/sync.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      help: 'Path to the Wario config file.',
      valueHelp: 'path',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message.',
    );

  parser.addCommand('sync');
  final execParser = parser.addCommand('exec');
  execParser.addOption(
    'concurrency',
    help: 'Maximum number of repositories to process at once.',
    valueHelp: 'count',
    defaultsTo: '$defaultExecConcurrency',
  );

  try {
    final results = parser.parse(arguments);
    final command = results.command;

    if (results['help'] as bool) {
      showUsage(parser);
      return;
    }

    if (command == null) {
      if (results.rest.isNotEmpty) {
        stderr
            .writeln('Could not find a command named "${results.rest.first}".');
        showUsage(parser, exitStatus: 64);
        return;
      }
      showUsage(parser);
      return;
    }

    final config = await WarioConfig.load(
      configPath: results['config'] as String?,
    );

    switch (command.name) {
      case 'sync':
        await syncRepos(config);
        if (!config.exists) {
          exitCode = 64;
        }
        return;
      case 'exec':
        if (command.rest.isEmpty) {
          stderr.writeln('Provide a command after `wario exec --`.');
          exitCode = 64;
          return;
        }
        final concurrency = int.parse(command['concurrency'] as String);
        if (concurrency < 1) {
          stderr.writeln('The --concurrency value must be at least 1.');
          exitCode = 64;
          return;
        }
        await execCommand(
          command.rest,
          config,
          concurrency: concurrency,
        );
        return;
      default:
        showUsage(parser, exitStatus: 64);
        return;
    }
  } on ArgParserException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  } on FormatException catch (error) {
    stderr.writeln('Invalid config: $error');
    exitCode = 64;
  }
}

void showUsage(
  ArgParser parser, {
  int exitStatus = 0,
}) {
  stdout.writeln('''
Usage: wario <command> [options]

Commands:
  sync       Clone or update all repositories
  exec       Run a command in each repository

Options:
${parser.usage}
''');
  exitCode = exitStatus;
}
