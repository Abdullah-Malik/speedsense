//
//  GyroscopeView.swift
//  SpeedSense
//
//  Created by Abdullah Malik on 11/30/24.
//

import SwiftUI

struct GyroscopeView: View {
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        VStack {
            Text("Gyroscope")
                .font(.headline)

            GraphView(title: "X-Axis", values: motionManager.gyroscopeData.map { $0.x })
            GraphView(title: "Y-Axis", values: motionManager.gyroscopeData.map { $0.y })
            GraphView(title: "Z-Axis", values: motionManager.gyroscopeData.map { $0.z })
            GraphView(title: "Magnitude", values: motionManager.gyroscopeData.compactMap { $0.magnitude })
        }
        .onAppear {
            motionManager.startGyroscopeUpdates()
        }
        .onDisappear {
            motionManager.stopGyroUpdates()
        }
    }
}
