//
//  UsageAPIResponse.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// API response for usage data
struct UsageAPIResponse: Codable {
    let fiveHour: UsageLimitResponse
    let sevenDay: UsageLimitResponse
    let sevenDaySonnet: UsageLimitResponse?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDaySonnet = "seven_day_sonnet"
    }
}

/// Individual usage limit response from API
struct UsageLimitResponse: Codable {
    let utilization: Double // Percentage 0-100
    let resetsAt: String? // ISO8601 string, can be null

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

/// Mapping error for API response conversion
enum MappingError: LocalizedError {
    case invalidDateFormat
    case missingCriticalField(field: String)

    var errorDescription: String? {
        switch self {
        case .invalidDateFormat:
            return "Server returned invalid date format"
        case .missingCriticalField(let field):
            return "Server response missing critical field: \(field)"
        }
    }
}

/// Extension to map API response to domain model
extension UsageAPIResponse {
    func toDomain(timezone: TimeZone = .current) throws -> UsageData {
        // Configure ISO8601 formatter with proper options
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Parse reset dates (must be present and valid)
        let sessionResetDate: Date
        let weeklyResetDate: Date

        guard let sessionResetString = fiveHour.resetsAt,
              let parsedDate = iso8601Formatter.date(from: sessionResetString) else {
            throw MappingError.missingCriticalField(field: "fiveHour.resetsAt")
        }
        sessionResetDate = parsedDate

        guard let weeklyResetString = sevenDay.resetsAt,
              let parsedDate = iso8601Formatter.date(from: weeklyResetString) else {
            throw MappingError.missingCriticalField(field: "sevenDay.resetsAt")
        }
        weeklyResetDate = parsedDate

        // Handle optional sonnet usage
        let sonnetLimit: UsageLimit? = sevenDaySonnet.flatMap { sonnet in
            let sonnetResetDate: Date

            if let sonnetResetString = sonnet.resetsAt,
               let parsedDate = iso8601Formatter.date(from: sonnetResetString) {
                sonnetResetDate = parsedDate
            } else {
                // Default to 7 days in the future if no reset date
                sonnetResetDate = Date().addingTimeInterval(7 * 24 * 3600)
            }

            return UsageLimit(
                utilization: sonnet.utilization,
                resetAt: sonnetResetDate
            )
        }

        return UsageData(
            sessionUsage: UsageLimit(
                utilization: fiveHour.utilization,
                resetAt: sessionResetDate
            ),
            weeklyUsage: UsageLimit(
                utilization: sevenDay.utilization,
                resetAt: weeklyResetDate
            ),
            sonnetUsage: sonnetLimit,
            lastUpdated: Date(),
            timezone: timezone
        )
    }
}
