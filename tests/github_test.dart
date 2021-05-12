import 'package:test/test.dart';
import 'package:flutter_eng_cycle_times/github.dart';

void main() {
  test('pull request id parse', () {
    expect(Commit.issueIdFromMessage(''), isNull);
    expect(
        Commit.issueIdFromMessage(
            'Roll Plugins from 2d850906a1d0 to 580a6e7a43a7 (2 revisions) (#81543)'),
        81543);
    expect(
        Commit.issueIdFromMessage(
            '[flutter_tools] remove mocks, globals from golden comparator and test runner tests | Reland'),
        isNull);
  });
}
