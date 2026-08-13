import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String version;
  final String minSupportedVersion;
  final String apkUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.version,
    required this.minSupportedVersion,
    required this.apkUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] as String? ?? '1.0.0',
      minSupportedVersion: json['minSupportedVersion'] as String? ?? '1.0.0',
      apkUrl: json['apkUrl'] as String? ?? '/apk/portal-social.apk',
      releaseNotes: json['releaseNotes'] as String? ?? '',
    );
  }
}

class UpdateService extends ChangeNotifier {
  static final UpdateService _instance = UpdateService._();
  factory UpdateService() => _instance;
  UpdateService._();

  static const _kLastVersionKey = 'portal_last_known_version';
  static const _kDismissedVersionKey = 'portal_dismissed_version';

  UpdateInfo? _latest;
  bool _isChecking = false;
  String? _error;
  final Set<String> _dismissedVersions = {};

  UpdateInfo? get latest => _latest;
  bool get isChecking => _isChecking;
  String? get error => _error;

  bool isDismissed(String version) => _dismissedVersions.contains(version);

  String get _baseUrl {
    final raw = dotenv.env['API_BASE_URL'] ?? 'https://portal-mz.vercel.app/';
    return raw.replaceAll(RegExp(r'/+$'), '') + '/';
  }

  Future<void> checkForUpdate() async {
    if (_isChecking) return;
    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${_baseUrl}api/app/version');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _latest = UpdateInfo.fromJson(data);
        if (await wasDismissed(_latest!.version)) {
          _dismissedVersions.add(_latest!.version);
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString();
      _latest = null;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool isUpdateRequired(String currentVersion) {
    if (_latest == null) return false;
    return _isVersionLessThan(currentVersion, _latest!.minSupportedVersion);
  }

  bool isUpdateAvailable(String currentVersion) {
    if (_latest == null) return false;
    return _isVersionLessThan(currentVersion, _latest!.version);
  }

  Future<void> downloadAndInstall() async {
    if (_latest == null) return;
    final url = _latest!.apkUrl.startsWith('http')
        ? _latest!.apkUrl
        : '${_baseUrl}${_latest!.apkUrl.replaceFirst(RegExp(r'^/'), '')}';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> markDismissed(String version) async {
    _dismissedVersions.add(version);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedVersionKey, version);
    notifyListeners();
  }

  Future<bool> wasDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDismissedVersionKey) == version;
  }

  String? getInstalledVersion() {
    return null;
  }

  bool _isVersionLessThan(String a, String b) {
    final partsA = a.split('.').map(int.parse).toList();
    final partsB = b.split('.').map(int.parse).toList();
    for (var i = 0; i < partsA.length && i < partsB.length; i++) {
      if (partsA[i] < partsB[i]) return true;
      if (partsA[i] > partsB[i]) return false;
    }
    return partsA.length < partsB.length;
  }
}
