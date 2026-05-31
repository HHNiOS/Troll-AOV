//
//  AppListModel.swift
//  TrollFools
//

import notify
import Combine
import OrderedCollections
import SwiftUI

final class AppListModel: ObservableObject {

    // MARK: - Scope

    enum Scope: Int, CaseIterable {
        case all
        case user
        case troll
        case system

        var localizedShortName: String {
            switch self {
            case .all:
                return NSLocalizedString("All", comment: "")
            case .user:
                return NSLocalizedString("User", comment: "")
            case .troll:
                return NSLocalizedString("TrollStore", comment: "")
            case .system:
                return NSLocalizedString("System", comment: "")
            }
        }

        var localizedName: String {
            switch self {
            case .all:
                return NSLocalizedString("All Applications", comment: "")
            case .user:
                return NSLocalizedString("User Applications", comment: "")
            case .troll:
                return NSLocalizedString("TrollStore Applications", comment: "")
            case .system:
                return NSLocalizedString("Injectable System Applications", comment: "")
            }
        }
    }

    // MARK: - ONLY SHOW THESE APPS

    private static let allowedIdentifiers: Set<String> = [
        // Liên Quân
        "com.garena.game.kgvn"
        // "vn.vng.pubgmobile"
        // "com.dts.freefireth"
    ]

    // MARK: - Properties

    static let isLegacyDevice: Bool = {
        UIScreen.main.fixedCoordinateSpace.bounds.height <= 736.0
    }()

    static let hasTrollStore: Bool = {
        LSApplicationProxy(forIdentifier: "com.opa334.TrollStore") != nil
    }()

    private var _allApplications: [App] = []

    let selectorURL: URL?

    var isSelectorMode: Bool {
        selectorURL != nil
    }

    @Published var filter = FilterOptions()

    @Published var activeScope: Scope = .all

    @Published var activeScopeApps: OrderedDictionary<String, [App]> = [:]

    @Published var unsupportedCount: Int = 0

    @Published var isRebuildNeeded: Bool = false

    lazy var isFilzaInstalled: Bool = {
        if let filzaURL {
            return UIApplication.shared.canOpenURL(filzaURL)
        }
        return false
    }()

    private let filzaURL = URL(string: "filza://view")

    private let applicationChanged = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    private var darwinNotifyToken: Int32 = NOTIFY_TOKEN_INVALID

    // MARK: - Init

    init(selectorURL: URL? = nil) {

        self.selectorURL = selectorURL

        reload()

        Publishers.CombineLatest(
            $filter,
            $activeScope
        )
        .throttle(
            for: 0.5,
            scheduler: DispatchQueue.main,
            latest: true
        )
        .sink { [weak self] _ in
            self?.performFilter()
        }
        .store(in: &cancellables)

        applicationChanged
            .throttle(
                for: 0.5,
                scheduler: DispatchQueue.main,
                latest: true
            )
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)

        notify_register_dispatch(
            "com.apple.LaunchServices.ApplicationsChanged",
            &darwinNotifyToken,
            .main
        ) { [weak self] _ in
            self?.applicationChanged.send()
        }
    }

    deinit {
        if darwinNotifyToken != NOTIFY_TOKEN_INVALID {
            notify_cancel(darwinNotifyToken)
        }
    }

    // MARK: - Reload

    func reload() {

        let allApplications = Self.fetchApplications(&unsupportedCount)

        allApplications.forEach {
            $0.appList = self
        }

        _allApplications = allApplications

        performFilter()
    }

    // MARK: - Filter

    func performFilter() {

        var filteredApplications = _allApplications

        // Search
        if !filter.searchKeyword.isEmpty {

            filteredApplications = filteredApplications.filter {

                $0.name.localizedCaseInsensitiveContains(filter.searchKeyword)
                ||
                $0.bid.localizedCaseInsensitiveContains(filter.searchKeyword)
                ||
                $0.latinName.localizedCaseInsensitiveContains(
                    filter.searchKeyword
                        .components(separatedBy: .whitespaces)
                        .joined()
                )
            }
        }

        // Patched only
        if filter.showPatchedOnly {

            filteredApplications = filteredApplications.filter {
                $0.isInjected || $0.hasPersistedAssets
            }
        }

        // KHÔNG FILTER THEO USER/TROLL/SYSTEM NỮA
        // ĐỂ APP KHÔNG BỊ BIẾN MẤT

        activeScopeApps = Self.groupedAppList(filteredApplications)
    }

    // MARK: - Fetch Apps

    private static func fetchApplications(
        _ unsupportedCount: inout Int
    ) -> [App] {

        let apps: [App] = LSApplicationWorkspace.default()
            .allApplications()
            .compactMap { proxy in

                guard
                    let id = proxy.applicationIdentifier(),
                    let url = proxy.bundleURL(),
                    let teamID = proxy.teamID(),
                    let appType = proxy.applicationType(),
                    let localizedName = proxy.localizedName()
                else {
                    return nil
                }

                // CHỈ HIỆN APP ĐƯỢC SET
                guard allowedIdentifiers.contains(id) else {
                    return nil
                }

                let shortVersionString = proxy.shortVersionString()

                return App(
                    bid: id,
                    name: localizedName,
                    type: appType,
                    teamID: teamID,
                    url: url,
                    version: shortVersionString
                )
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                == .orderedAscending
            }

        unsupportedCount = 0

        return apps
    }
}

// MARK: - Filza

extension AppListModel {

    func openInFilza(_ url: URL) {

        guard let filzaURL else {
            return
        }

        let fileURL: URL

        if #available(iOS 16, *) {

            fileURL = filzaURL.appending(path: url.path)

        } else {

            fileURL = URL(
                string:
                    filzaURL.absoluteString
                    + (
                        url.path.addingPercentEncoding(
                            withAllowedCharacters: .urlPathAllowed
                        ) ?? ""
                    )
            )!
        }

        UIApplication.shared.open(fileURL)
    }

    func rebuildIconCache() {

        DispatchQueue.global(qos: .userInitiated).async {

            LSApplicationWorkspace.default().openApplication(
                withBundleID: "com.opa334.TrollStore"
            )
        }
    }
}

// MARK: - Grouping

extension AppListModel {

    static let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ#"

    private static let allowedCharacterSet = CharacterSet(
        charactersIn: allowedCharacters
    )

    private static func groupedAppList(
        _ apps: [App]
    ) -> OrderedDictionary<String, [App]> {

        var groupedApps = OrderedDictionary<String, [App]>()

        for app in apps {

            var key = app.name
                .trimmingCharacters(in: .controlCharacters)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .applyingTransform(.stripCombiningMarks, reverse: false)?
                .applyingTransform(.toLatin, reverse: false)?
                .applyingTransform(.stripDiacritics, reverse: false)?
                .prefix(1)
                .uppercased() ?? "#"

            if let scalar = UnicodeScalar(key) {

                if !allowedCharacterSet.contains(scalar) {
                    key = "#"
                }

            } else {

                key = "#"
            }

            if groupedApps[key] == nil {
                groupedApps[key] = []
            }

            groupedApps[key]?.append(app)
        }

        groupedApps.sort { app1, app2 in

            if let c1 = app1.key.first,
               let c2 = app2.key.first,
               let idx1 = allowedCharacters.firstIndex(of: c1),
               let idx2 = allowedCharacters.firstIndex(of: c2)
            {
                return idx1 < idx2
            }

            return app1.key < app2.key
        }

        return groupedApps
    }
}
