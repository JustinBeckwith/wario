import 'dart:io';

import 'package:test/test.dart';
import 'package:wario/config.dart';
import 'package:wario/exec.dart';

void main() {
  test('runs the provided command in each subdirectory', () async {
    final tempRoot = await Directory.systemTemp.createTemp('wario-exec-');
    await Directory('${tempRoot.path}/alpha').create();
    await Directory('${tempRoot.path}/beta').create();
    await File('${tempRoot.path}/README.md').writeAsString('ignore me');

    final workingDirectories = <String?>[];
    final config = WarioConfig(
      cloneDirectory: tempRoot.path,
      repos: const [],
      org: 'promptfoo',
      filter: 'archived:false',
      configPath: '${tempRoot.path}/.wario.json',
      exists: true,
    );

    await execCommand(
      ['git', 'status'],
      config,
      processRunner: (executable, arguments, {workingDirectory}) async {
        workingDirectories.add(workingDirectory);
        return ProcessResult(0, 0, '', '');
      },
    );

    expect(
        workingDirectories, containsAll([contains('alpha'), contains('beta')]));
    expect(workingDirectories, hasLength(2));
  });

  test('limits the number of concurrent executions', () async {
    final tempRoot = await Directory.systemTemp.createTemp('wario-exec-');
    for (final name in ['alpha', 'beta', 'gamma', 'delta']) {
      await Directory('${tempRoot.path}/$name').create();
    }

    final config = WarioConfig(
      cloneDirectory: tempRoot.path,
      repos: const [],
      org: 'promptfoo',
      filter: 'archived:false',
      configPath: '${tempRoot.path}/.wario.json',
      exists: true,
    );

    var active = 0;
    var maxActive = 0;

    await execCommand(
      ['git', 'status'],
      config,
      concurrency: 2,
      processRunner: (executable, arguments, {workingDirectory}) async {
        active++;
        if (active > maxActive) {
          maxActive = active;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
        active--;
        return ProcessResult(0, 0, '', '');
      },
    );

    expect(maxActive, 2);
  });

  test('rejects invalid concurrency values', () async {
    final tempRoot = await Directory.systemTemp.createTemp('wario-exec-');
    final config = WarioConfig(
      cloneDirectory: tempRoot.path,
      repos: const [],
      org: 'promptfoo',
      filter: 'archived:false',
      configPath: '${tempRoot.path}/.wario.json',
      exists: true,
    );

    await expectLater(
      () => execCommand(
        ['git', 'status'],
        config,
        concurrency: 0,
      ),
      throwsArgumentError,
    );
  });
}
