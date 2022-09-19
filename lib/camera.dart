import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

part 'camera_image.dart';

const MethodChannel _channel = MethodChannel('video_stream');

enum CameraLensDirection { front, back, external }

enum ResolutionPreset {
  /// 352x288 on iOS, 240p (320x240) on Android
  low,

  /// 480p (640x480 on iOS, 720x480 on Android)
  medium,

  /// 720p (1280x720)
  high,

  /// 1080p (1920x1080)
  veryHigh,

  /// 2160p (3840x2160)
  ultraHigh,

  /// The highest resolution available.
  max,
}

// ignore: camel_case_types
typedef onLatestImageAvailable = Function(CameraImage image);

String serializeResolutionPreset(ResolutionPreset resolutionPreset) {
  switch (resolutionPreset) {
    case ResolutionPreset.max:
      return 'max';
    case ResolutionPreset.ultraHigh:
      return 'ultraHigh';
    case ResolutionPreset.veryHigh:
      return 'veryHigh';
    case ResolutionPreset.high:
      return 'high';
    case ResolutionPreset.medium:
      return 'medium';
    case ResolutionPreset.low:
      return 'low';
  }
  // ignore: dead_code
  throw ArgumentError('Unknown ResolutionPreset value');
}

CameraLensDirection _parseCameraLensDirection(String string) {
  switch (string) {
    case 'front':
      return CameraLensDirection.front;
    case 'back':
      return CameraLensDirection.back;
    case 'external':
      return CameraLensDirection.external;
  }
  throw ArgumentError('Unknown CameraLensDirection value');
}

Future<List<CameraDescription>> availableCameras() async {
  try {
    final List<Map>? cameras = await _channel.invokeListMethod<Map<dynamic, dynamic>>('availableCameras');
    return cameras!.map((Map<dynamic, dynamic> camera) {
      return CameraDescription(
        name: camera['name'],
        lensDirection: _parseCameraLensDirection(camera['lensFacing']),
        sensorOrientation: camera['sensorOrientation'],
      );
    }).toList();
  } on PlatformException catch (e) {
    throw CameraException(e.code, e.message!);
  }
}

class CameraDescription {
  final String name;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  CameraDescription({required this.name, required this.lensDirection, required this.sensorOrientation});

  @override
  bool operator ==(Object o) {
    return o is CameraDescription && o.name == name && o.lensDirection == lensDirection;
  }

  @override
  int get hashCode {
    return hashValues(name, lensDirection);
  }

  @override
  String toString() {
    return '$runtimeType($name, $lensDirection, $sensorOrientation)';
  }
}

class StreamStatistics {
  final int cacheSize;
  final int sentAudioFrames;
  final int sentVideoFrames;
  final int droppedAudioFrames;
  final int droppedVideoFrames;
  final bool isAudioMuted;
  final int bitrate;
  final int width;
  final int height;

  StreamStatistics({
    required this.cacheSize,
    required this.sentAudioFrames,
    required this.sentVideoFrames,
    required this.droppedAudioFrames,
    required this.droppedVideoFrames,
    required this.bitrate,
    required this.width,
    required this.height,
    required this.isAudioMuted,
  });

  @override
  String toString() {
    return 'StreamStatistics{cacheSize: $cacheSize, sentAudioFrames: $sentAudioFrames, sentVideoFrames: $sentVideoFrames, droppedAudioFrames: $droppedAudioFrames, droppedVideoFrames: $droppedVideoFrames, isAudioMuted: $isAudioMuted, bitrate: $bitrate, width: $width, height: $height}';
  }
}

class CameraException implements Exception {
  CameraException(this.code, this.description);

  String code;
  String description;

  @override
  String toString() => '$runtimeType($code, $description)';
}

// Build the UI texture view of the video data with textureId.
class CameraPreview extends StatelessWidget {
  const CameraPreview(this.controller);

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return controller.value.isInitialized
        ? controller.value.previewSize!.width < controller.value.previewSize!.height
            ? RotatedBox(
                quarterTurns: controller.value.previewQuarterTurns!,
                child: Texture(
                  textureId: controller._textureId!,
                ),
              )
            : Texture(textureId: controller._textureId!)
        : Container();
  }
}

class CameraValue {
  final bool isInitialized;
  final bool? isTakingPicture;
  final bool isRecordingVideo;
  final bool isStreamingVideoRtmp;
  final bool? isStreamingImages;
  final bool _isRecordingPaused;
  final bool _isStreamingPaused;
  final String? errorDescription;
  final Size? previewSize;
  final int? previewQuarterTurns;

  CameraValue({
    required this.isInitialized,
    this.errorDescription,
    this.previewSize,
    this.previewQuarterTurns,
    required this.isRecordingVideo,
    required this.isTakingPicture,
    required this.isStreamingImages,
    required this.isStreamingVideoRtmp,
    required bool isRecordingPaused,
    required bool isStreamingPaused,
  })  : _isRecordingPaused = isRecordingPaused,
        _isStreamingPaused = isStreamingPaused;

  CameraValue.uninitialized()
      : this(
          isInitialized: false,
          isRecordingVideo: false,
          isTakingPicture: false,
          isStreamingImages: false,
          isStreamingVideoRtmp: false,
          isRecordingPaused: false,
          isStreamingPaused: false,
          previewQuarterTurns: 0,
        );

  bool get isRecordingPaused => isRecordingVideo && _isRecordingPaused;

  bool get isStreamingPaused => isStreamingVideoRtmp && _isStreamingPaused;

  double get aspectRatio => previewSize!.height / previewSize!.width;

  bool get hasError => errorDescription != '';

  CameraValue copyWith({
    bool? isInitialized,
    bool? isRecordingVideo,
    bool? isStreamingVideoRtmp,
    bool? isTakingPicture,
    bool? isStreamingImages,
    String? errorDescription,
    Size? previewSize,
    int? previewQuarterTurns,
    bool? isRecordingPaused,
    bool? isStreamingPaused,
  }) {
    return CameraValue(
      isInitialized: isInitialized ?? this.isInitialized,
      errorDescription: errorDescription ?? '',
      previewSize: previewSize ?? this.previewSize,
      previewQuarterTurns: previewQuarterTurns ?? this.previewQuarterTurns,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      isStreamingVideoRtmp: isStreamingVideoRtmp ?? this.isStreamingVideoRtmp,
      isTakingPicture: isTakingPicture ?? this.isTakingPicture,
      isStreamingImages: isStreamingImages ?? this.isStreamingImages,
      isRecordingPaused: isRecordingPaused ?? _isRecordingPaused,
      isStreamingPaused: isStreamingPaused ?? _isStreamingPaused,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isRecordingVideo: $isRecordingVideo, '
        'isRecordingVideo: $isRecordingVideo, '
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription, '
        'previewSize: $previewSize, '
        'previewQuarterTurns: $previewQuarterTurns, '
        'isStreamingImages: $isStreamingImages, '
        'isStreamingVideoRtmp: $isStreamingVideoRtmp)';
  }
}

class CameraController extends ValueNotifier<CameraValue> {
  final CameraDescription? description;
  final ResolutionPreset? resolutionPreset;
  final ResolutionPreset? streamingPreset;
  final bool? enableAudio;
  int? _textureId;
  bool? _isDisposed = false;
  StreamSubscription<dynamic>? _eventSubscription;
  StreamSubscription<dynamic>? _imageStreamSubscription;
  Completer<void>? _creatingCompleter;
  final bool? androidUseOpenGL;

  CameraController(
    this.description,
    this.resolutionPreset, {
    this.enableAudio = true,
    this.streamingPreset,
    this.androidUseOpenGL = false,
  }) : super(CameraValue.uninitialized());

  Future<void> initialize() async {
    if (_isDisposed!) {
      return Future<void>.value();
    }
    try {
      _creatingCompleter = Completer<void>();
      final Map<String, dynamic>? reply = await _channel.invokeMapMethod<String, dynamic>(
        'initialize',
        <String, dynamic>{'cameraName': description!.name, 'resolutionPreset': serializeResolutionPreset(resolutionPreset!), 'streamingPreset': serializeResolutionPreset(streamingPreset ?? resolutionPreset!), 'enableAudio': enableAudio, 'enableAndroidOpenGL': androidUseOpenGL ?? false},
      );
      _textureId = reply!['textureId'];
      value = value.copyWith(
        isInitialized: true,
        previewSize: Size(
          reply['previewWidth'].toDouble(),
          reply['previewHeight'].toDouble(),
        ),
        previewQuarterTurns: reply['previewQuarterTurns'],
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
    _eventSubscription = EventChannel('video_stream/cameraEvents$_textureId').receiveBroadcastStream().listen(_listener);
    _creatingCompleter!.complete();
    return _creatingCompleter!.future;
  }

  Future<void> prepareForVideoRecording() async {
    await _channel.invokeMethod<void>('prepareForVideoRecording');
  }

  Future<void> prepareForVideoStreaming() async {
    await _channel.invokeMethod<void>('prepareForVideoStreaming');
  }

  void _listener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    if (_isDisposed!) {
      return;
    }

    print("Event $map");
    switch (map['eventType']) {
      case 'error':
        value = value.copyWith(errorDescription: event['errorDescription']);
        break;
      case 'camera_closing':
        value = value.copyWith(isRecordingVideo: false, isStreamingVideoRtmp: false);
        break;
      case 'rtmp_connected':
        break;
      case 'rtmp_retry':
        break;
      case 'rtmp_stopped':
        value = value.copyWith(isStreamingVideoRtmp: false);
        break;
      case 'rotation_update':
        value = value.copyWith(previewQuarterTurns: int.parse(event['errorDescription']));
        break;
    }
  }

  // TODO: Add settings for resolution and fps.
  Future<void> startImageStream(onLatestImageAvailable onAvailable) async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'startImageStream was called on uninitialized CameraController.',
      );
    }
    if (value.isRecordingVideo) {
      throw CameraException(
        'A video recording is already started.',
        'startImageStream was called while a video is being recorded.',
      );
    }
    if (value.isStreamingVideoRtmp) {
      throw CameraException(
        'A video recording is already started.',
        'startImageStream was called while a video is being recorded.',
      );
    }
    if (value.isStreamingImages!) {
      throw CameraException(
        'A camera has started streaming images.',
        'startImageStream was called while a camera was streaming images.',
      );
    }

    try {
      await _channel.invokeMethod<void>('startImageStream');
      value = value.copyWith(isStreamingImages: true);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
    const EventChannel cameraEventChannel = EventChannel('video_stream/imageStream');
    _imageStreamSubscription = cameraEventChannel.receiveBroadcastStream().listen(
      (dynamic imageData) {
        onAvailable(CameraImage._fromPlatformData(imageData));
      },
    );
  }

  /// Stop streaming images from platform camera.
  ///
  /// Throws a [CameraException] if image streaming was not started or video
  /// recording was started.
  Future<void> stopImageStream() async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'stopImageStream was called on uninitialized CameraController.',
      );
    }
    if (!value.isStreamingImages!) {
      throw CameraException(
        'No camera is streaming images',
        'stopImageStream was called when no camera is streaming images.',
      );
    }

    try {
      value = value.copyWith(isStreamingImages: false);
      await _channel.invokeMethod<void>('stopImageStream');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }

    await _imageStreamSubscription!.cancel();
    _imageStreamSubscription = null;
  }

  /// Get statistics about the rtmp stream.
  ///
  /// Throws a [CameraException] if image streaming was not started.
  Future<StreamStatistics> getStreamStatistics() async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'stopImageStream was called on uninitialized CameraController.',
      );
    }
    if (!value.isStreamingVideoRtmp) {
      throw CameraException(
        'No camera is streaming images',
        'stopImageStream was called when no camera is streaming images.',
      );
    }

    try {
      var data = await _channel.invokeMapMethod<String, dynamic>('getStreamStatistics');
      return StreamStatistics(
        sentAudioFrames: data!["sentAudioFrames"],
        sentVideoFrames: data["sentVideoFrames"],
        height: data["height"],
        width: data["width"],
        bitrate: data["bitrate"],
        isAudioMuted: data["isAudioMuted"],
        cacheSize: data["cacheSize"],
        droppedAudioFrames: data["drpppedAudioFrames"],
        droppedVideoFrames: data["droppedVideoFrames"],
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
  }

  /// Start a video streaming to the url in [url`].
  ///
  /// This uses rtmp to do the sending the remote side.
  ///
  /// Throws a [CameraException] if the capture fails.
  Future<void> startVideoStreaming(String url, {int bitrate = 1200 * 1024, required bool androidUseOpenGL}) async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'startVideoStreaming was called on uninitialized CameraController',
      );
    }
    if (value.isRecordingVideo) {
      throw CameraException(
        'A video recording is already started.',
        'startVideoStreaming was called when a recording is already started.',
      );
    }
    if (value.isStreamingVideoRtmp) {
      throw CameraException(
        'A video streaming is already started.',
        'startVideoStreaming was called when a recording is already started.',
      );
    }
    if (value.isStreamingImages!) {
      throw CameraException(
        'A camera has started streaming images.',
        'startVideoStreaming was called while a camera was streaming images.',
      );
    }

    try {
      await _channel.invokeMethod<void>('startVideoStreaming', <String, dynamic>{
        'textureId': _textureId,
        'url': url,
        'bitrate': bitrate,
      });
      value = value.copyWith(isStreamingVideoRtmp: true, isStreamingPaused: false);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
  }

  /// Stop streaming.
  Future<void> stopVideoStreaming() async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'stopVideoStreaming was called on uninitialized CameraController',
      );
    }
    if (!value.isStreamingVideoRtmp) {
      throw CameraException(
        'No video is recording',
        'stopVideoStreaming was called when no video is streaming.',
      );
    }
    try {
      value = value.copyWith(isStreamingVideoRtmp: false, isRecordingVideo: false);
      print("Stop video streaming call");
      await _channel.invokeMethod<void>(
        'stopRecordingOrStreaming',
        <String, dynamic>{'textureId': _textureId},
      );
    } on PlatformException catch (e) {
      print("GOt exception $e");
      throw CameraException(e.code, e.message!);
    }
  }

  /// Stop streaming.
  Future<void> stopEverything() async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'stopVideoStreaming was called on uninitialized CameraController',
      );
    }
    try {
      value = value.copyWith(isStreamingVideoRtmp: false);
      if (value.isRecordingVideo || value.isStreamingVideoRtmp) {
        value = value.copyWith(isRecordingVideo: false, isStreamingVideoRtmp: false);
        await _channel.invokeMethod<void>(
          'stopRecordingOrStreaming',
          <String, dynamic>{'textureId': _textureId},
        );
      }
      if (value.isStreamingImages!) {
        value = value.copyWith(isStreamingImages: false);
        await _channel.invokeMethod<void>('stopImageStream');
      }
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
  }

  /// Pause video recording.
  ///
  /// This feature is only available on iOS and Android sdk 24+.
  Future<void> pauseVideoStreaming() async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'pauseVideoStreaming was called on uninitialized CameraController',
      );
    }
    if (!value.isStreamingVideoRtmp) {
      throw CameraException(
        'No video is recording',
        'pauseVideoStreaming was called when no video is streaming.',
      );
    }
    try {
      value = value.copyWith(isStreamingPaused: true);
      await _channel.invokeMethod<void>(
        'pauseVideoStreaming',
        <String, dynamic>{'textureId': _textureId},
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
  }

  /// Resume video streaming after pausing.
  ///
  /// This feature is only available on iOS and Android sdk 24+.
  Future<void> resumeVideoStreaming() async {
    if (!value.isInitialized || _isDisposed!) {
      throw CameraException(
        'Uninitialized CameraController',
        'resumeVideoStreaming was called on uninitialized CameraController',
      );
    }
    if (!value.isStreamingVideoRtmp) {
      throw CameraException(
        'No video is recording',
        'resumeVideoStreaming was called when no video is streaming.',
      );
    }
    try {
      value = value.copyWith(isStreamingPaused: false);
      await _channel.invokeMethod<void>(
        'resumeVideoStreaming',
        <String, dynamic>{'textureId': _textureId},
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message!);
    }
  }

  /// Releases the resources of this camera.
  @override
  Future<void> dispose() async {
    if (_isDisposed!) {
      return;
    }
    _isDisposed = true;
    super.dispose();
    if (_creatingCompleter != null) {
      await _creatingCompleter!.future;
      await _channel.invokeMethod<void>(
        'dispose',
        <String, dynamic>{'textureId': _textureId},
      );
      await _eventSubscription!.cancel();
    }
  }
}
