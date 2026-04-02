import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:wario/config.dart';

void main() {
  group('WarioConfig.load', () {
    test('uses home directory defaults when the config file does not exist',
        () async {
      final tempHome = await Directory.systemTemp.createTemp('wario-home-');

      final config = await WarioConfig.load(homeDirectory: tempHome.path);

      expect(config.configPath, path.join(tempHome.path, '.wario.json'));
      expect(config.cloneDirectory, path.join(tempHome.path, '.wario'));
      expect(config.repos, isEmpty);
      expect(config.org, isNull);
      expect(config.filter, isEmpty);
      expect(config.exists, isFalse);
    });

    test('loads repos and ignores legacy language fields', () async {
      final tempHome = await Directory.systemTemp.createTemp('wario-home-');
      final configFile = File(path.join(tempHome.path, '.wario.json'));

      await configFile.writeAsString('''
{
  "cloneDir": "~/.workspace/wario",
  "repos": [
    "dart-lang/sdk",
    {
      "repo": "google/wireit",
      "language": "nodejs"
    }
  ]
}
''');

      final config = await WarioConfig.load(homeDirectory: tempHome.path);

      expect(
        config.cloneDirectory,
        path.join(tempHome.path, '.workspace', 'wario'),
      );
      expect(config.repos, ['dart-lang/sdk', 'google/wireit']);
      expect(config.usesRepoList, isTrue);
      expect(config.usesOrgSearch, isFalse);
    });

    test('loads an org and filter config', () async {
      final tempHome = await Directory.systemTemp.createTemp('wario-home-');
      final configFile = File(path.join(tempHome.path, '.wario.json'));

      await configFile.writeAsString('''
{
  "org": "promptfoo",
  "filter": "archived:false"
}
''');

      final config = await WarioConfig.load(homeDirectory: tempHome.path);

      expect(config.org, 'promptfoo');
      expect(config.filter, 'archived:false');
      expect(config.usesRepoList, isFalse);
      expect(config.usesOrgSearch, isTrue);
    });

    test('rejects configs that define repos and org together', () async {
      final tempHome = await Directory.systemTemp.createTemp('wario-home-');
      final configFile = File(path.join(tempHome.path, '.wario.json'));

      await configFile.writeAsString('''
{
  "repos": ["dart-lang/sdk"],
  "org": "promptfoo",
  "filter": "archived:false"
}
''');

      expect(
        () => WarioConfig.load(homeDirectory: tempHome.path),
        throwsFormatException,
      );
    });
  });
}
