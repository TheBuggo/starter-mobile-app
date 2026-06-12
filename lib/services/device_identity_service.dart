import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/device_identity.dart';

class DeviceIdentityService {
  const DeviceIdentityService();

  static const _channel = MethodChannel('starter_app/device_identity');

  Future<DeviceIdentity?> load() async {
    final Map<String, String>? response;
    try {
      response = await _channel.invokeMapMethod<String, String>('load');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
    final platform = response?['platform'];
    final kind = response?['kind'];
    final identifier = response?['identifier'];

    if (platform == null ||
        platform.isEmpty ||
        kind == null ||
        kind.isEmpty ||
        identifier == null ||
        identifier.isEmpty) {
      return null;
    }

    return DeviceIdentity(
      identifierHash:
          sha256.convert(utf8.encode('$platform:$kind:$identifier')).toString(),
      kind: kind,
      platform: platform,
    );
  }
}
