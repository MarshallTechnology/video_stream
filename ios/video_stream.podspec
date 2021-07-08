#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint video_stream.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'video_stream'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter package to stream video to RTMP server.'
  s.description      = <<-DESC
A new Flutter package to stream video to RTMP server.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'HaishinKit', '~> 1.0.10'
  s.platform = :ios, '8.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
