String compareTagsUrl({required String newerHash, required String olderHash}) {
  return '/repos/flutter/flutter/compare/$olderHash...$newerHash';
}

class Commit {
  String sha;
  String message;
  int? issueId;

  String get title => message.split('\n').first;

  // This is a hack
  static final RegExp prIdRegexp = RegExp(r'\(#(?<id>\d+)\)');

  static int? issueIdFromMessage(String message) {
    var matchResult = Commit.prIdRegexp.firstMatch(message);
    var firstMatch = matchResult?.namedGroup('id');
    return firstMatch != null ? int.tryParse(firstMatch) : null;
  }

  Commit.fromJson(dynamic commit)
      : message = commit['commit']['message'],
        sha = commit['sha'],
        issueId = issueIdFromMessage(commit['commit']['message']);
}

// https://api.github.com/repos/flutter/flutter/compare/2.2.0-10.3.pre...2.3.0-1.0.pre
class CompareResult {
  List<Commit> commits;
  CompareResult.fromJson(dynamic compareResult)
      : commits = (compareResult['commits'] as List)
            .map<Commit>((commit) => Commit.fromJson(commit))
            .toList();
}
