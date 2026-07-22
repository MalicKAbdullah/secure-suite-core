import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A newer release available for the app.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.downloadUrl,
    required this.releaseUrl,
  });

  /// Clean version, e.g. `1.4.0` (no leading `v`).
  final String version;

  /// Release notes (GitHub release body); may be empty.
  final String notes;

  /// Direct APK asset URL — opening it downloads the update.
  final String downloadUrl;

  /// The release's web page, as a fallback.
  final String releaseUrl;
}

/// Checks a GitHub repo's latest release and opens its APK to update.
abstract interface class IUpdateService {
  /// Returns the update when the latest release is newer than the running
  /// build, else null (up to date, offline, or no APK asset).
  Future<UpdateInfo?> check();

  /// Opens the APK download in the browser so Android installs it.
  Future<bool> openDownload(UpdateInfo info);
}

/// GitHub-releases implementation. Unauthenticated (public repos).
final class GithubUpdateService implements IUpdateService {
  GithubUpdateService({
    required this.owner,
    required this.repo,
    http.Client? client,
    Future<String> Function()? currentVersion,
  })  : _client = client ?? http.Client(),
        _currentVersion = currentVersion ?? _platformVersion;

  final String owner;
  final String repo;
  final http.Client _client;
  final Future<String> Function() _currentVersion;

  static Future<String> _platformVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  @override
  Future<UpdateInfo?> check() async {
    final Uri uri =
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
    try {
      final resp = await _client.get(
        uri,
        headers: const {'Accept': 'application/vnd.github+json'},
      );
      if (resp.statusCode != 200) return null;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final latest = parseVersion(tag);
      final current = parseVersion(await _currentVersion());
      if (latest == null || current == null) return null;
      if (!isNewer(latest, current)) return null;

      final apk = pickApkUrl(json['assets'] as List<dynamic>? ?? const []);
      if (apk == null) return null;

      return UpdateInfo(
        version: tag.replaceFirst(RegExp('^v'), ''),
        notes: ((json['body'] as String?) ?? '').trim(),
        downloadUrl: apk,
        releaseUrl: (json['html_url'] as String?) ?? '',
      );
    } catch (_) {
      // Offline or unexpected shape — silently skip; never block the app.
      return null;
    }
  }

  @override
  Future<bool> openDownload(UpdateInfo info) {
    final url =
        info.downloadUrl.isNotEmpty ? info.downloadUrl : info.releaseUrl;
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  /// Parses `v1.4.0` / `1.4.0+3` into `[1, 4, 0]`; null when unparseable.
  static List<int>? parseVersion(String raw) {
    final core = raw.replaceFirst(RegExp('^v'), '').split('+').first.trim();
    if (core.isEmpty) return null;
    final parts = core.split('.');
    final nums = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null) return null;
      nums.add(n);
    }
    return nums.isEmpty ? null : nums;
  }

  /// True when [latest] is a higher version than [current], component-wise.
  static bool isNewer(List<int> latest, List<int> current) {
    final len = latest.length > current.length ? latest.length : current.length;
    for (var i = 0; i < len; i++) {
      final a = i < latest.length ? latest[i] : 0;
      final b = i < current.length ? current[i] : 0;
      if (a != b) return a > b;
    }
    return false;
  }

  /// Picks the best APK asset: arm64-v8a first, then universal, then any apk.
  static String? pickApkUrl(List<dynamic> assets) {
    String? universal;
    String? anyApk;
    for (final a in assets) {
      if (a is! Map<String, dynamic>) continue;
      final name = (a['name'] as String?)?.toLowerCase() ?? '';
      final url = a['browser_download_url'] as String?;
      if (url == null || !name.endsWith('.apk')) continue;
      if (name.contains('arm64-v8a')) return url;
      if (name.contains('universal')) universal ??= url;
      anyApk ??= url;
    }
    return universal ?? anyApk;
  }
}
