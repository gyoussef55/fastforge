import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:unified_distributor/src/extensions/string.dart';
import 'package:unified_distributor/src/unified_distributor.dart';

/// Publish an application to a third party provider
///
/// This command wrapper defines, parses and transforms all passed arguments,
/// so that they may be passed to `unified_distributor`. The distributor will
/// then publish an application bundle using `flutter_app_publisher`.
class CommandPublish extends Command {
  CommandPublish(this.distributor) {
    argParser.addOption(
      'path',
      valueHelp: '',
      help: 'The path to the application bundle to publish.',
    );

    argParser.addOption(
      'targets',
      aliases: ['target'],
      valueHelp: [
        'appstore',
        'fir',
        'firebase',
        'github',
        'playstore',
        'pgyer',
        'qiniu',
        'vercel',
      ].join(','),
      help: 'The target provider(s) to publish to.',
    );

    argParser.addOption(
      'app-version',
      valueHelp: '',
      help: [
        'The version of the app',
        'Must follow semantic versioning format, e.g., 1.0.0, 2.1.3-beta.1',
      ].join('\n'),
    );

    // Firebase
    argParser.addSeparator('firebase');

    argParser.addOption(
      'firebase-app',
      valueHelp: '',
      help: [
        'The unique ID of the application on Firebase.',
        'This is NOT your bundle identifier',
      ].join('\n'),
    );

    argParser.addOption(
      'firebase-release-notes',
      valueHelp: '',
      help: 'The release notes for the published application.',
    );

    argParser.addOption(
      'firebase-release-notes-file',
      valueHelp: '',
      help: [
        'The path of a file containing the release notes',
        'This is a more extensive alternative to firebase-release-notes',
      ].join('\n'),
    );

    argParser.addOption(
      'firebase-testers',
      valueHelp: '',
      help:
          'The testers that will be notified about the published application.',
    );

    argParser.addOption(
      'firebase-testers-file',
      valueHelp: '',
      help: [
        'The path of a file containing testers that will be notified',
        'This is a more extensive alternative to firebase-testers',
      ].join('\n'),
    );

    argParser.addOption(
      'firebase-groups',
      valueHelp: '',
      help: 'The groups that will be notified about the published application.',
    );

    argParser.addOption(
      'firebase-groups-file',
      valueHelp: '',
      help: [
        'The path of a file containing groups that will be notified',
        'This is a more extensive alternative to firebase-groups',
      ].join('\n'),
    );

    // Firebase Hosting
    argParser.addSeparator('firebase-hosting');
    argParser.addOption('firebase-hosting-project-id', valueHelp: '');

    // Github
    argParser.addSeparator('github');

    argParser.addOption(
      'github-repo',
      valueHelp: '',
      help: 'The repository to publish to, format: <owner>/<repo>',
    );

    argParser.addOption(
      'github-repo-owner',
      valueHelp: '',
      help:
          '[Deprecated] The name of the target GitHub repository owner (namespace)',
    );

    argParser.addOption(
      'github-repo-name',
      valueHelp: '',
      help: '[Deprecated] The name of the target GitHub repository',
    );

    argParser.addOption(
      'github-release-title',
      valueHelp: '',
      help: 'The title of the new release on GitHub',
    );

    argParser.addOption(
      'github-release-draft',
      valueHelp: 'true|false',
      help: 'Whether to create a draft release',
      defaultsTo: 'false',
    );

    argParser.addOption(
      'github-release-prerelease',
      valueHelp: 'true|false',
      help: 'Whether to create a prerelease',
      defaultsTo: 'false',
    );

    // PlayStore
    argParser.addSeparator('playstore');
    argParser.addOption('playstore-package-name', valueHelp: '');
    argParser.addOption('playstore-track', valueHelp: '');

    // Qiniu
    argParser.addSeparator('qiniu');
    argParser.addOption('qiniu-bucket', valueHelp: '');
    argParser.addOption('qiniu-bucket-domain', valueHelp: '');
    argParser.addOption('qiniu-savekey-prefix', valueHelp: '');

    // Vercel
    argParser.addSeparator('vercel');
    argParser.addOption('vercel-org-id', valueHelp: '');
    argParser.addOption('vercel-project-id', valueHelp: '');
  }

  final UnifiedDistributor distributor;

  @override
  String get name => 'publish';

  @override
  String get description => [
        'Publish the built Flutter application artifacts to distribution platforms',
        '',
        'This command uploads your application bundle to specified target providers',
        'Use --targets to specify one or more distribution platforms',
      ].join('\n');

  @override
  Future run() async {
    String? path = argResults?['path'];
    List<String> targets = '${argResults?['targets'] ?? ''}'
        .split(',')
        .where((t) => t.isNotEmpty)
        .toList();

    // At least `path` and one `targets` is required for flutter build
    if (path == null) {
      print('\nThe \'path\' options is mandatory!'.red(bold: true));
      exit(1);
    }

    if (targets.isEmpty) {
      print('\nAt least one \'target\' must be specified!'.red(bold: true));
      exit(1);
    }

    // Required parameters for firebase
    if (targets.contains('firebase')) {
      if (argResults?['firebase-app'] == null) {
        print('\nFirebase app identifier is required for target \'firebase\'');
        exit(1);
      }
    }

    Map<String, String?> publishArguments = {
      'app-version': argResults?['app-version'],
      'firebase-app': argResults?['firebase-app'],
      'firebase-release-notes': argResults?['firebase-release-notes'],
      'firebase-release-notes-file': argResults?['firebase-release-notes-file'],
      'firebase-testers': argResults?['firebase-testers'],
      'firebase-testers-file': argResults?['firebase-testers-file'],
      'firebase-groups': argResults?['firebase-groups'],
      'firebase-groups-file': argResults?['firebase-groups-file'],
      'firebase-hosting-project-id': argResults?['firebase-hosting-project-id'],
      'github-repo': argResults?['github-repo'],
      'github-repo-owner': argResults?['github-repo-owner'],
      'github-repo-name': argResults?['github-repo-name'],
      'github-release-title': argResults?['github-release-title'],
      'github-release-draft': argResults?['github-release-draft'],
      'github-release-prerelease': argResults?['github-release-prerelease'],
      'playstore-package-name': argResults?['playstore-package-name'],
      'playstore-track': argResults?['playstore-track'],
      'qiniu-bucket': argResults?['qiniu-bucket'],
      'qiniu-bucket-domain': argResults?['qiniu-bucket-domain'],
      'qiniu-savekey-prefix': argResults?['qiniu-savekey-prefix'],
      'vercel-org-id': argResults?['vercel-org-id'],
      'vercel-project-id': argResults?['vercel-project-id'],
    }..removeWhere((key, value) => value == null);

    final fileSystemEntity =
        await FileSystemEntity.type(path) == FileSystemEntityType.directory
            ? Directory(path)
            : File(path);

    return distributor.publish(
      fileSystemEntity,
      targets,
      publishArguments: publishArguments,
    );
  }
}
