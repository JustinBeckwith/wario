import 'dart:io';

exec(List<String> params) async {
  final rootDir = new Directory('.wario');
  final dirStream = rootDir.list();
  await for (var entity in dirStream) {
    final stat = await entity.stat();
    if (stat.type == FileSystemEntityType.directory) {
      var results = await Process.run(params[0], params.sublist(1), workingDirectory: entity.path);
      stdout.write(results.stdout);
      stderr.write(results.stderr);
    }
  }
}
