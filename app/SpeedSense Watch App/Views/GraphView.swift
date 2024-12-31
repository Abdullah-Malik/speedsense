//
//  Untitled.swift
//  SpeedSense
//
//  Created by Abdullah Malik on 11/30/24.
//

import SwiftUI
import Charts

struct GraphView: View {
    let title: String
    let values: [Double] // Values for the selected axis or magnitude

    var body: some View {
        VStack {
            Text(title).font(.caption)
            
            Chart {
                ForEach(values.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Value", values[index])
                    )
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .frame(height: 150)
        }
    }
}
