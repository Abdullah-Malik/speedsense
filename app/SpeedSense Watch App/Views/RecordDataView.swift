import SwiftUI

struct RecordDataView: View {
    @StateObject private var motionManager = MotionManager()
    @State private var isRecording = false
    @State private var uploadStatus: String = "Idle"

    var body: some View {
        VStack(spacing: 20) {
            Text("Record Sensor Data")
                .font(.headline)

            // Start/Stop Recording Button
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
                isRecording.toggle()
            }) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            // Upload All Data Button
            if !isRecording && (!motionManager.accelerometerRecordedData.isEmpty || !motionManager.gyroscopeRecordedData.isEmpty) {
                Button(action: uploadAllData) {
                    Text("Upload All Data")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            // Status Text
            Text("Upload Status: \(uploadStatus)")
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .padding()
        .navigationTitle("Recording")
    }

    private func startRecording() {
        motionManager.startRecording()
        uploadStatus = "Recording..."
    }

    private func stopRecording() {
        motionManager.stopRecording()
        uploadStatus = "Recording Stopped"
    }

    private func uploadAllData() {
        let endpoint = "https://abdullahmalik.me/data"

        uploadStatus = "Uploading..."

        // Upload accelerometer data
        motionManager.uploadData(motionManager.accelerometerRecordedData, to: endpoint, sensorType: "accelerometer")

        // Upload gyroscope data
        motionManager.uploadData(motionManager.gyroscopeRecordedData, to: endpoint, sensorType: "gyroscope")

        uploadStatus = "Upload Started for Both Sensors"
    }
}
