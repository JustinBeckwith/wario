import 'dart:convert';
import 'dart:io';
import 'package:colorize/colorize.dart';
import 'package:http/http.dart' as http;
import 'package:github/server.dart';
import './utils.dart';

/**
 * Approve all PRs against tracked repos that match the
 * given title, and have passing status checks.
 */
approve(String title) async {
  var token = Platform.environment['WARIO_GH_TOKEN'];
  if (token == null || token == '') {
    throw 'Wario requires the WARIO_GH_TOKEN environment variable to be set';
  }
  var github = createGitHubClient(auth: new Authentication.withToken(token));
  List<Repo> repos = await getRepoList();
  for (var repo in repos) {
    var parts = repo.repo.split('/');
    var slug = new RepositorySlug(parts[0], parts[1]);
    color('Getting PRs for ${repo.repo} ...', front: Styles.CYAN, isBold: true);
    var prs = github.pullRequests.list(slug);
    await for (var pr in prs) {
      if (pr.title == title && pr.state == 'open') {
        var status = await github.repositories.getCombinedStatus(slug, pr.head.ref);
        if (status.state == 'success') {
          // There does not appear to be an API in this lib for approving PRs 😐
          _approvePR(pr);
        } else {
          color('${pr.htmlUrl} is in a failed state.', front: Styles.RED, isBold: true);
        }
      }
    }
  }
}

_approvePR(PullRequest pr) async {
  var token = Platform.environment['WARIO_GH_TOKEN'];
  var url = 'https://api.github.com/repos/${pr.head.repo.owner.login}/${pr.base.repo.name}/pulls/${pr.number}/reviews?access_token=${token}';
  var body = {
    'commit_id': pr.head.sha,
    'event': 'APPROVE'
  };
  var res = await http.post(url, body: JSON.encode(body));
  if (res.statusCode == 200) {
    color('Approved ${pr.htmlUrl}', front: Styles.GREEN);
  } else {
    color('Error approving PR (${res.statusCode}):', front: Styles.RED, isBold: true);
    color('\t${res.body}', front: Styles.RED, isBold: true);
  }
}
