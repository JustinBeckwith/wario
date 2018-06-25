import 'package:http/http.dart' as http;
import 'package:json_object/json_object.dart';
import 'package:colorize/colorize.dart';

abstract class RepoResponse {
  List<Repo> repos;
}

abstract class Repo {
  String repo;
  String language;
}

Future<List<Repo>> getRepoList() async {
  const url = 'https://raw.githubusercontent.com/JustinBeckwith/sloth/master/repos.json';
  color('Fetching repos from ${url}.', front: Styles.CYAN, isBold: true);
  final res = await http.get(url);
  final RepoResponse data = new JsonObject.fromJsonString(res.body);
  return data.repos;
}
