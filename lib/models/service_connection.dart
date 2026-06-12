enum ServiceConnectionStatus {
  needsSetup('needs_setup'),
  requested('requested'),
  connected('connected'),
  disconnected('disconnected');

  const ServiceConnectionStatus(this.value);

  final String value;

  static ServiceConnectionStatus fromValue(String? value) {
    return ServiceConnectionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ServiceConnectionStatus.needsSetup,
    );
  }
}

class ServiceConnection {
  const ServiceConnection({
    required this.connectionType,
    required this.id,
    required this.metadata,
    required this.providerKey,
    required this.providerName,
    required this.scopes,
    required this.status,
    required this.userId,
    this.connectedAt,
    this.externalAccountLabel,
  });

  final DateTime? connectedAt;
  final String connectionType;
  final String? externalAccountLabel;
  final int id;
  final Map<String, dynamic> metadata;
  final String providerKey;
  final String providerName;
  final List<String> scopes;
  final ServiceConnectionStatus status;
  final String userId;

  bool get connected => status == ServiceConnectionStatus.connected;

  String get statusLabel {
    return switch (status) {
      ServiceConnectionStatus.needsSetup => 'Setup needed',
      ServiceConnectionStatus.requested => 'Requested',
      ServiceConnectionStatus.connected => 'Connected',
      ServiceConnectionStatus.disconnected => 'Disconnected',
    };
  }

  factory ServiceConnection.fromMap(Map<String, dynamic> map) {
    return ServiceConnection(
      connectedAt: _dateTimeFrom(map['connected_at']),
      connectionType: (map['connection_type'] as String?) ?? 'oauth',
      externalAccountLabel: map['external_account_label'] as String?,
      id: (map['id'] as int?) ?? 0,
      metadata: _jsonMapFrom(map['metadata']),
      providerKey: (map['provider_key'] as String?) ?? '',
      providerName: (map['provider_name'] as String?) ?? '',
      scopes: _stringListFrom(map['scopes']),
      status: ServiceConnectionStatus.fromValue(map['status'] as String?),
      userId: (map['user_id'] as String?) ?? '',
    );
  }
}

DateTime? _dateTimeFrom(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

Map<String, dynamic> _jsonMapFrom(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<String> _stringListFrom(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
