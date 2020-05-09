import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:colorize/colorize.dart';

class Repo {
  String repo;
  String language;
  Repo(this.repo, this.language);
  factory Repo.fromJson(dynamic json) {
    return Repo(json['repo'] as String, json['language'] as String);
  }

}

Future<List<Repo>> getRepoList() async {
  const url = 'https://raw.githubusercontent.com/googleapis/sloth/master/repos.json';
  color('Fetching repos from ${url}.', front: Styles.CYAN, isBold: true);
  final res = await http.get(url);
  var reposJson = jsonDecode(res.body)['repos'] as List;
  List<Repo> repos = reposJson.map((repo) => Repo.fromJson(repo)).toList();
  return repos;
}
