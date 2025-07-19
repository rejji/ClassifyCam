//
//  ClassificationModeView.swift
//  AVCam
//
//  Created by Rajeev Bakshi on 14/10/24.
//  Copyright ©️ 2024 Apple. All rights reserved.
//

import SwiftUI

struct ClassificationModeView2<CameraModel: Camera>: View {
    @State var camera: CameraModel
    @Binding private var direction: SwipeDirection

    init(camera: CameraModel,
         direction: Binding<SwipeDirection>
    ) {
        self.camera = camera
        _direction = direction
    }
    
    var body: some View {
        HStack {
            Spacer()

            // Toggle button with waveform icons
            Button(action: toggleClassificationMode) {
                Image(systemName: camera.classificationMode == .classify ? "waveform" : "waveform.slash")
                    .font(.system(size: 20))
                    .foregroundColor(
                        camera.classificationMode == .classify ? .green : .white.opacity(0.7)
                    )
                    //.padding(5)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(camera.classificationMode == .classify ? 0.5 : 0.2))
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .onChange(of: direction) { _, _ in
            let modes = ClassificationMode.allCases
            let selectedIndex = modes.firstIndex(of: camera.classificationMode) ?? -1
            let increment = direction == .right
            let newIndex = selectedIndex + (increment ? 1 : -1)
            
            guard newIndex >= 0, newIndex < modes.count else { return }
            camera.classificationMode = modes[newIndex]
        }
    }

    /// Toggles between the available classification modes.
    private func toggleClassificationMode() {
        camera.classificationMode = camera.classificationMode == .classify ? .noClassify : .classify
    }
}

#if DEBUG

#Preview {
    ClassificationModeView2(camera: PreviewCameraModel(), direction: .constant(.left))
}

#endif
