import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wario/config.dart';
import 'package:wario/utils.dart';

void main() {
  test('fetches repo list from GitHub org search', () async {
    final client = MockClient((request) async {
      expect(request.url.host, gitHubApiHost);
      expect(request.url.path, gitHubSearchRepositoriesPath);
      expect(request.url.queryParameters['q'], 'org:promptfoo archived:false');
      return http.Response('''
{
  "items": [
    {"full_name": "promptfoo/promptfoo"},
    {"full_name": "promptfoo/promptfoo-site"}
  ]
}
''', 200);
    });

    final repos = await getRepoList(
      WarioConfig(
        cloneDirectory: '/tmp/.wario',
        repos: const [],
        org: 'promptfoo',
        filter: 'archived:false',
        configPath: '/tmp/.wario.json',
        exists: true,
      ),
      client: client,
    );

    expect(repos.map((repo) => repo.repo).toList(), [
      'promptfoo/promptfoo',
      'promptfoo/promptfoo-site',
    ]);
  });

  test('sends auth headers when a GitHub token is available', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer test-token');
      return http.Response('''
{
  "items": [
    {"full_name": "promptfoo/promptfoo"}
  ]
}
''', 200);
    });

    final repos = await getRepoList(
      WarioConfig(
        cloneDirectory: '/tmp/.wario',
        repos: const [],
        org: 'promptfoo',
        filter: 'archived:false',
        configPath: '/tmp/.wario.json',
        exists: true,
      ),
      client: client,
      githubToken: 'test-token',
    );

    expect(repos.map((repo) => repo.repo).toList(), ['promptfoo/promptfoo']);
  });

  test('uses the token resolver when no explicit token is provided', () async {
    final client = MockClient((request) async {
      expect(request.headers['authorization'], 'Bearer gh-token');
      return http.Response('''
{
  "items": [
    {"full_name": "promptfoo/promptfoo"}
  ]
}
''', 200);
    });

    final repos = await getRepoList(
      WarioConfig(
        cloneDirectory: '/tmp/.wario',
        repos: const [],
        org: 'promptfoo',
        filter: 'archived:false',
        configPath: '/tmp/.wario.json',
        exists: true,
      ),
      client: client,
      githubTokenResolver: () async => 'gh-token',
    );

    expect(repos.map((repo) => repo.repo).toList(), ['promptfoo/promptfoo']);
  });
}
