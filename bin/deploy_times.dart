import 'package:github/github.dart';
import 'dart:convert';
import 'package:flutter_eng_cycle_times/flutter_releases.dart';
import 'package:flutter_eng_cycle_times/github.dart';
import 'package:flutter_eng_cycle_times/network.dart';

// Calculate the time per-PR from creation until release.

// releases
// https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json
// https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json
// https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json

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
// Date branch published with that change.

// Do we need to deal with reverts?

void printTags(GitHub github) {
  // Flutter doesn't seem to have official "github releases", just tags.
  // Have to fetch all tags, get the date associated with the commit
  // cache them all and sort by commit date order.
  // https://stackoverflow.com/questions/19452244/github-api-v3-order-tags-by-creation-date
  github.repositories
      .listTags(RepositorySlug('flutter', 'flutter'))
      .take(10)
      .toList()
      .then((tags) {
    for (final tag in tags) {
      print(tag);
    }
  });
}

void main(List<String> arguments) async {
  // var github = GitHub(auth: findAuthenticationFromEnvironment());

  var releases = await fetchReleases(ReleasePlatform.mac);
  var latest = releases.latest(ReleaseChannel.dev);
  var penultimate =
      releases.latest(ReleaseChannel.dev, offsetFromMostRecent: 1);

  print(latest.version);
  print(penultimate.version);

  var compareUri =
      compareTagsUrl(newerHash: latest.hash, olderHash: penultimate.hash);
  var response = await dio.getUri(compareUri);
  var compareResult = CompareResult.fromJson(response.data);
  var prs = Set<int>.from(compareResult.commits
      .where((commit) => commit.issueId != null)
      .map((commit) => commit.issueId));

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
