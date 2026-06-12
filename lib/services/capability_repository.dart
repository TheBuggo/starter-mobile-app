import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_connection.dart';

class CapabilityRepository {
  const CapabilityRepository(this._client);

  final SupabaseClient _client;

  User? get _currentUser => _client.auth.currentUser;

  Future<Set<String>> loadPreparedCapabilities(String userId) async {
    final rows = await _client
        .from('capability_events')
        .select('capability_key')
        .eq('user_id', userId)
        .eq('event_type', 'prepared');

    return {
      for (final row in rows)
        if (row['capability_key'] is String) row['capability_key'] as String,
    };
  }

  Future<List<ServiceConnection>> loadServiceConnections(String userId) async {
    final rows = await _client
        .from('service_connections')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows.map((row) => ServiceConnection.fromMap(row)).toList();
  }

  Future<void> recordCapabilityEvent({
    required String capabilityKey,
    required String eventType,
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    await _client.from('capability_events').insert({
      'capability_key': capabilityKey,
      'event_type': eventType,
      'metadata': metadata,
      'user_id': user.id,
    });
  }

  Future<ServiceConnection?> requestServiceConnection({
    required String connectionType,
    required String providerKey,
    required String providerName,
    List<String> scopes = const [],
  }) async {
    final user = _currentUser;
    if (user == null) {
      return null;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final row = await _client
        .from('service_connections')
        .upsert(
          {
            'connection_type': connectionType,
            'metadata': {'requested_at': now},
            'provider_key': providerKey,
            'provider_name': providerName,
            'scopes': scopes,
            'status': ServiceConnectionStatus.requested.value,
            'updated_at': now,
            'user_id': user.id,
          },
          onConflict: 'user_id,provider_key',
        )
        .select()
        .single();

    return ServiceConnection.fromMap(row);
  }
}
