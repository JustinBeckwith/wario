import 'dart:convert';
import 'package:http/http.dart' show Client;
import 'package:colorize/colorize.dart';

class Repo {
  String repo;
  String language;
  Repo(this.repo, this.language);
  factory Repo.fromJson(dynamic json) {
    return Repo(json['repo'] as String, json['language'] as String);
  }
}

const host = 'https://raw.githubusercontent.com';
const path = "/googleapis/sloth/master/repos.json";
const url = host + path;

Future<List<Repo>> getRepoList() async {
  color('Fetching repos from ${url}.', front: Styles.CYAN, isBold: true);
  final client = new Client();
  final res = await client.get(url);
  final reposJson = jsonDecode(res.body)['repos'] as List;
  final repos = reposJson.map((repo) => Repo.fromJson(repo)).toList();
  return repos;
}
