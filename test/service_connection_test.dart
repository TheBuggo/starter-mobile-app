import 'package:flutter_test/flutter_test.dart';
import 'package:starter_app/models/service_connection.dart';

void main() {
  test('parses service connection status and scopes', () {
    final connection = ServiceConnection.fromMap({
      'connection_type': 'oauth',
      'external_account_label': 'Creator account',
      'id': 42,
      'metadata': {'requested_at': '2026-06-04T12:00:00Z'},
      'provider_key': 'spotify',
      'provider_name': 'Spotify',
      'scopes': ['profile', 'library'],
      'status': 'connected',
      'user_id': 'user-1',
    });

    expect(connection.connected, isTrue);
    expect(connection.providerName, 'Spotify');
    expect(connection.scopes, ['profile', 'library']);
    expect(connection.statusLabel, 'Connected');
  });
}
