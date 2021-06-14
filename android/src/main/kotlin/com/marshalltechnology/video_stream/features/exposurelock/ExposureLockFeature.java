package com.marshalltechnology.video_stream.features.exposurelock;

import android.hardware.camera2.CaptureRequest;
import com.marshalltechnology.video_stream.CameraProperties;
import com.marshalltechnology.video_stream.features.CameraFeature;

/** Controls whether or not the exposure mode is currently locked or automatically metering. */
public class ExposureLockFeature extends CameraFeature<ExposureMode> {

    private ExposureMode currentSetting = ExposureMode.auto;

    /**
     * Creates a new instance of the {@see ExposureLockFeature}.
     *
     * @param cameraProperties Collection of the characteristics for the current camera device.
     */
    public ExposureLockFeature(CameraProperties cameraProperties) {
        super(cameraProperties);
    }

    @Override
    public String getDebugName() {
        return "ExposureLockFeature";
    }

    @Override
    public ExposureMode getValue() {
        return currentSetting;
    }

    @Override
    public void setValue(ExposureMode value) {
        this.currentSetting = value;
    }

    // Available on all devices.
    @Override
    public boolean checkIsSupported() {
        return true;
    }

    @Override
    public void updateBuilder(CaptureRequest.Builder requestBuilder) {
        if (!checkIsSupported()) {
            return;
        }

        requestBuilder.set(CaptureRequest.CONTROL_AE_LOCK, currentSetting == ExposureMode.locked);
    }
}
