/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The top-level view for the app.
*/

import SwiftUI

/// The main view that contains the app content.
struct ContentView<CameraModel: Camera>: View {
    /// Indicates whether to display the setup workflow.
    @State var showSetup = true

    @State var camera: CameraModel

    /// A configuration for managing the characteristics of a sound classification task.
    //@State var appConfig = AppConfiguration()
    @Binding var appConfig: AppConfiguration // = AppConfiguration()

    /// The runtime state that contains information about the strength of the detected sounds.
    @StateObject var appState: AppState // = AppState()
    @State var isRecording: Bool
    @State var showDetectctionView = false
    @Binding var classificationMode: ClassificationMode
    //@Binding var overlaySoundDetectionView: Bool
    @Binding var showClassificationSetup: Bool
    
    init(camera: CameraModel,
         appConfig: Binding<AppConfiguration>,
         classificationMode: Binding<ClassificationMode>,
         //overlaySoundDetectionView: Binding<Bool>,
         showClassificationSetup: Binding<Bool>
    ) {
        _appState = StateObject(wrappedValue: camera.appState)
        //appConfig = camera.appConfig
        _appConfig = appConfig
        self.camera = camera
        _isRecording = State(wrappedValue: camera.captureActivity.isRecording)
        _classificationMode = classificationMode
        //_overlaySoundDetectionView = overlaySoundDetectionView
        _showClassificationSetup = showClassificationSetup
    }

    var body: some View {
        ZStack {
            //if (showSetup && !camera.captureActivity.isRecording) {
            if (camera.showClassificationSetup && !camera.captureActivity.isRecording) {
                SetupMonitoredSoundsView (
                    querySoundOptions: {
                        return try AppConfiguration.listAllValidSoundIdentifiers()
                    },
                    selectedSounds: $appConfig.monitoredSounds,
                    doneAction: {
                        //showSetup = false
                        showClassificationSetup = false
                        //if camera.captureActivity.isRecording {
                            camera.appState.restartDetection(config: appConfig)
                        //}
                        showDetectctionView = true
                    }
                )
                .background(Color.black.opacity(0.8))
                .offset(y: (camera.captureMode == .video) ? -35 : 0)
            /*
            } else if !camera.captureActivity.isRecording {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            overlaySoundDetectionView = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    Text("Press Video Record Button")
                        .foregroundColor(.white)
                        .padding()
                }
                .background(.black)
            */
            } else { //if showDetectctionView {
                DetectSoundsView(
                    state: appState,
                    isRecording: camera.captureActivity.isRecording,
                    config: $appConfig,
                    classificationMode: $classificationMode,
                    configureAction: {
                        //showSetup = true
                        showClassificationSetup = true
                    },
                    dismissAction: {
                        showDetectctionView = false
                    }
                )
                .background(Color.black.opacity(0.8))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockCamera = CameraModel()
        let appConfig = AppConfiguration()

        return ContentView(
            camera: mockCamera,
            appConfig: .constant(appConfig),
            classificationMode: .constant(.classify),
            //overlaySoundDetectionView: .constant(true),
            showClassificationSetup: .constant(false)
        )
        .aspectRatio(classificationAspectRatio, contentMode: .fit)
        .offset(y: -100)
    }
}
