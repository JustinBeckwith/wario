import 'dart:convert';

import 'package:nock/nock.dart';
import 'package:test/test.dart';
import '../lib/utils.dart' as util;

void main() {
  setUpAll(() {
    nock.init();
  });
  setUp(() {
    nock.cleanAll();
  });
  test('should get repo list', () async {
    dynamic jsonResponse = {
      'repos': [
        {
          'repo': 'JustinBeckwith/wario',
          'language': 'dart'
        }
      ]
    };
    final interceptor = nock(util.host).get(util.path)
      ..replay(
        200,
        jsonEncode(jsonResponse),
      );
    final list = await util.getRepoList();
    expect(interceptor.isDone, true);
    expect(list.length, 1);
  });
}
