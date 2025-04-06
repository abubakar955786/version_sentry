class VersionSentryInfo {
  final String platform;
  final String currentVersion;
  final String storeVersion;
  final bool needsUpdate;
  final bool isMajorUpdate;
  final bool isMinorUpdate;
  final bool isPatchUpdate;
  final String? releaseNotes;
  final String packageName;
  final String appUpdateLink;

  VersionSentryInfo({
    required this.platform,
    required this.currentVersion,
    required this.storeVersion,
    required this.needsUpdate,
    required this.isMajorUpdate,
    required this.isMinorUpdate,
    required this.isPatchUpdate,
    this.releaseNotes,
    required this.packageName,
    required this.appUpdateLink,
  });

  factory VersionSentryInfo.fromJson(Map<String, dynamic> json) {
    return VersionSentryInfo(
      platform: json['platform'] as String,
      currentVersion: json['currentVersion'] as String,
      storeVersion: json['storeVersion'] as String,
      needsUpdate: json['needsUpdate'] as bool,
      isMajorUpdate: json['isMajorUpdate'] as bool,
      isMinorUpdate: json['isMinorUpdate'] as bool,
      isPatchUpdate: json['isPatchUpdate'] as bool,
      releaseNotes: json['releaseNotes'] as String?,
      packageName: json['packageName'] as String,
      appUpdateLink: json['appStoreLink'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'platform': platform,
      'currentVersion': currentVersion,
      'storeVersion': storeVersion,
      'needsUpdate': needsUpdate,
      'isMajorUpdate': isMajorUpdate,
      'isMinorUpdate': isMinorUpdate,
      'isPatchUpdate': isPatchUpdate,
      'releaseNotes': releaseNotes,
      'packageName': packageName,
      'appStoreLink': appUpdateLink,
    };
  }

  @override
  String toString() {
    return 'VersionSentryInfo(\n'
        '  Platform: $platform\n'
        '  Current Version: $currentVersion\n'
        '  Store Version: $storeVersion\n'
        '  Needs Update: $needsUpdate\n'
        '  Update Type: $_updateType\n'
        '  Package: $packageName\n'
        '  Store Link: $appUpdateLink\n'
        ')';
  }

  String get _updateType {
    if (isMajorUpdate) return 'Major';
    if (isMinorUpdate) return 'Minor';
    if (isPatchUpdate) return 'Patch';
    return 'None';
  }
}
