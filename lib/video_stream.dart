
import 'dart:async';

import 'package:flutter/services.dart';

class VideoStream {
  static const MethodChannel _channel = MethodChannel('video_stream');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
