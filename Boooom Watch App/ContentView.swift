//
//  ContentView.swift
//  Boooom Watch App
//
//  Created by 4rNe5 on 11/7/24.
//

import SwiftUI
import CoreMotion

class PunchDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var currentPunchPower: Double = 0
    @Published var maxPunchPower: Double = 0
    @Published var punchScore: Int = 0
    @Published var isMeasuring: Bool = false
    
    // 펀치 감지를 위한 임계값
    private let accelerationThreshold: Double = 2.0
    // 최대 예상 가속도 (점수 계산용)
    private let maxExpectedAcceleration: Double = 40.0
    
    init() {
        queue.maxConcurrentOperationCount = 1
    }
    
    func startMeasuring() {
        reset()
        isMeasuring = true
        setupAccelerometer()
    }
    
    func stopMeasuring() {
        isMeasuring = false
        motionManager.stopAccelerometerUpdates()
        calculateScore()
    }
    
    private func calculateScore() {
        // maxPunchPower를 1000점 만점으로 환산
        let normalizedPower = min(maxPunchPower, maxExpectedAcceleration)
        punchScore = Int((normalizedPower / maxExpectedAcceleration) * 1000)
    }
    
    func setupAccelerometer() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer is not available")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 1.0 / 100.0
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] (data, error) in
            guard let self = self,
                  let data = data,
                  self.isMeasuring else { return }
            
            let acceleration = sqrt(
                pow(data.acceleration.x, 2) +
                pow(data.acceleration.y, 2) +
                pow(data.acceleration.z, 2)
            )
            
            let netAcceleration = abs(acceleration - 1.0)
            
            if netAcceleration > self.accelerationThreshold {
                DispatchQueue.main.async {
                    self.currentPunchPower = netAcceleration
                    if netAcceleration > self.maxPunchPower {
                        self.maxPunchPower = netAcceleration
                    }
                }
            }
        }
    }
    
    func reset() {
        currentPunchPower = 0
        maxPunchPower = 0
        punchScore = 0
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}

struct ContentView: View {
    @StateObject private var punchDetector = PunchDetector()
    
    var body: some View {
        VStack(spacing: 20) {
            if punchDetector.isMeasuring {
                Text("측정 중...")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Text("현재 파워: \(String(format: "%.2f G", punchDetector.currentPunchPower))")
                    .font(.body)
                    .foregroundColor(.blue)
                
                Text("최대 파워: \(String(format: "%.2f G", punchDetector.maxPunchPower))")
                    .font(.body)
                    .foregroundColor(.red)
                
                Button(action: {
                    punchDetector.stopMeasuring()
                }) {
                    Text("측정 종료")
                        .font(.headline)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                if punchDetector.punchScore > 0 {
                    Text("펀치 파워 점수")
                        .font(.headline)
                    Text("\(punchDetector.punchScore)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.blue)
                    Text("/ 1000")
                        .font(.headline)
                    
                    Text("최대 파워: \(String(format: "%.2f G", punchDetector.maxPunchPower))")
                        .font(.body)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    punchDetector.startMeasuring()
                }) {
                    Text("측정 시작")
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
}
