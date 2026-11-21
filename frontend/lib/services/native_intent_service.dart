import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Memanggil Intent native Android (lewat MethodChannel).
class NativeIntentService {
  static const MethodChannel _channel = MethodChannel('jadwal/intent');

  static Future<bool> openNotificationSettings() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
