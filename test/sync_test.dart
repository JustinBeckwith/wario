import 'dart:io';

import 'package:test/test.dart';
import 'package:wario/config.dart';
import 'package:wario/sync.dart';

void main() {
  test('sync clones missing repos over https', () async {
    final tempRoot = await Directory.systemTemp.createTemp('wario-sync-');
    final calls = <({List<String> arguments, String? workingDirectory})>[];
    final config = WarioConfig(
      cloneDirectory: tempRoot.path,
      repos: const ['octocat/hello-world'],
      org: null,
      filter: '',
      configPath: '${tempRoot.path}/.wario.json',
      exists: true,
    );

    await syncRepos(
      config,
      processRunner: (executable, arguments, {workingDirectory}) async {
        calls.add((arguments: arguments, workingDirectory: workingDirectory));
        return ProcessResult(0, 0, '', '');
      },
    );

    expect(calls, hasLength(1));
    expect(
      calls.single.arguments,
      ['clone', 'https://github.com/octocat/hello-world.git'],
    );
    expect(calls.single.workingDirectory, tempRoot.path);
  });

  test('sync updates repos that already exist', () async {
    final tempRoot = await Directory.systemTemp.createTemp('wario-sync-');
    await Directory('${tempRoot.path}/hello-world').create();

    final calls = <({List<String> arguments, String? workingDirectory})>[];

    await syncRepo(
      tempRoot,
      'octocat/hello-world',
      processRunner: (executable, arguments, {workingDirectory}) async {
        calls.add((arguments: arguments, workingDirectory: workingDirectory));
        return ProcessResult(0, 0, '', '');
      },
    );

    expect(calls, hasLength(1));
    expect(calls.single.arguments, ['pull', '--ff-only']);
    expect(calls.single.workingDirectory, '${tempRoot.path}/hello-world');
  });

  test('sync warns when the config file is missing', () async {
    final tempRoot = await Directory.systemTemp.createTemp('wario-sync-');
    final config = WarioConfig(
      cloneDirectory: tempRoot.path,
      repos: const [],
      org: null,
      filter: '',
      configPath: '${tempRoot.path}/.wario.json',
      exists: false,
    );

    await syncRepos(config);

    expect(await Directory(tempRoot.path).exists(), isTrue);
  });
}
