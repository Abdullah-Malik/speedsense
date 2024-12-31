//
//  SensorDataView.swift
//  SpeedSense
//
//  Created by Abdullah Malik on 11/30/24.
//

import SwiftUI

enum SensorType {
    case accelerometer
    case gyroscope
}

struct AccelerometerView: View {
    @StateObject private var motionManager = MotionManager()

    var body: some View {
        VStack {
            Text("Accelerometer")
                .font(.headline)

            GraphView(title: "X-Axis", values: motionManager.accelerometerData.map { $0.x })
            GraphView(title: "Y-Axis", values: motionManager.accelerometerData.map { $0.y })
            GraphView(title: "Z-Axis", values: motionManager.accelerometerData.map { $0.z })
            GraphView(title: "Magnitude", values: motionManager.accelerometerData.compactMap { $0.magnitude })
        }
        .onAppear {
            motionManager.startAccelerometerUpdates()
        }
        .onDisappear {
            motionManager.stopAccelerometerUpdates()
        }
    }
}
