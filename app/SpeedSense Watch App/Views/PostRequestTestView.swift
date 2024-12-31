//
//  PostRequestTestView.swift
//  SpeedSense
//
//  Created by Abdullah Malik on 12/1/24.
//

import SwiftUI

struct PostRequestTestView: View {
    @State private var requestStatus: String = "Idle"
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("POST Request Test")
                .font(.headline)

            // Display the current request status
            Text("Status: \(requestStatus)")
                .foregroundColor(isLoading ? .orange : .green)

            // Button to trigger the POST request
            Button(action: {
                sendPostRequest()
            }) {
                Text(isLoading ? "Sending..." : "Send POST Request")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading) // Disable the button while a request is in progress
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Test POST Request")
    }

    // Function to send a POST request
    private func sendPostRequest() {
        isLoading = true
        requestStatus = "Sending..."

        // Replace with your API endpoint
        guard let url = URL(string: "https://speed.free.beeceptor.com") else {
            requestStatus = "Invalid URL"
            isLoading = false
            return
        }

        // Sample payload
        let payload: [String: Any] = [
            "title": "Sample Post",
            "body": "This is a test post",
            "userId": 1
        ]

        // Serialize payload to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            requestStatus = "Failed to serialize JSON"
            isLoading = false
            return
        }

        // Create POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        // Send the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    requestStatus = "Error: \(error.localizedDescription)"
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    requestStatus = "Request successful!"
                } else {
                    print(response)
                    requestStatus = "Failed with response: \(String(describing: response))"
                }
            }
        }.resume()
    }
}
