//
//  MainView.swift
//  SpeedSense
//
//  Created by Abdullah Malik on 11/30/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Accelerometer", destination: AccelerometerView())
                NavigationLink("Gyroscope", destination: GyroscopeView())
                NavigationLink("Record Data", destination: RecordDataView())
            }
            .navigationTitle("SpeedSense")
        }
    }
}
