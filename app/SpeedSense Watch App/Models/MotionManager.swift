//
//  SensorDataLogger.swift
//  SpeedSense
//
//  Created by Abdullah Malik on 11/30/24.
//

import CoreMotion

struct SensorDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date // Add a timestamp property
    let x: Double
    let y: Double
    let z: Double
    let magnitude: Double
}

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    private let updateInterval = 0.01

    // Separate published properties for accelerometer and gyroscope data
    @Published var accelerometerData: [SensorDataPoint] = []
    @Published var gyroscopeData: [SensorDataPoint] = []
    @Published var accelerometerRecordedData: [SensorDataPoint] = []
    @Published var gyroscopeRecordedData: [SensorDataPoint] = []
    
    func startRecording() {
        accelerometerRecordedData = [] // Clear previous accelerometer data
        gyroscopeRecordedData = []    // Clear previous gyroscope data
        startDeviceMotionUpdates()
    }

    func stopRecording() {
        motionManager.stopDeviceMotionUpdates()
        print("Recording stopped. Total accelerometer data points: \(accelerometerRecordedData.count)")
        print("Recording stopped. Total gyroscope data points: \(gyroscopeRecordedData.count)")
    }
    
    private func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion = motion else { return }

            // Extract accelerometer and gyroscope data
            let accelerometerData = motion.userAcceleration
            let rotationRate = motion.rotationRate

            // Create separate data points
            let accelerometerDataPoint = SensorDataPoint(
                timestamp: Date(),
                x: accelerometerData.x,
                y: accelerometerData.y,
                z: accelerometerData.z,
                magnitude: sqrt(
                    accelerometerData.x * accelerometerData.x +
                    accelerometerData.y * accelerometerData.y +
                    accelerometerData.z * accelerometerData.z
                )
            )

            let gyroscopeDataPoint = SensorDataPoint(
                timestamp: Date(),
                x: rotationRate.x,
                y: rotationRate.y,
                z: rotationRate.z,
                magnitude: sqrt(
                    rotationRate.x * rotationRate.x +
                    rotationRate.y * rotationRate.y +
                    rotationRate.z * rotationRate.z
                )
            )

            DispatchQueue.main.async {
                // Append data to respective lists
                self?.accelerometerRecordedData.append(accelerometerDataPoint)
                self?.gyroscopeRecordedData.append(gyroscopeDataPoint)
            }
        }
    }

    func startAccelerometerUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available on this device.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            if let accelerometerData = motion?.userAcceleration {
                self?.processAccelerometerData(x: accelerometerData.x, y: accelerometerData.y, z: accelerometerData.z)
            }
        }
    }

    func startGyroscopeUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion is not available on this device.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            if let rotationRate = motion?.rotationRate {
                self?.processGyroscopeData(
                    x: rotationRate.x,
                    y: rotationRate.y,
                    z: rotationRate.z
                )
            }
        }
    }
    
    func stopAccelerometerUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func stopGyroUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }

    private func processAccelerometerData(x: Double, y: Double, z: Double) {
        let magnitude = sqrt(x * x + y * y + z * z)
        let dataPoint = SensorDataPoint(timestamp: Date(), x: x, y: y, z: z, magnitude: magnitude)

        DispatchQueue.main.async {
            self.accelerometerData.append(dataPoint)
            if self.accelerometerData.count > 50 {
                self.accelerometerData.removeFirst()
            }
        }
    }

    private func processGyroscopeData(x: Double, y: Double, z: Double) {
        let magnitude = sqrt(x * x + y * y + z * z)
        let dataPoint = SensorDataPoint(
            timestamp: Date(),
            x: x,
            y: y,
            z: z,
            magnitude: magnitude
        )

        DispatchQueue.main.async {
            self.gyroscopeData.append(dataPoint)

            // Limit to last 50 data points for real-time visualization
            if self.gyroscopeData.count > 50 {
                self.gyroscopeData.removeFirst()
            }

        }
    }
    
    func uploadData(_ data: [SensorDataPoint], to endpoint: String, sensorType: String) {
        guard let url = URL(string: endpoint) else {
            print("Invalid URL for \(sensorType) data.")
            return
        }

        let payload: [String: Any] = [
            "device_id": "watch1234",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "sensor_type": sensorType,
            "data": data.map { dataPoint in
                [
                    "x": dataPoint.x,
                    "y": dataPoint.y,
                    "z": dataPoint.z,
                    "magnitude": dataPoint.magnitude,
                    "timestamp": ISO8601DateFormatter().string(from: dataPoint.timestamp)
                ]
            }
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("Failed to serialize \(sensorType) data to JSON.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("\(sensorType) data upload failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("\(sensorType) data uploaded successfully.")
                } else {
                    print("\(sensorType) data upload failed with response: \(String(describing: response))")
                }
            }
        }.resume()
    }

}
