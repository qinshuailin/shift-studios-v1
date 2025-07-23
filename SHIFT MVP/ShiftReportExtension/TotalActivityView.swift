//
//  TotalActivityView.swift
//  ShiftReportExtension
//
//  Created by Eric Qin on 12/07/2025.
//

import SwiftUI

struct TotalActivityView: View {
    let appUsage: [String: TimeInterval]
    
    var body: some View {
        List(appUsage.sorted(by: { $0.value > $1.value }), id: \ .key) { app, duration in
            HStack {
                Text(app)
                Spacer()
                Text(formatDuration(duration))
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
