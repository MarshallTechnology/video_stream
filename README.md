# video_stream

A new Flutter package for basic live streaming video to RTMP server.

## Getting Started

This plugin is an simplified version of [camera_with_rtmp](https://pub.dev/packages/camera_with_rtmp) an extension of the flutter 
[camera plugin](https://pub.dev/packages/camera) to add in
rtmp streaming as part of the system.  It works on android and iOS
(but not web).
   
## Features:

* Display live camera preview in a widget.
* stream video to a rtmp server.

### iOS

Add two rows to the `ios/Runner/Info.plist`:

* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description.

Or in text format add the key:

```xml
<key>NSCameraUsageDescription</key>
<string>Can I use the camera please?</string>
<key>NSMicrophoneUsageDescription</key>
<string>Can I use the mic please?</string>
```

### Android

Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```
minSdkVersion 21
```

Need to add in a section to the packaging options to exclude a file, or gradle will error on building.

```
packagingOptions {
   exclude 'project.clj'
}
```