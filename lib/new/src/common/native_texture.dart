import 'dart:async';
import 'camera_channel.dart';
import 'camera_mixins.dart';

class NativeTexture with CameraMappable {
  NativeTexture._({required int handle, required this.textureId})
      : _handle = handle;

  final int _handle;
  bool _isClosed = false;
  final int textureId;

  static Future<NativeTexture> allocate() async {
    final int handle = CameraChannel.nextHandle++;

    final int? textureId = await CameraChannel.channel.invokeMethod<int>(
      '$NativeTexture#allocate',
      <String, dynamic>{'textureHandle': handle},
    );

    return NativeTexture._(handle: handle, textureId: textureId!);
  }

  Future<void> release() {
    if (_isClosed) return Future<void>.value();

    _isClosed = true;
    return CameraChannel.channel.invokeMethod<void>(
      '$NativeTexture#release',
      <String, dynamic>{'handle': _handle},
    );
  }

  @override
  Map<String, dynamic> asMap() {
    return <String, dynamic>{'handle': _handle};
  }
}
