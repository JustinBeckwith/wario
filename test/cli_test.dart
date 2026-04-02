import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  final repoRoot = Directory.current.path;
  final entrypoint = path.join(repoRoot, 'bin', 'wario.dart');

  test('shows help for supported commands', () async {
    final result = await Process.run('dart', [entrypoint, '--help']);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('sync'));
    expect(result.stdout, contains('exec'));
    expect(result.stdout, isNot(contains('init')));
  });

  test('rejects the removed init command', () async {
    final result = await Process.run('dart', [entrypoint, 'init']);

    expect(result.exitCode, 64);
    expect(result.stderr, contains('Could not find a command named "init"'));
  });

  test('sync warns when the default config file is missing', () async {
    final tempHome = await Directory.systemTemp.createTemp('wario-home-');

    final result = await Process.run(
      'dart',
      [entrypoint, 'sync'],
      environment: {
        ...Platform.environment,
        'HOME': tempHome.path,
      },
    );

    expect(result.exitCode, 64);
    expect(result.stderr, contains('No config file was found'));
    expect(result.stderr, contains('.wario.json'));
  });

  test('rejects invalid exec concurrency values', () async {
    final result = await Process.run(
      'dart',
      [entrypoint, 'exec', '--concurrency', '0', '--', 'git', 'status'],
    );

    expect(result.exitCode, 64);
    expect(result.stderr, contains('--concurrency'));
  });
}
