/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents the main camera user interface.
*/

import SwiftUI
import AVFoundation

/// A view that presents the main camera user interface.
struct CameraUI<CameraModel: Camera>: PlatformView {

    @State var camera: CameraModel
    @Binding var swipeDirection: SwipeDirection
    @Binding var swipeDirection_2: SwipeDirection

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        Group {
            if isRegularSize {
                regularUI
            } else {
                compactUI
            }
        }
        .overlay(alignment: .top) {
            switch camera.captureMode {
            case .photo:
                LiveBadge()
                    .opacity(camera.captureActivity.isLivePhoto ? 1.0 : 0.0)
            case .video:
                RecordingTimeView(time: camera.captureActivity.currentTime, appState: camera.appState)
                    .offset(y: isRegularSize ? 20 : 0)
            }
        }
        .overlay {
            StatusOverlayView(status: camera.status)
        }
    }
    
    /// This view arranges UI elements vertically.
    @ViewBuilder
    var compactUI: some View {
        //let _ = print("CameraUI:\n\tclassificationMode: \(camera.classificationMode),\n\tshowClassificationSetup: \(camera.showClassificationSetup)")
        VStack(spacing: 0) {
            FeaturesToolbar(camera: camera)
            Spacer()
            //ClassificationModeView(camera: camera, direction: $swipeDirection_2)
            HStack (spacing: 0) {
                //Rectangle()
                    //.frame(width: 40, height: 0)
                ClassificationSettingView(camera: camera, showClassificationSetup: $camera.showClassificationSetup)
                .frame(width: 40)

                CaptureModeView(camera: camera, direction: $swipeDirection)
                    .frame(width: 300)

                ClassificationModeView2(camera: camera, direction: $swipeDirection_2)
                .frame(width: 40)

            }
            .frame(maxWidth: .infinity)
            MainToolbar(camera: camera)
                .padding(.bottom, bottomPadding)
        }
    }
    
    /// This view arranges UI elements in a layered stack.
    @ViewBuilder
    var regularUI: some View {
        VStack {
            Spacer()
            ZStack {
                ClassificationModeView(camera: camera, direction: $swipeDirection_2)
                    .offset(x: -550) // The vertical offset from center.
                HStack (spacing: 0) {
                    ClassificationSettingView(camera: camera, showClassificationSetup: $camera.showClassificationSetup)
                    .frame(width: 40)

                    CaptureModeView(camera: camera, direction: $swipeDirection)
                        .offset(x: -250) // The vertical offset from center.

                    ClassificationModeView2(camera: camera, direction: $swipeDirection_2)
                    .frame(width: 40)

                }
                MainToolbar(camera: camera)
                FeaturesToolbar(camera: camera)
                    .frame(width: 250)
                    .offset(x: 250) // The vertical offset from center.
            }
            .frame(width: 740)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(12)
            .padding(.bottom, 32)
        }
    }
    
    var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded {
                // Capture the swipe direction.
                swipeDirection = $0.translation.width < 0 ? .left : .right
            }
    }
    
    var bottomPadding: CGFloat {
        // Dynamically calculate the offset for the bottom toolbar in iOS.
        let bounds = UIScreen.main.bounds
        let rect = AVMakeRect(aspectRatio: movieAspectRatio, insideRect: bounds)
        return (rect.minY.rounded() / 2) + 12
    }
}

#if DEBUG

#Preview {
    CameraUI(camera: PreviewCameraModel(captureMode: .video),
             swipeDirection: .constant(.left),
             swipeDirection_2: .constant(.left))
}

#Preview {
    CameraUI(camera: PreviewCameraModel(),
             swipeDirection: .constant(.left),
             swipeDirection_2: .constant(.left))
             //showClassificationView: .constant(false))
}

#endif
