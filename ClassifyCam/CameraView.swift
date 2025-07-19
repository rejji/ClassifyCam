/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI
import AVFoundation

@MainActor
struct CameraView<CameraModel: Camera>: PlatformView {
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    // The direction a person swipes on the camera preview or mode selector.
    @State var swipeDirection = SwipeDirection.left
    @State var swipeDirection_2 = SwipeDirection.left
    
    //@State private var showClassificationView: Bool = false
    
    var body: some View {
        //let _ = print("CameraView - \n\tclassificationMode: \(camera.classificationMode), \n\tshowClassificationSetup: \(camera.showClassificationSetup)\n")
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                CameraPreview(source: camera.previewSource)
                    .onTapGesture { location in
                        // Focus and expose at the tapped point.
                        Task { await camera.focusAndExpose(at: location) }
                    }
                    .simultaneousGesture(swipeGesture)
                    /// The value of `shouldFlashScreen` changes briefly to `true` when capture
                    /// starts, then immediately changes to `false`. Use this to
                    /// flash the screen to provide visual feedback.
                    .opacity(camera.shouldFlashScreen ? 0 : 1)
                /*
                if ((
                    (camera.classificationMode == ClassificationMode.classify) /*&&
                    camera.overlaySoundDetectionView*/)
                    || camera.showClassificationSetup )
                {*/
                        ContentView2(
                            camera: camera,
                            appConfig: $camera.appConfig,
                            classificationMode: $camera.classificationMode,
                            //overlaySoundDetectionView: $camera.overlaySoundDetectionView,
                            showClassificationSetup: $camera.showClassificationSetup
                        )
                        .opacity(0.7)
                        .aspectRatio(classificationAspectRatio, contentMode: .fit)
                        .offset(y: camera.captureMode == .video ? -35 : 0)
                        //.offset(y: ( (camera.captureMode == .video) ? -100 : 10))
                    //}
            }
            // The main camera user interface.
            CameraUI(camera: camera, swipeDirection: $swipeDirection, swipeDirection_2: $swipeDirection_2)
        }
    }

    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded {
                // Capture swipe direction.
                swipeDirection = $0.translation.width < 0 ? .left : .right
            }
    }
}

enum SwipeDirection {
    case left
    case right
    case up
    case down
}

#if DEBUG

#Preview {
    CameraView(camera: PreviewCameraModel(captureMode: .video, classificationMode: .classify))
}
#Preview {
    CameraView(camera: PreviewCameraModel(captureMode: .video))
}
#Preview {
    CameraView(camera: PreviewCameraModel())
}
#endif

