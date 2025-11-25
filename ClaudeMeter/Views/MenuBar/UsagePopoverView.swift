//
//  UsagePopoverView.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import SwiftUI

/// Usage popover view with detailed metrics
struct UsagePopoverView: View {
    @ObservedObject var viewModel: UsagePopoverViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Claude Usage")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Refresh button
                Button(action: {
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    if viewModel.isRefreshing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isRefreshing)
                .help("Refresh usage data")
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding()

            Divider()

            // Error banner
            if let errorMessage = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        // Retry button for recoverable errors
                        Button("Retry") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .buttonStyle(.bordered)

                        // Update Key button for authentication errors
                        if errorMessage.contains("invalid") || errorMessage.contains("expired") || errorMessage.contains("authentication") {
                            Button("Update Session Key") {
                                NotificationCenter.default.post(name: .openSettings, object: nil)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))

                Divider()
            }

            // Content
            if let usageData = viewModel.usageData {
                ScrollView {
                    VStack(spacing: 16) {
                        // Session usage card
                        UsageCardView(
                            title: "5-Hour Session",
                            usageLimit: usageData.sessionUsage,
                            icon: "gauge.with.dots.needle.67percent",
                            timezone: usageData.timezone
                        )

                        // Weekly usage card
                        UsageCardView(
                            title: "Weekly Usage",
                            usageLimit: usageData.weeklyUsage,
                            icon: "calendar",
                            timezone: usageData.timezone
                        )

                        // Sonnet usage card (conditional rendering)
                        if viewModel.isSonnetUsageShown, let sonnetUsage = usageData.sonnetUsage {
                            UsageCardView(
                                title: "Weekly Sonnet",
                                usageLimit: sonnetUsage,
                                icon: "sparkles",
                                timezone: usageData.timezone
                            )
                        }
                    }
                    .padding()
                }
            } else {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading usage data...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }

            Divider()

            // Footer with settings button
            HStack {
                Button("Settings") {
                    NotificationCenter.default.post(name: .openSettings, object: nil)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
                .accessibilityLabel("Open settings window")

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
                .accessibilityLabel("Quit application")
            }
            .padding()
        }
        .frame(width: 320, height: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Usage Dashboard")
    }
}

// MARK: - Preview

#Preview {
    let container = DIContainer.shared
    let viewModel = UsagePopoverViewModel(
        usageService: container.usageService,
        settingsRepository: container.settingsRepository
    )

    // Mock data for preview
    viewModel.usageData = UsageData(
        sessionUsage: UsageLimit(
            utilization: 35.0,
            resetAt: Date().addingTimeInterval(7200)
        ),
        weeklyUsage: UsageLimit(
            utilization: 75.0,
            resetAt: Date().addingTimeInterval(86400 * 3)
        ),
        sonnetUsage: UsageLimit(
            utilization: 50.0,
            resetAt: Date().addingTimeInterval(86400 * 3)
        ),
        lastUpdated: Date(),
        timezone: .current
    )

    return UsagePopoverView(viewModel: viewModel)
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

