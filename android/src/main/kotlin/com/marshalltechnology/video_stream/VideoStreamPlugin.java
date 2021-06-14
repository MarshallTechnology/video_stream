package com.marshalltechnology.video_stream;
import android.app.Activity;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.view.TextureRegistry;

public final class VideoStreamPlugin implements FlutterPlugin, ActivityAware {
    private static final String TAG = "CameraPlugin";
    private @Nullable
    FlutterPluginBinding flutterPluginBinding;
    private @Nullable MethodCallHandlerImpl methodCallHandler;

    public VideoStreamPlugin() {

    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = binding;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = null;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        maybeStartListening(
                binding.getActivity(),
                flutterPluginBinding.getBinaryMessenger(),
                binding::addRequestPermissionsResultListener,
                flutterPluginBinding.getTextureRegistry());
    }

    @Override
    public void onDetachedFromActivity() {
        if (methodCallHandler == null) {
            // Could be on too low of an SDK to have started listening originally.
            return;
        }

        methodCallHandler.stopListening();
        methodCallHandler = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    private void maybeStartListening(
            Activity activity,
            BinaryMessenger messenger,
            CameraPermissions.PermissionsRegistry permissionsRegistry,
            TextureRegistry textureRegistry) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            // If the sdk is less than 21 (min sdk for Camera2) we don't register the plugin.
            return;
        }

        methodCallHandler =
                new MethodCallHandlerImpl(
                        activity, messenger, new CameraPermissions(), permissionsRegistry, textureRegistry);
    }
}
