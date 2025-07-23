//
//  TotalActivityReport.swift
//  ShiftReportExtension
//
//  Created by Eric Qin on 12/07/2025.
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
}

let appGroupID = "group.com.ericqin.shift" // Replace with your actual App Group ID

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity
    let content: (Configuration) -> ReportView = { configuration in
        ReportView(configuration: configuration)
    }

    struct Configuration {
        let appUsage: [String: TimeInterval]
    }

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> Configuration {
        var appUsage: [String: TimeInterval] = [:]
        for await result in data {
            for await segment in result.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        let appName = app.application.localizedDisplayName ?? "Unknown"
                        appUsage[appName, default: 0] += app.totalActivityDuration
                    }
                }
            }
        }
        // Write usage data to app group
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            if let jsonData = try? JSONEncoder().encode(appUsage) {
                sharedDefaults.set(jsonData, forKey: "usageData")
            }
        }
        return Configuration(appUsage: appUsage)
    }
}
