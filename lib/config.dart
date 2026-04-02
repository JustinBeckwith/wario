import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const String defaultConfigPath = '~/.wario.json';
const String defaultCloneDirectory = '~/.wario';

class WarioConfig {
  const WarioConfig({
    required this.cloneDirectory,
    required this.repos,
    required this.org,
    required this.filter,
    required this.configPath,
    required this.exists,
  });

  final String cloneDirectory;
  final List<String> repos;
  final String? org;
  final String filter;
  final String configPath;
  final bool exists;

  bool get usesRepoList => repos.isNotEmpty;

  bool get usesOrgSearch => org != null;

  static Future<WarioConfig> load({
    String? configPath,
    String? homeDirectory,
  }) async {
    final home = _resolveHomeDirectory(homeDirectory);
    final resolvedConfigPath = _expandHome(
      configPath ?? defaultConfigPath,
      homeDirectory: home,
    );
    final file = File(resolvedConfigPath);

    if (!await file.exists()) {
      return WarioConfig.defaults(
        configPath: resolvedConfigPath,
        homeDirectory: home,
      );
    }

    final rawConfig = jsonDecode(await file.readAsString());
    if (rawConfig is! Map) {
      throw const FormatException('Config must be a JSON object.');
    }

    return WarioConfig.fromJson(
      Map<String, dynamic>.from(rawConfig),
      configPath: resolvedConfigPath,
      homeDirectory: home,
    );
  }

  factory WarioConfig.fromJson(
    Map<String, dynamic> json, {
    required String configPath,
    required String homeDirectory,
  }) {
    final cloneDirectory = _expandHome(
      (json['cloneDir'] ?? json['cloneDirectory'] ?? defaultCloneDirectory)
          .toString(),
      homeDirectory: homeDirectory,
    );
    final repos = _parseRepos(json['repos']);
    final org = _parseOptionalString(json['org']);
    final filter = _parseOptionalString(json['filter']) ?? '';

    if (repos.isNotEmpty && org != null) {
      throw const FormatException(
        'Config must define either "repos" or "org", but not both.',
      );
    }

    if (repos.isEmpty && org == null) {
      throw const FormatException(
        'Config must define either "repos" or "org".',
      );
    }

    return WarioConfig(
      cloneDirectory: path.normalize(cloneDirectory),
      repos: repos,
      org: org,
      filter: filter,
      configPath: configPath,
      exists: true,
    );
  }

  factory WarioConfig.defaults({
    required String configPath,
    required String homeDirectory,
  }) {
    return WarioConfig(
      cloneDirectory: path.normalize(
        _expandHome(defaultCloneDirectory, homeDirectory: homeDirectory),
      ),
      repos: const [],
      org: null,
      filter: '',
      configPath: configPath,
      exists: false,
    );
  }
}

List<String> _parseRepos(dynamic rawRepos) {
  if (rawRepos == null) {
    return const [];
  }

  if (rawRepos is! List) {
    throw const FormatException('The "repos" field must be a list.');
  }

  return rawRepos.map((repo) {
    if (repo is String) {
      return repo;
    }

    if (repo is Map && repo['repo'] is String) {
      return repo['repo'] as String;
    }

    throw const FormatException(
      'Each repo entry must be a string or an object with a "repo" field.',
    );
  }).toList(growable: false);
}

String? _parseOptionalString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }

  return text;
}

String _resolveHomeDirectory(String? homeDirectory) {
  return homeDirectory ??
      Platform.environment['HOME'] ??
      Directory.current.absolute.path;
}

String _expandHome(
  String value, {
  required String homeDirectory,
}) {
  if (value == '~') {
    return homeDirectory;
  }

  if (value.startsWith('~/')) {
    return path.join(homeDirectory, value.substring(2));
  }

  return value;
}
