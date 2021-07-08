import 'package:flutter/services.dart';

typedef CameraCallback = void Function(dynamic result);

// Non exported class
class CameraChannel {
  static final Map<int, dynamic> callbacks = <int, CameraCallback>{};

  static final MethodChannel channel = const MethodChannel(
    'video_stream',
  )..setMethodCallHandler(
      (MethodCall call) async {
        assert(call.method == 'handleCallback');

        final int handle = call.arguments['handle'];
        if (callbacks[handle] != null) callbacks[handle](call.arguments);
      },
    );

  static int nextHandle = 0;

  static void registerCallback(int handle, CameraCallback callback) {

    assert(!callbacks.containsKey(handle));
    callbacks[handle] = callback;
  }

  static void unregisterCallback(int handle) {
    callbacks.remove(handle);
  }
}
