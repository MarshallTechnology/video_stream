// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'camera.dart';

/// A single color plane of image data.
///
/// The number and meaning of the planes in an image are determined by the
/// format of the Image.
class Plane {
  final Uint8List bytes;
  final int? bytesPerPixel;
  final int bytesPerRow;
  final int? height;
  final int? width;
  
  Plane._fromPlatformData(Map<dynamic, dynamic> data)
      : bytes = data['bytes'],
        bytesPerPixel = data['bytesPerPixel'],
        bytesPerRow = data['bytesPerRow'],
        height = data['height'],
        width = data['width'];

}

// TODO:Turn [ImageFormatGroup] to a class with int values.

enum ImageFormatGroup {
  /// The image format does not fit into any specific group.
  unknown,

  /// Multi-plane YUV 420 format.
  ///
  /// This format is a generic YCbCr format, capable of describing any 4:2:0
  /// chroma-subsampled planar or semiplanar buffer (but not fully interleaved),
  /// with 8 bits per color sample.
  ///
  /// On Android, this is `android.graphics.ImageFormat.YUV_420_888`. See
  /// https://developer.android.com/reference/android/graphics/ImageFormat.html#YUV_420_888
  ///
  /// On iOS, this is `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange`. See
  /// https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers/kcvpixelformattype_420ypcbcr8biplanarvideorange?language=objc
  yuv420,

  /// 32-bit BGRA.
  ///
  /// On iOS, this is `kCVPixelFormatType_32BGRA`. See
  /// https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers/kcvpixelformattype_32bgra?language=objc
  bgra8888,
}

/// Describes how pixels are represented in an image.
class ImageFormat {
  ImageFormat._fromPlatformData(this.raw) : group = _asImageFormatGroup(raw);
  final ImageFormatGroup group;

  /// Raw version of the format from the Android or iOS platform.
  ///
  /// On Android, this is an `int` from class `android.graphics.ImageFormat`. See
  /// https://developer.android.com/reference/android/graphics/ImageFormat
  ///
  /// On iOS, this is a `FourCharCode` constant from Pixel Format Identifiers.
  /// See https://developer.apple.com/documentation/corevideo/1563591-pixel_format_identifiers?language=objc
  final dynamic raw;
}

ImageFormatGroup _asImageFormatGroup(dynamic rawFormat) {
  if (defaultTargetPlatform == TargetPlatform.android) {
    // android.graphics.ImageFormat.YUV_420_888
    if (rawFormat == 35) {
      return ImageFormatGroup.yuv420;
    }
  }

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    switch (rawFormat) {
      // kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
      case 875704438:
        return ImageFormatGroup.yuv420;
      // kCVPixelFormatType_32BGRA
      case 1111970369:
        return ImageFormatGroup.bgra8888;
    }
  }

  return ImageFormatGroup.unknown;
}

class CameraImage {
  final ImageFormat format;
  final int height;
  final int width;
  final List<Plane> planes;

  CameraImage._fromPlatformData(Map<dynamic, dynamic> data)
    : format = ImageFormat._fromPlatformData(data['format']),
      height = data['height'],
      width = data['width'],
      planes = List<Plane>.unmodifiable(data['planes'].map((dynamic planeData) => Plane._fromPlatformData(planeData)));

}
