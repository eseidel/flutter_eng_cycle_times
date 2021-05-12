import 'package:flutter_eng_cycle_times/flutter_releases.dart';
import 'package:flutter_eng_cycle_times/github.dart';
import 'package:stats/stats.dart';
import 'package:flutter_eng_cycle_times/network.dart';
import 'package:github/github.dart' as gh;

// Calculate the time per-PR from creation until release.

// Get the associated commit for a given release
// Get the associated commit for the previous release.
// Get the list of commits between these two releases.
// For each commit, work backwards to the PR which caused it.
// If it's a roll commit (hand that later)
// For each PR:
// - Last touched
// - commit time

// Time from when an author last touches a PR to when it ships to customers.

// First find set of PRs being checked.
// For any given PR find
// Last touch from author
// Merge date in repo
// Date branch published with that change.hg

// Do we need to deal with reverts?

// void printTags(GitHub github) {
//   // Flutter doesn't seem to have official "github releases", just tags.
//   // Have to fetch all tags, get the date associated with the commit
//   // cache them all and sort by commit date order.
//   // https://stackoverflow.com/questions/19452244/github-api-v3-order-tags-by-creation-date
//   github.repositories
//       .listTags(RepositorySlug('flutter', 'flutter'))
//       .take(10)
//       .toList()
//       .then((tags) {
//     for (final tag in tags) {
//       print(tag);
//     }
//   });
// }

class ChangeTiming {
  int pullNumber;
  DateTime createTime;
  DateTime mergeTime;
  DateTime devReleaseTime;
  ChangeTiming(
      {required this.pullNumber,
      required this.createTime,
      required this.mergeTime,
      required this.devReleaseTime});
}

void main(List<String> arguments) async {
  var releases = await fetchReleases(ReleasePlatform.mac);
  var latest = releases.latest(ReleaseChannel.dev);
  var penultimate =
      releases.latest(ReleaseChannel.dev, offsetFromMostRecent: 1);

  print(latest.version);
  print(penultimate.version);

  // Could this use github.GitHubComparison instead?
  var compareUrl =
      compareTagsUrl(newerHash: latest.hash, olderHash: penultimate.hash);
  var response = await github.getJSON(compareUrl);
  var compareResult = CompareResult.fromJson(response);
  var prs = Set<int>.from(compareResult.commits
      .where((commit) => commit.issueId != null)
      .map((commit) => commit.issueId));

  print(prs);

  var commitsByPrId = <int?, List<Commit>>{};
  for (var commit in compareResult.commits) {
    var commits = commitsByPrId[commit.issueId] ?? [];
    commits.add(commit);
    commitsByPrId[commit.issueId] = commits;
  }

  print('found ${prs.length} prs from ${compareResult.commits.length} commits');
  var commitsWithoutPrs = commitsByPrId[null];
  if (commitsWithoutPrs != null) {
    print('commits missing prs:');
    for (var commit in commitsWithoutPrs) {
      print(commit.title);
    }
  }

  print('Caching ${prs.length} prs...');
  var timings = <ChangeTiming>[];
  for (var issueId in prs) {
    var url = '/repos/flutter/flutter/pulls/$issueId';
    var response = await github.getJSON(url);
    var pull = gh.PullRequest.fromJson(response);
    var timing = ChangeTiming(
        pullNumber: pull.number!,
        createTime: pull.createdAt!,
        mergeTime: pull.mergedAt!,
        devReleaseTime: latest.releaseDate);
    timings.add(timing);
  }

  void printStats(String label, Iterable<int> values) {
    var stats = Stats.fromData(values);
    print(label + ': ' + stats.withPrecision(3).toString());
  }

  printStats(
      'merge hrs',
      timings.map(
          (timing) => timing.mergeTime.difference(timing.createTime).inHours));
  printStats(
      'release hrs',
      timings.map((timing) =>
          timing.devReleaseTime.difference(timing.mergeTime).inHours));
  printStats(
      'total hrs',
      timings.map((timing) =>
          timing.devReleaseTime.difference(timing.createTime).inHours));

  // Entirely reverts or reverts of reverts?
  // for (var issueId in commitsByPrId.keys) {
  //   if (issueId == null) continue;
  //   var commits = commitsByPrId[issueId]!;
  //   if (commits.length == 1) continue;
  //   print('${commits.length} commits mapped to $issueId:');
  //   for (var commit in commits) {
  //     print(commit.title);
  //   }
  // }

  // https://docs.github.com/en/rest/reference/repos#commits
  // https://docs.github.com/en/rest/reference/repos#list-pull-requests-associated-with-a-commit
  // printTags(github);

  // https://api.github.com/repos/flutter/flutter/pulls/82238
  // "created_at": "2021-05-11T06:27:13Z",
  // "updated_at": "2021-05-11T17:19:10Z",
  // "closed_at": "2021-05-11T17:19:02Z",
  // "merged_at": "2021-05-11T17:19:02Z",
}
