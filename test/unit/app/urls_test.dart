import 'package:flutter_test/flutter_test.dart';
import 'package:nodepulse/data/res/url.dart';

/// The update check and the crash-report link both read this fork's own
/// repository. An upstream merge that restores the original owner would
/// silently point them at a project this build is not.
void main() {
  test('the update check reads this fork releases', () {
    expect(
      Urls.githubReleasesApi,
      'https://api.github.com/repos/jimiha1/nodepulse/releases',
    );
  });

  test('a crash report is filed against this fork', () {
    expect(
      Urls.newIssue,
      'https://github.com/jimiha1/nodepulse/issues/new',
    );
  });
}
