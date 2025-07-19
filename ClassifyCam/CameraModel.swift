/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the camera.
*/

import SwiftUI
import Combine

/// An object that provides the interface to the features of the camera.
///
/// This object provides the default implementation of the `Camera` protocol, which defines the interface
/// to configure the camera hardware and capture media. `CameraModel` doesn't perform capture itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `CaptureService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewCameraModel` instead.
///
@Observable
final class CameraModel: Camera {
    
    /// The current status of the camera, such as unauthorized, running, or failed.
    private(set) var status = CameraStatus.unknown
    
    /// The current state of photo or movie capture.
    private(set) var captureActivity = CaptureActivity.idle
    
    /// The photo features that a person can enable in the user interface.
    private(set) var photoFeatures = PhotoFeatures()
    
    /// A Boolean value that indicates whether the app is currently switching video devices.
    private(set) var isSwitchingVideoDevices = false
    
    /// A Boolean value that indicates whether the app is currently switching capture modes.
    private(set) var isSwitchingModes = false
    private(set) var isSwitchingClassificatinMode = false
    
    /// A Boolean value that indicates whether to show visual feedback when capture begins.
    private(set) var shouldFlashScreen = false
    
    /// A thumbnail for the last captured photo or video.
    private(set) var thumbnail: CGImage?
    
    /// An error that indicates the details of an error during photo or movie capture.
    private(set) var error: Error?
    
    /// An object that provides the connection between the capture session and the video preview layer.
    var previewSource: PreviewSource { captureService.previewSource }
    
    /// A Boolean that indicates whether the camera supports HDR video recording.
    private(set) var isHDRVideoSupported = false
    
    /// An object that saves captured media to a person's Photos library.
    private let mediaLibrary = MediaLibrary()
    
    /// An object that manages the app's capture functionality.
    private let captureService = CaptureService()

    var appConfig = AppConfiguration()
    var appState = AppState()
    //var overlaySoundDetectionView = false
    var showClassificationSetup = false

    init() {
        //
    }
    
    // MARK: - Starting the camera
    /// Start the camera and begin the stream of data.
    func start() async {
        // Verify that the person authorizes the app to use device cameras and microphones.
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        do {
            // Start the capture service to start the flow of data.
            try await captureService.start()
            //appState.restartDetection(config: appConfig)
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service. \(error)")
            status = .failed
        }
    }
    
    // MARK: - Changing modes and devices
    
    /// A value that indicates the mode of capture for the camera.
    var captureMode = CaptureMode.photo {
        didSet {
            Task {
                isSwitchingModes = true
                defer { isSwitchingModes = false }
                // Update the configuration of the capture service for the new mode.
                try? await captureService.setCaptureMode(captureMode)

                /*
                 TODO: Not sure why subject is no longer in observation state
                 
                 But anyhow, since the capture mode is changed, restart is required
                 and the state of classification capture should be restarted.
                */
                if (classificationMode == .classify) {
                    appState.restartDetection(config: appConfig) //
                }
            }
        }
    }
    
    var classificationMode = ClassificationMode.noClassify {
        didSet {
            Task {
                isSwitchingClassificatinMode = true
                defer { isSwitchingClassificatinMode = false }
                // Update the configuration of the capture service for the new mode.
                try? await captureService.setClassificationMode(classificationMode)
                //print("classificationMode: \(classificationMode)")
                if classificationMode == .noClassify {
                    SystemAudioClassifier.singleton.stopSoundClassification()
                } else {
                    appState.restartDetection(config: appConfig) // when separate button given to ClassificationSettingView //Not reqd when same button was used for settings -> Done -> start classification
                //} else { //
                //   print("starting classification here can loose settings prerequisite") //But that would not precede settings for sounds to be identified. Hence not choosing it.
                }
            }
        }
    }

    
    /// Selects the next available video device for capture.
    func switchVideoDevices() async {
        isSwitchingVideoDevices = true
        defer { isSwitchingVideoDevices = false }
        await captureService.selectNextVideoDevice()
    }
    
    // MARK: - Photo capture
    
    /// Captures a photo and writes it to the user's Photos library.
    func capturePhoto() async {
        do {
            let photo = try await captureService.capturePhoto(with: photoFeatures.current)
            try await mediaLibrary.save(photo: photo)
        } catch {
            self.error = error
        }
    }
    
    /// Performs a focus and expose operation at the specified screen point.
    func focusAndExpose(at point: CGPoint) async {
        await captureService.focusAndExpose(at: point)
    }
    
    /// Sets the `showCaptureFeedback` state to indicate that capture is underway.
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.01)) {
            shouldFlashScreen = false
        }
    }
    
    // MARK: - Video capture
    /// A Boolean value that indicates whether the camera captures video in HDR format.
    var isHDRVideoEnabled = false {
        didSet {
            Task {
                await captureService.setHDRVideoEnabled(isHDRVideoEnabled)
            }
        }
    }
    
    /// Toggles the state of recording.
    func toggleRecording() async {
        switch await captureService.captureActivity {
        case .movieCapture:
            do {
                /* Not reqd after separate button for ClassificationSettingView
                if appState.soundDetectionIsRunning {
                    SystemAudioClassifier.singleton.stopSoundClassification()
                    appState.soundDetectionIsRunning = false
                } else {
                    print("soundDetectionIsRunning: false already")
                }
                 */
                // If currently recording, stop the recording and write the movie to the library.
                let movie = try await captureService.stopRecording()
                try await mediaLibrary.save(movie: movie)
            } catch {
                self.error = error
            }
        default:
            // In any other case, start recording.
            await captureService.startRecording()

            /*
             TODO: Not sure why subject is no longer in observation state
             
             But anyhow, since the recording mode is started, restart is required
             and the state of classification capture should be restarted.
            */
            if (classificationMode == .classify) {
                appState.restartDetection(config: appConfig) //
            }
            
            /*
            Start classification, this is to come after startRecording(), probably because of some prerequisite
            On further check, ordering wrt this statement is important: connection.preferredVideoStabilizationMode = .auto
            */
            //if !appState.soundDetectionIsRunning {
                //appState.restartDetection(config: appConfig) // sets soundDetectionIsRunning
            //} else {
            //    print("soundDetectionIsRunning: true already")
            //}
            
            /* Not reqd after giving separate button for ClassificationSettingView
            if classificationMode == .classify {
                overlaySoundDetectionView = true
                showClassificationSetup = false
                appState.restartDetection(config: appConfig)
            } else {
                print("classificationMode is not set")
            }
             */
        }
    }
    
    // MARK: - Internal state observations
    
    // Set up camera's state observations.
    private func observeState() {
        Task {
            // Await new thumbnails that the media library generates when saving a file.
            for await thumbnail in mediaLibrary.thumbnails.compactMap({ $0 }) {
                self.thumbnail = thumbnail
            }
        }
        
        Task {
            // Await new capture activity values from the capture service.
            for await activity in await captureService.$captureActivity.values {
                if activity.willCapture {
                    // Flash the screen to indicate capture is starting.
                    flashScreen()
                } else {
                    // Forward the activity to the UI.
                    captureActivity = activity
                }
            }
        }
        
        Task {
            // Await updates to the capabilities that the capture service advertises.
            for await capabilities in await captureService.$captureCapabilities.values {
                isHDRVideoSupported = capabilities.isHDRSupported
            }
        }
    }
}

