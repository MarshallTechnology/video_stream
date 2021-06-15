// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedantic/pedantic.dart';
import 'package:video_stream/platform_interface/camera_platform.dart';
import 'package:video_stream/types/types.dart';

import 'camera_image.dart';
import 'events/camera_event.dart';

const MethodChannel _channel = MethodChannel('video_stream/camera');

/// Signature for a callback receiving the a camera image.
///
/// This is used by [CameraController.startImageStream].
// ignore: inference_failure_on_function_return_type
// ignore: camel_case_types
typedef onLatestImageAvailable = Function(CameraImage image);

/// Completes with a list of available cameras.
///
/// May throw a [CameraException].
Future<List<CameraDescription>> availableCameras() async {
  return CameraPlatform.instance.availableCameras();
}

/// The state of a [CameraController].
class CameraValue {
  /// Creates a new camera controller state.
  const CameraValue({
    required this.isInitialized,
    this.errorDescription,
    this.previewSize,
    required this.isStreaming,
    required this.focusMode,
    required this.deviceOrientation,
  });

  /// Creates a new camera controller state for an uninitialized controller.
  const CameraValue.uninitialized()
      : this(
          isInitialized: false,
          isStreaming: false,
          focusMode: FocusMode.auto,
          deviceOrientation: DeviceOrientation.portraitUp,
        );

  /// True after [CameraController.initialize] has completed successfully.
  final bool isInitialized;

  /// True when images from the camera are being streamed.
  final bool isStreaming;

  /// Description of an error state.
  ///
  /// This is null while the controller is not in an error state.
  /// When [hasError] is true this contains the error description.
  final String? errorDescription;

  /// The size of the preview in pixels.
  ///
  /// Is `null` until [isInitialized] is `true`.
  final Size? previewSize;

  /// Convenience getter for `previewSize.width / previewSize.height`.
  ///
  /// Can only be called when [initialize] is done.
  double get aspectRatio => previewSize!.width / previewSize!.height;

  /// Whether the controller is in an error state.
  ///
  /// When true [errorDescription] describes the error.
  bool get hasError => errorDescription != null;

  /// The focus mode the camera is currently set to.
  final FocusMode focusMode;

  /// The current device orientation.
  final DeviceOrientation deviceOrientation;

  /// Creates a modified copy of the object.
  ///
  /// Explicitly specified fields get the specified value, all other fields get
  /// the same value of the current object.
  CameraValue copyWith({
    bool? isInitialized,
    bool? isStreaming,
    String? errorDescription,
    Size? previewSize,
    FocusMode? focusMode,
    DeviceOrientation? deviceOrientation,
  }) {
    return CameraValue(
      isInitialized: isInitialized ?? this.isInitialized,
      errorDescription: errorDescription,
      previewSize: previewSize ?? this.previewSize,
      isStreaming: isStreaming ?? this.isStreaming,
      focusMode: focusMode ?? this.focusMode,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'isInitialized: $isInitialized, '
        'errorDescription: $errorDescription, '
        'previewSize: $previewSize, '
        'isStreaming: $isStreaming, '
        'focusMode: $focusMode, '
        'deviceOrientation: $deviceOrientation, ';
  }
}

/// Controls a device camera.
///
/// Use [availableCameras] to get a list of available cameras.
///
/// Before using a [CameraController] a call to [initialize] must complete.
///
/// To show the camera preview on the screen use a [CameraPreview] widget.
class CameraController extends ValueNotifier<CameraValue> {
  /// Creates a new camera controller in an uninitialized state.
  CameraController(
    this.description,
    this.resolutionPreset, {
    this.enableAudio = true,
    this.imageFormatGroup,
  }) : super(const CameraValue.uninitialized());

  /// The properties of the camera device controlled by this controller.
  final CameraDescription description;

  /// The resolution this controller is targeting.
  ///
  /// This resolution preset is not guaranteed to be available on the device,
  /// if unavailable a lower resolution will be used.
  ///
  /// See also: [ResolutionPreset].
  final ResolutionPreset resolutionPreset;

  /// Whether to include audio when recording a video.
  final bool enableAudio;

  /// The [ImageFormatGroup] describes the output of the raw image format.
  ///
  /// When null the imageFormat will fallback to the platforms default.
  final ImageFormatGroup? imageFormatGroup;

  /// The id of a camera that hasn't been initialized.
  @visibleForTesting
  static const int kUninitializedCameraId = -1;
  int _cameraId = kUninitializedCameraId;

  bool _isDisposed = false;
  StreamSubscription<dynamic>? _imageStreamSubscription;
  FutureOr<bool>? _initCalled;
  StreamSubscription? _deviceOrientationSubscription;

  /// Checks whether [CameraController.dispose] has completed successfully.
  ///
  /// This is a no-op when asserts are disabled.
  void debugCheckIsDisposed() {
    assert(_isDisposed);
  }

  /// The camera identifier with which the controller is associated.
  int get cameraId => _cameraId;

  /// Initializes the camera on the device.
  ///
  /// Throws a [CameraException] if the initialization fails.
  Future<void> initialize() async {
    if (_isDisposed) {
      throw CameraException(
        'Disposed CameraController',
        'initialize was called on a disposed CameraController',
      );
    }
    try {
      Completer<CameraInitializedEvent> _initializeCompleter = Completer();

      _deviceOrientationSubscription =
          CameraPlatform.instance.onDeviceOrientationChanged().listen((event) {
        value = value.copyWith(
          deviceOrientation: event.orientation,
        );
      });

      _cameraId = await CameraPlatform.instance.createCamera(
        description,
        resolutionPreset,
        enableAudio: enableAudio,
      );

      unawaited(CameraPlatform.instance
          .onCameraInitialized(_cameraId)
          .first
          .then((event) {
        _initializeCompleter.complete(event);
      }));

      await CameraPlatform.instance.initializeCamera(
        _cameraId,
        imageFormatGroup: imageFormatGroup ?? ImageFormatGroup.unknown,
      );

      value = value.copyWith(
        isInitialized: true,
        previewSize: await _initializeCompleter.future
          .then((CameraInitializedEvent event) => Size(
            event.previewWidth,
            event.previewHeight,
          )),
        focusMode: await _initializeCompleter.future.then((event) => event.focusMode),
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }

    _initCalled = true;
  }

 
  Future<void> startStreaming(onLatestImageAvailable onAvailable) async {
    assert(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
    _throwIfNotInitialized("startImageStream");
    

    try {
      await _channel.invokeMethod<void>('startStreaming');
      value = value.copyWith(isStreaming: true);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
    const EventChannel cameraEventChannel =
        EventChannel('video_stream/camera/Stream');
    _imageStreamSubscription =
        cameraEventChannel.receiveBroadcastStream().listen(
      (dynamic imageData) {
        onAvailable(CameraImage.fromPlatformData(imageData));
      },
    );
  }

  /// Stop streaming images from platform camera.
  ///
  /// Throws a [CameraException] if image streaming was not started or video
  /// recording was started.
  ///
  /// The `stopImageStream` method is only available on Android and iOS (other
  /// platforms won't be supported in current setup).
  Future<void> stopStreaming() async {
    assert(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
    _throwIfNotInitialized("stopImageStream");

    try {
      value = value.copyWith(isStreaming: false);
      await _channel.invokeMethod<void>('stopStreaming');
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }

    await _imageStreamSubscription?.cancel();
    _imageStreamSubscription = null;
  }

  /// Returns a widget showing a live camera preview.
  Widget buildPreview() {
    _throwIfNotInitialized("buildPreview");
    try {
      return CameraPlatform.instance.buildPreview(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Gets the maximum supported zoom level for the selected camera.
  Future<double> getMaxZoomLevel() {
    _throwIfNotInitialized("getMaxZoomLevel");
    try {
      return CameraPlatform.instance.getMaxZoomLevel(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Gets the minimum supported zoom level for the selected camera.
  Future<double> getMinZoomLevel() {
    _throwIfNotInitialized("getMinZoomLevel");
    try {
      return CameraPlatform.instance.getMinZoomLevel(_cameraId);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Set the zoom level for the selected camera.
  ///
  /// The supplied [zoom] value should be between 1.0 and the maximum supported
  /// zoom level returned by the `getMaxZoomLevel`. Throws an `CameraException`
  /// when an illegal zoom level is suplied.
  Future<void> setZoomLevel(double zoom) {
    _throwIfNotInitialized("setZoomLevel");
    try {
      return CameraPlatform.instance.setZoomLevel(_cameraId, zoom);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  

  /// Sets the focus mode for taking pictures.
  Future<void> setFocusMode(FocusMode mode) async {
    try {
      await CameraPlatform.instance.setFocusMode(_cameraId, mode);
      value = value.copyWith(focusMode: mode);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Sets the focus point for automatically determining the focus value.
  ///
  /// Supplying a `null` value will reset the focus point to it's default
  /// value.
  Future<void> setFocusPoint(Offset? point) async {
    if (point != null &&
        (point.dx < 0 || point.dx > 1 || point.dy < 0 || point.dy > 1)) {
      throw ArgumentError(
          'The values of point should be anywhere between (0,0) and (1,1).');
    }
    try {
      await CameraPlatform.instance.setFocusPoint(
        _cameraId,
        point == null
            ? null
            : Point<double>(
                point.dx,
                point.dy,
              ),
      );
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  /// Releases the resources of this camera.
  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    unawaited(_deviceOrientationSubscription?.cancel());
    _isDisposed = true;
    super.dispose();
    if (_initCalled != null) {
      await _initCalled;
      await CameraPlatform.instance.dispose(_cameraId);
    }
  }

  void _throwIfNotInitialized(String functionName) {
    if (!value.isInitialized) {
      throw CameraException(
        'Uninitialized CameraController',
        '$functionName() was called on an uninitialized CameraController.',
      );
    }
    if (_isDisposed) {
      throw CameraException(
        'Disposed CameraController',
        '$functionName() was called on a disposed CameraController.',
      );
    }
  }
}
