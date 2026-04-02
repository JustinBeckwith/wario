import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'config.dart';

const String gitHubApiHost = 'api.github.com';
const String gitHubSearchRepositoriesPath = '/search/repositories';
typedef GitHubTokenResolver = Future<String?> Function();

class Repo {
  const Repo(this.repo);

  final String repo;

  factory Repo.fromJson(dynamic json) {
    if (json is String) {
      return Repo(json);
    }

    if (json is Map && json['repo'] is String) {
      return Repo(json['repo'] as String);
    }

    throw const FormatException(
      'Repo entries must be strings or objects with a "repo" field.',
    );
  }
}

Future<List<Repo>> getRepoList(
  WarioConfig config, {
  http.Client? client,
  String? githubToken,
  GitHubTokenResolver? githubTokenResolver,
}) async {
  if (config.usesRepoList) {
    return config.repos.map(Repo.new).toList(growable: false);
  }

  if (!config.usesOrgSearch) {
    throw const FormatException(
      'Config must define either a repo list or an org search.',
    );
  }

  final httpClient = client ?? http.Client();
  try {
    return await _searchOrgRepos(
      config,
      client: httpClient,
      githubToken: githubToken,
      githubTokenResolver: githubTokenResolver,
    );
  } finally {
    if (client == null) {
      httpClient.close();
    }
  }
}

Future<List<Repo>> _searchOrgRepos(
  WarioConfig config, {
  required http.Client client,
  String? githubToken,
  GitHubTokenResolver? githubTokenResolver,
}) async {
  final repos = <Repo>[];
  final token =
      githubToken ?? await (githubTokenResolver ?? _githubToken).call();
  final query = [
    'org:${config.org}',
    if (config.filter.trim().isNotEmpty) config.filter.trim(),
  ].join(' ');

  stdout.writeln('Searching GitHub repos with `$query`.');
  if (token == null) {
    stderr.writeln(
      'GitHub auth token not found. Set WARIO_GH_TOKEN, GH_TOKEN, or '
      'GITHUB_TOKEN, or sign in with `gh auth login`, to include private or '
      'internal repositories in org searches.',
    );
  }

  for (var page = 1; page <= 10; page++) {
    final uri = Uri.https(gitHubApiHost, gitHubSearchRepositoriesPath, {
      'q': query,
      'per_page': '100',
      'page': '$page',
    });

    final response =
        await client.get(uri, headers: _githubHeaders(token: token));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to search GitHub repositories: ${response.statusCode}',
        uri: uri,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['items'] is! List) {
      throw const FormatException(
        'GitHub search response must contain an "items" list.',
      );
    }

    final items = (decoded['items'] as List)
        .map((repo) => Repo.fromJson({'repo': repo['full_name']}))
        .toList(growable: false);
    repos.addAll(items);

    if (items.length < 100) {
      break;
    }
  }

  return repos;
}

Map<String, String> _githubHeaders({String? token}) {
  final headers = <String, String>{
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'wario',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  if (token != null && token.trim().isNotEmpty) {
    headers['Authorization'] = 'Bearer ${token.trim()}';
  }

  return headers;
}

Future<String?> _githubToken() async {
  for (final name in ['WARIO_GH_TOKEN', 'GH_TOKEN', 'GITHUB_TOKEN']) {
    final value = Platform.environment[name];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return _githubCliToken();
}

Future<String?> _githubCliToken() async {
  try {
    final result = await Process.run('gh', ['auth', 'token']);
    if (result.exitCode != 0) {
      return null;
    }

    final token = result.stdout.toString().trim();
    if (token.isEmpty) {
      return null;
    }

    return token;
  } on ProcessException {
    return null;
  }
}
