import 'dart:convert';

import 'package:core_update/core_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

http.Client _clientReturning(String body, {int status = 200}) =>
    _FakeClient((_) async => http.Response(body, status));

class _FakeClient extends http.BaseClient {
  _FakeClient(this._handler);
  final Future<http.Response> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(r.body)),
      r.statusCode,
    );
  }
}

String _release({required String tag, List<String> assets = const []}) {
  return jsonEncode({
    'tag_name': tag,
    'body': 'What\'s new:\n- Faster startup',
    'html_url': 'https://github.com/o/r/releases/$tag',
    'assets': [
      for (final a in assets)
        {'name': a, 'browser_download_url': 'https://dl/$a'},
    ],
  });
}

void main() {
  group('version parsing/compare', () {
    test('parses v-prefixed and build-suffixed versions', () {
      expect(GithubUpdateService.parseVersion('v1.4.0'), [1, 4, 0]);
      expect(GithubUpdateService.parseVersion('1.4.0+3'), [1, 4, 0]);
      expect(GithubUpdateService.parseVersion('nope'), isNull);
    });

    test('isNewer compares component-wise', () {
      expect(GithubUpdateService.isNewer([1, 4, 0], [1, 3, 9]), isTrue);
      expect(GithubUpdateService.isNewer([1, 4, 0], [1, 4, 0]), isFalse);
      expect(GithubUpdateService.isNewer([1, 3, 0], [1, 4, 0]), isFalse);
      expect(GithubUpdateService.isNewer([2, 0], [1, 9, 9]), isTrue);
    });
  });

  group('APK picking', () {
    test('prefers arm64, then universal, then any apk', () {
      expect(
        GithubUpdateService.pickApkUrl([
          {'name': 'app-x86_64.apk', 'browser_download_url': 'x'},
          {'name': 'app-arm64-v8a.apk', 'browser_download_url': 'a'},
          {'name': 'app-universal.apk', 'browser_download_url': 'u'},
        ]),
        'a',
      );
      expect(
        GithubUpdateService.pickApkUrl([
          {'name': 'app-universal.apk', 'browser_download_url': 'u'},
          {'name': 'notes.txt', 'browser_download_url': 't'},
        ]),
        'u',
      );
      expect(GithubUpdateService.pickApkUrl([]), isNull);
    });
  });

  group('check()', () {
    GithubUpdateService svc(http.Client c, String current) =>
        GithubUpdateService(
          owner: 'o',
          repo: 'r',
          client: c,
          currentVersion: () async => current,
        );

    test('returns update when latest is newer + has an APK', () async {
      final c = _clientReturning(
        _release(tag: 'v1.4.0', assets: ['app-arm64-v8a.apk']),
      );
      final info = await svc(c, '1.3.0').check();
      expect(info, isNotNull);
      expect(info!.version, '1.4.0');
      expect(info.downloadUrl, 'https://dl/app-arm64-v8a.apk');
      expect(info.notes, contains('Faster startup'));
    });

    test('null when already up to date', () async {
      final c = _clientReturning(
        _release(tag: 'v1.3.0', assets: ['app-arm64-v8a.apk']),
      );
      expect(await svc(c, '1.3.0').check(), isNull);
    });

    test('null when newer but no APK asset', () async {
      final c = _clientReturning(_release(tag: 'v2.0.0'));
      expect(await svc(c, '1.0.0').check(), isNull);
    });

    test('null on non-200 (offline/error) without throwing', () async {
      final c = _clientReturning('{}', status: 500);
      expect(await svc(c, '1.0.0').check(), isNull);
    });
  });
}
