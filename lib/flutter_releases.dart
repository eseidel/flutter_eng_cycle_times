import 'network.dart';

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
  String version;
  // DateTime releaseDate;
  // String archivePath;
  // String sha256;
  ReleaseInfo.fromJson(dynamic release)
      : hash = release['hash'],
        channel = channelByName(release['channel']),
        version = release['version'];
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
  var response = await dio.get(releasesUrl);
  return RecentReleases.fromJson(response.data);
}
