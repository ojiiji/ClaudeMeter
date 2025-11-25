//
//  UsageLimit.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// A single usage limit (session, weekly, or Sonnet)
struct UsageLimit: Codable, Equatable, Sendable {
    /// Utilization percentage (0-100)
    let utilization: Double

    /// ISO8601 timestamp when limit resets
    let resetAt: Date

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetAt = "reset_at"
    }
}

extension UsageLimit {
    /// Percentage used (0-100+) - alias for utilization
    var percentage: Double {
        utilization
    }

    /// Status level based on percentage
    var status: UsageStatus {
        switch utilization {
        case 0..<50:
            return .safe
        case 50..<80:
            return .warning
        default:
            return .critical
        }
    }

    /// Human-readable reset time
    func resetDescription(in timezone: TimeZone = .current) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: resetAt, relativeTo: Date())
    }

    /// Check if limit has been exceeded
    var isExceeded: Bool {
        utilization >= 100
    }

    /// Check if reset time has passed but usage hasn't reset
    var isResetting: Bool {
        resetAt < Date() && utilization > 0
    }
}
