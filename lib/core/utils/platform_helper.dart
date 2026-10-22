import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class PlatformHelper {
  /// Checks if the client is iOS, whether running natively or inside Safari Web
  static bool get isIOS {
    if (kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.iOS;
    }
    return Platform.isIOS;
  }
}