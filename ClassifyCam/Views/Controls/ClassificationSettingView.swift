//
//  ClassificationSettingView.swift
//  AVCam
//
//  Created by Rajeev Bakshi on 18/10/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI

struct ClassificationSettingView<CameraModel: Camera>: View {
    @State var camera: CameraModel
    @Binding var showClassificationSetup: Bool

    init(
        camera: CameraModel,
        showClassificationSetup: Binding<Bool>
    ) {
        self.camera = camera
        _showClassificationSetup = showClassificationSetup
    }

    var body: some View {
        HStack {
            Button(action: {
                showClassificationSetup.toggle()
                print("showClassificationSetup button pressed")
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 20))
                    .foregroundColor(Color.white)
                    .padding(5)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.5))
                    )
            }
            
            Spacer()
        }
    }

}

#if DEBUG

#Preview {
    ClassificationSettingView(
        camera: PreviewCameraModel(),
        showClassificationSetup: .constant(true)
    )
}

#endif
