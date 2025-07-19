/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Camera implementation to use when working with SwiftUI previews.
*/

import Foundation
import SwiftUI

@Observable
class PreviewCameraModel: Camera {

    var shouldFlashScreen = false
    var isHDRVideoSupported = false
    var isHDRVideoEnabled = false
    var appState = AppState() // check it?
    var appConfig = AppConfiguration() // check it?
    //var overlaySoundDetectionView = false
    var showClassificationSetup = false
    
    struct PreviewSourceStub: PreviewSource {
        // Stubbed out for test purposes.
        func connect(to target: PreviewTarget) {}
    }
    
    let previewSource: PreviewSource = PreviewSourceStub()
    
    private(set) var status = CameraStatus.unknown
    private(set) var captureActivity = CaptureActivity.idle
    var captureMode = CaptureMode.photo {
        didSet {
            isSwitchingModes = true
            Task {
                // Create a short delay to mimic the time it takes to reconfigure the session.
                try? await Task.sleep(until: .now + .seconds(0.3), clock: .continuous)
                self.isSwitchingModes = false
            }
        }
    }
    var classificationMode = ClassificationMode.noClassify {
        didSet {
            isSwitchingClassificationModes = true
            Task {
                // Create a short delay to mimic the time it takes to reconfigure the session.
                try? await Task.sleep(until: .now + .seconds(0.3), clock: .continuous)
                self.isSwitchingClassificationModes = false
            }
        }
    }
    private(set) var isSwitchingModes = false
    private(set) var isSwitchingClassificationModes = false
    private(set) var isVideoDeviceSwitchable = true
    private(set) var isSwitchingVideoDevices = false
    private(set) var photoFeatures = PhotoFeatures()
    private(set) var thumbnail: CGImage?
    
    var error: Error?
    
    init(captureMode: CaptureMode = .photo, status: CameraStatus = .unknown, classificationMode: ClassificationMode = .noClassify) {
        self.captureMode = captureMode
        self.status = status
        self.classificationMode = classificationMode
    }
    
    func start() async {
        if status == .unknown {
            status = .running
        }
    }
    
    func switchVideoDevices() {
        logger.debug("Device switching isn't implemented in PreviewCamera.")
    }
    
    func capturePhoto() {
        logger.debug("Photo capture isn't implemented in PreviewCamera.")
    }
    
    func toggleRecording() {
        logger.debug("Moving capture isn't implemented in PreviewCamera.")
    }
    
    func focusAndExpose(at point: CGPoint) {
        logger.debug("Focus and expose isn't implemented in PreviewCamera.")
    }
    
    var recordingTime: TimeInterval { .zero }
    
    private func capabilities(for mode: CaptureMode) -> CaptureCapabilities {
        switch mode {
        case .photo:
            return CaptureCapabilities(isFlashSupported: true,
                                       isLivePhotoCaptureSupported: true)
        case .video:
            return CaptureCapabilities(isFlashSupported: false,
                                       isLivePhotoCaptureSupported: false,
                                       isHDRSupported: true)
        }
    }
}
