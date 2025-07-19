//
//  ClassifyCamApp.swift
//  ClassifyCam
//
//  Created by Rajeev Bakshi on 21/10/24.
//

import os
import SwiftUI

@main
struct ClassifyCamApp: App {
    // Simulator doesn't support the AVFoundation capture APIs. Use the preview camera when running in Simulator.
    @State private var camera = CameraModel()

    var body: some Scene {
        WindowGroup {
            CameraView(camera: camera)
                .statusBarHidden(true)
                .task {
                    // Start the capture pipeline.
                    await camera.start()
                }
        }
    }
}

/// A global logger for the app.
let logger = Logger()
