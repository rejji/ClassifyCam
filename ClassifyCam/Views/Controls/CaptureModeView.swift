/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that toggles the camera's capture mode.
*/

import SwiftUI

/// A view that toggles the camera's capture mode.
struct CaptureModeView<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    @Binding private var direction: SwipeDirection
    @ObservedObject var appState: AppState
    
    init(camera: CameraModel, direction: Binding<SwipeDirection>) {
        self.camera = camera
        _direction = direction
        self.appState = camera.appState
    }
    
    var body: some View {
        HStack {
            Spacer()
            Picker("Capture Mode", selection: $camera.captureMode) {
                ForEach(CaptureMode.allCases) {
                    Image(systemName: $0.systemName)
                        .tag($0.rawValue)
                }
            }
            .frame(width: 180)
            .pickerStyle(.segmented)
            .disabled(camera.captureActivity.isRecording)
            .onChange(of: direction) { _, _ in
                let modes = CaptureMode.allCases
                let selectedIndex = modes.firstIndex(of: camera.captureMode) ?? -1
                // Increment the selected index when swiping right.
                let increment = direction == .right
                let newIndex = selectedIndex + (increment ? 1 : -1)
                
                guard newIndex >= 0, newIndex < modes.count else { return }
                camera.captureMode = modes[newIndex]
            }


            Spacer()
            
            /*

             HStack {
                Button(action: { appState.restartDetection(config: camera.appConfig) }) {
                    Image(systemName:
                            appState.soundDetectionIsRunning
                          ? "waveform" : "waveform.slash")
                    .foregroundColor(appState.soundDetectionIsRunning ? Color.white : Color.white)
                    .background(appState.soundDetectionIsRunning ? Color.green : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    //.opacity(appState.soundDetectionIsRunning ? 1.0 : 0.5)
                    .padding(.trailing, 5)
                }
                .disabled(appState.soundDetectionIsRunning)
                .buttonStyle(PlainButtonStyle())
                
                /* - This works -
                 HStack {
                 Text("Sound Detection Paused").padding()
                 Button(action: { camera.appState.restartDetection(config: camera.appConfig) }) {
                 Text("Start")
                 }
                 }.opacity(camera.appState.soundDetectionIsRunning ? 0.0 : 1.0)
                 .disabled(camera.appState.soundDetectionIsRunning)
                 */

                Button(action: {
                    print("showClassificationView: \(camera.showClassificationView)")
                    camera.showClassificationView.toggle()
                    print("showClassificationView: \(camera.showClassificationView)")
                }) {
                    Image(systemName:
                            camera.showClassificationView
                          ? "square" : "square.grid.2x2" )
                    .foregroundColor(Color.white)
                    .padding(10)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    //.opacity(appState.soundDetectionIsRunning ? 1.0 : 0.5)
                    .padding(.trailing, 5)
                }
                .buttonStyle(PlainButtonStyle())

            }

            */
        }
    }
}

#if DEBUG

#Preview {
    CaptureModeView(camera: PreviewCameraModel(), direction: .constant(.left))
}
#endif
