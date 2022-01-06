import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> arguments) async {
  final args = ['pub', ...arguments];
  final projects = await findProjects();

  for (final project in projects) {
    // Skip flutter pub get in example projects since flutter does it anyways
    if (project.engine == Engine.flutter &&
        args.contains('get') &&
        project.example) {
      print('\nSkipping flutter example project: ${project.path}');
      continue;
    }

    print(
      '\nRunning ${project.engine.name} ${args.join(' ')} in ${project.path}',
    );
    final result = Process.runSync(
      project.engine.name,
      args,
      workingDirectory: project.path,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  print('\nDone!');
}

Future<List<Project>> findProjects() async {
  final pubspecEntities = Directory.current.listSync(recursive: true).where(
        (entity) => entity is File && entity.path.endsWith('pubspec.yaml'),
      );

  final projects = <Project>[];
  for (final pubspecEntity in pubspecEntities) {
    final project = await Project.fromPubspecEntity(pubspecEntity);
    projects.add(project);
  }
  return projects;
}

class Project {
  final Engine engine;
  final String path;
  final bool example;

  Project._({required this.engine, required this.path, required this.example});

  static Future<Project> fromPubspecEntity(FileSystemEntity entity) async {
    final pubspec = await loadYaml(File(entity.path).readAsStringSync());

    final Engine engine;
    if (pubspec['environment']['flutter'] != null) {
      engine = Engine.flutter;
    } else {
      engine = Engine.dart;
    }

    final path = entity.parent.path;
    final example = path.endsWith('/example');

    return Project._(
      engine: engine,
      path: path,
      example: example,
    );
  }
}

enum Engine {
  dart,
  flutter,
}
