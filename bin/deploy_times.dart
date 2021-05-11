import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

enum ReleasePlatform {
  mac,
  win,
  linux,
}

String _nameForPlatform(ReleasePlatform platform) {
  switch (platform) {
    case ReleasePlatform.mac:
      return 'macos';
    case ReleasePlatform.win:
      return 'windows';
    case ReleasePlatform.linux:
      return 'linux';
  }
}

enum ReleaseChannel {
  stable,
  dev,
  beta,
}

String nameForChannel(ReleaseChannel channel) {
  switch (channel) {
    case ReleaseChannel.stable:
      return 'stable';
    case ReleaseChannel.dev:
      return 'dev';
    case ReleaseChannel.beta:
      return 'beta';
  }
}

ReleaseChannel channelByName(String name) {
  var channel = {
    'stable': ReleaseChannel.stable,
    'beta': ReleaseChannel.beta,
    'dev': ReleaseChannel.dev,
  }[name];
  if (channel == null) {
    throw ArgumentError('No channel for $name');
  }
  return channel;
}

String releaseBaseUrl =
    'https://storage.googleapis.com/flutter_infra_release/releases';

String releaseJsonUrlForPlatform(ReleasePlatform platform) {
  return '$releaseBaseUrl/releases_${_nameForPlatform(platform)}.json';
}

class ReleaseInfo {
  final String hash;
  final ReleaseChannel channel;
  // String version;
  // DateTime releaseDate;
  // String archivePath;
  // String sha256;
  ReleaseInfo.fromJson(dynamic release)
      : hash = release['hash'],
        channel = channelByName(release['channel']);
}

class RecentReleases {
  final List<ReleaseInfo> releases;
  RecentReleases.fromJson(dynamic recentReleases)
      : releases = (recentReleases['releases'] as List)
            .map<ReleaseInfo>((release) => ReleaseInfo.fromJson(release))
            .toList();

  Iterable<ReleaseInfo> releasesByChannel(ReleaseChannel channel) {
    return releases.where((release) => release.channel == channel);
  }

  ReleaseInfo latest(ReleaseChannel channel, {int offsetFromMostRecent = 0}) {
    // This is ignoring the 'current_release' key and depending on order
    return releases[offsetFromMostRecent];
  }
}

Future<RecentReleases> fetchReleases(ReleasePlatform platform) async {
  var releasesUrl = releaseJsonUrlForPlatform(ReleasePlatform.mac);
  var response = await http.get(Uri.parse(releasesUrl));
  return RecentReleases.fromJson(json.decode(response.body));
}

void main(List<String> arguments) async {
  // var github = GitHub(auth: findAuthenticationFromEnvironment());

  var releases = await fetchReleases(ReleasePlatform.mac);
  var latest = releases.latest(ReleaseChannel.dev);
  var penultimate =
      releases.latest(ReleaseChannel.dev, offsetFromMostRecent: 1);

  print(latest.hash);
  print(penultimate.hash);

  // https://docs.github.com/en/rest/reference/repos#commits
  // https://docs.github.com/en/rest/reference/repos#list-pull-requests-associated-with-a-commit
  // printTags(github);

  // https://api.github.com/repos/flutter/flutter/pulls/82238
  // "created_at": "2021-05-11T06:27:13Z",
  // "updated_at": "2021-05-11T17:19:10Z",
  // "closed_at": "2021-05-11T17:19:02Z",
  // "merged_at": "2021-05-11T17:19:02Z",
}
