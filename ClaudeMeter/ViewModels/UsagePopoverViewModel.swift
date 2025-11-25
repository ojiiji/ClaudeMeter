//
//  UsagePopoverViewModel.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation
import Combine

/// ViewModel for usage popover
@MainActor
final class UsagePopoverViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var usageData: UsageData?
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String?
    @Published var isSonnetUsageShown: Bool = false

    // MARK: - Dependencies

    private let usageService: UsageServiceProtocol
    private let settingsRepository: SettingsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(usageService: UsageServiceProtocol, settingsRepository: SettingsRepositoryProtocol) {
        self.usageService = usageService
        self.settingsRepository = settingsRepository

        // Load initial settings
        Task {
            await loadSettings()
        }

        // Listen for settings changes
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.loadSettings()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    /// Load settings from repository
    private func loadSettings() async {
        let settings = await settingsRepository.load()
        self.isSonnetUsageShown = settings.isSonnetUsageShown
    }

    /// Manual refresh (clears cache and fetches fresh data)
    func refresh() async {
        isRefreshing = true
        errorMessage = nil

        do {
            let data = try await usageService.fetchUsage(forceRefresh: true)
            self.usageData = data
            isRefreshing = false
        } catch {
            errorMessage = error.localizedDescription
            isRefreshing = false
        }
    }
}
