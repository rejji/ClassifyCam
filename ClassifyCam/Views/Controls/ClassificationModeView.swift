//
//  ClassificationModeView.swift
//  AVCam
//
//  Created by Rajeev Bakshi on 14/10/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ClassificationModeView<CameraModel: Camera>: View {
    @State var camera: CameraModel
    @Binding private var direction: SwipeDirection

    init(camera: CameraModel, direction: Binding<SwipeDirection>) {
        self.camera = camera
        _direction = direction
    }
    
    var body: some View {
        Picker("Classification Mode", selection: $camera.classificationMode) {
            ForEach(ClassificationMode.allCases) {
                Image(systemName: $0.systemName)
                    .tag($0.rawValue)
            }
        }
        .frame(width: 180)
        .pickerStyle(.segmented)
        .tint(.purple)
        //.disabled(camera.captureActivity.isRecording)
        //.disabled(camera.captureMode != .video) //allow with photo also
        .onChange(of: direction) { _, _ in
            let modes = ClassificationMode.allCases
            let selectedIndex = modes.firstIndex(of: camera.classificationMode) ?? -1
            // Increment the selected index when swiping right.
            let increment = direction == .right
            let newIndex = selectedIndex + (increment ? 1 : -1)
            
            guard newIndex >= 0, newIndex < modes.count else { return }
            camera.classificationMode = modes[newIndex]
        }
    }
}

#if DEBUG
#Preview {
    ClassificationModeView(camera: PreviewCameraModel(),  direction: .constant(.left))
}
#endif
