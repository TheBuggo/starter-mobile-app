import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starter_app/app/app_config.dart';

void main() {
  test('keeps loopback URL on Apple platforms', () {
    expect(
      AppConfig.normalizeSupabaseUrlForPlatform(
        'http://127.0.0.1:54321',
        TargetPlatform.iOS,
      ),
      'http://127.0.0.1:54321',
    );

    expect(
      AppConfig.normalizeSupabaseUrlForPlatform(
        'http://localhost:54321',
        TargetPlatform.macOS,
      ),
      'http://localhost:54321',
    );
  });

  test('rewrites loopback URL for Android emulators', () {
    expect(
      AppConfig.normalizeSupabaseUrlForPlatform(
        'http://127.0.0.1:54321',
        TargetPlatform.android,
      ),
      'http://10.0.2.2:54321',
    );

    expect(
      AppConfig.normalizeSupabaseUrlForPlatform(
        'http://localhost:54321',
        TargetPlatform.android,
      ),
      'http://10.0.2.2:54321',
    );
  });

  test('keeps non-loopback URL on Android', () {
    expect(
      AppConfig.normalizeSupabaseUrlForPlatform(
        'https://project-ref.supabase.co',
        TargetPlatform.android,
      ),
      'https://project-ref.supabase.co',
    );
  });
}
