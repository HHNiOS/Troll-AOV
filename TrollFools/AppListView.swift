//
//  AppListView.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//  UI Upgraded 🚀 (Full Bleed Background)
//

import CocoaLumberjackSwift
import OrderedCollections
import SwiftUI
import UIKit
import SwiftUIIntrospect

typealias Scope = AppListModel.Scope

struct AppListView: View {
    let isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad

    @EnvironmentObject var appList: AppListModel
    @Environment(\.verticalSizeClass) var verticalSizeClass

    @State var selectorOpenedURL: URLIdentifiable? = nil
    @State var isWarningPresented = false
    @State var temporaryOpenedURL: URLIdentifiable? = nil

    @AppStorage("isAdvertisementHiddenV2")
    var isAdvertisementHidden: Bool = false

    @AppStorage("isWarningHidden")
    var isWarningHidden: Bool = false

    var shouldShowAdvertisement: Bool {
        !isAdvertisementHidden &&
            !appList.filter.isSearching &&
            !appList.filter.showPatchedOnly &&
            !appList.isRebuildNeeded &&
            !appList.isSelectorMode
    }

    var body: some View {
        ZStack {
            Image("anime_bg")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(0.4)
            
            if #available(iOS 15, *) {
                content
                    .alert(
                        NSLocalizedString("Notice", comment: ""),
                        isPresented: $isWarningPresented,
                        presenting: temporaryOpenedURL
                    ) { result in
                        Button { selectorOpenedURL = result } label: { Text(NSLocalizedString("Continue", comment: "")) }
                        Button(role: .destructive) {
                            selectorOpenedURL = result
                            isWarningHidden = true
                        } label: { Text(NSLocalizedString("Continue and Don’t Show Again", comment: "")) }
                        Button(role: .cancel) {
                            temporaryOpenedURL = nil
                            isWarningPresented = false
                        } label: { Text(NSLocalizedString("Cancel", comment: "")) }
                    } message: { result in
                        Text(localWarningMessage([result.url]))
                    }
            } else {
                content
            }
        }
    }

    var content: some View {
        styledNavigationView
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appList.activeScopeApps.keys)
            // Đã xoá đoạn .sheet và .onOpenURL ở đây cho mượt!
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
                UITableView.appearance().separatorStyle = .none
                UICollectionView.appearance().backgroundColor = .clear
                
                if Double.random(in: 0 ..< 1) < 0.1 { isAdvertisementHidden = false }
            }
    }

    @ViewBuilder
    var styledNavigationView: some View {
        if isPad {
            navigationView.navigationViewStyle(.automatic)
        } else {
            navigationView.navigationViewStyle(.stack)
        }
    }

    var navigationView: some View {
        NavigationView {
            refreshableListView
            if !appList.isSelectorMode { PlaceholderView() }
        }
    }

    @ViewBuilder
    var refreshableListView: some View {
        if #available(iOS 15, *) {
            listView
                .refreshable { appList.reload() }
                .introspect(.viewController, on: .iOS(.v15, .v16, .v17, .v18)) { viewController in
                    viewController.navigationItem.searchController = nil
                    viewController.navigationController?.navigationBar.prefersLargeTitles = true
                    viewController.navigationItem.largeTitleDisplayMode = .always
                    viewController.view.backgroundColor = .clear
                    viewController.navigationController?.view.backgroundColor = .clear
                }
        } else {
            listView
                .introspect(.list, on: .iOS(.v14)) { tableView in
                    tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))
                    if tableView.refreshControl == nil {
                        tableView.refreshControl = {
                            let refreshControl = UIRefreshControl()
                            refreshControl.addAction(UIAction { action in
                                appList.reload()
                                if let control = action.sender as? UIRefreshControl { control.endRefreshing() }
                            }, for: .valueChanged)
                            return refreshControl
                        }()
                    }
                }
                .introspect(.viewController, on: .iOS(.v14)) { viewController in
                    viewController.navigationItem.searchController = nil
                    viewController.navigationController?.navigationBar.prefersLargeTitles = true
                    viewController.navigationItem.largeTitleDisplayMode = .always
                    viewController.view.backgroundColor = .clear
                }
        }
    }

    var listView: some View {
        List {
            topSection
            mainContentSection
            appSections
            
            if !appList.isSelectorMode && !appList.filter.isSearching {
                footer
                    .listRowBackground(Color.clear)
                    .hideListRowSeparator()
            }
        }
        .if_iOS16_ClearBackground()
        .animation(.spring(), value: appList.activeScopeApps.count)
        .animation(.spring(), value: appList.isRebuildNeeded)
        .listStyle(.plain)
        .navigationTitle(appList.isSelectorMode ? NSLocalizedString("Select Application", comment: "") : NSLocalizedString("Nakoto Panel", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if appList.isSelectorMode, let selectorURL = appList.selectorURL {
                    VStack(spacing: 4) {
                        Text(selectorURL.lastPathComponent).font(.subheadline).fontWeight(.bold)
                        Text(NSLocalizedString("Select Application to Inject", comment: "")).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var mainContentSection: some View {
        if #available(iOS 15, *) {
            if appList.activeScope == .all && shouldShowAdvertisement { advertisementSection }
        }
    }

    @ViewBuilder
    var topSection: some View {
        if AppListModel.hasTrollStore && appList.isRebuildNeeded {
            rebuildButton
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.85))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .hideListRowSeparator()
                .transition(.scale.combined(with: .opacity))
        }

        if !appList.filter.isSearching && !appList.filter.showPatchedOnly && !appList.isRebuildNeeded {
            if appList.activeScope == .system {
                Text(NSLocalizedString("Only removable system applications are eligible and listed.", comment: ""))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .hideListRowSeparator()
                    .transition(.opacity)
            } else if appList.activeScope != .troll && appList.unsupportedCount > 0 {
                Text(String(format: NSLocalizedString("And %d more unsupported user applications.", comment: ""), appList.unsupportedCount))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .hideListRowSeparator()
                    .transition(.opacity)
            }
        }
    }

    var rebuildButton: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            appList.rebuildIconCache()
        } label: {
            HStack(spacing: 16) {
                if #available(iOS 15.0, *) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.blue)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Rebuild Icon Cache", comment: "")).font(.headline).fontWeight(.bold).foregroundColor(.primary)
                    Text(NSLocalizedString("Rebuild cache in TrollStore to apply changes.", comment: "")).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill").font(.title3).foregroundColor(Color(UIColor.tertiaryLabel))
            }
        }
    }

    var appSections: some View {
        ForEach(Array(appList.activeScopeApps.keys), id: \.self) { sectionKey in
            ForEach(appList.activeScopeApps[sectionKey] ?? [], id: \.bid) { app in
                NavigationLink {
                    if appList.isSelectorMode, let selectorURL = appList.selectorURL {
                        InjectView(app, urlList: [selectorURL])
                    } else {
                        OptionView(app)
                    }
                } label: {
                    AppListCell(app: app)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 12, leading: 32, bottom: 12, trailing: 32))
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.85))
                        .padding(.horizontal, 16) 
                        .padding(.vertical, 4)    
                )
                .hideListRowSeparator()
            }
        }
    }

    @available(iOS 15.0, *)
    var advertisementSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(NSLocalizedString("BUY KEY & SUPPORT", comment: ""))
                .textCase(.uppercase)
                .font(.footnote.weight(.bold))
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            
            Button {
                UIApplication.shared.open(App.advertisementApp.url)
            } label: {
                HStack(spacing: 12) {
                    AppListCell(app: App.advertisementApp)
                        .padding(.vertical, 4)
                    Spacer()
                    Image(systemName: "cart.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                        .overlay(
                            LinearGradient(colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(NSLocalizedString("Buy keys through my Mini App bot!!", comment: ""))
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .hideListRowSeparator()
    }

    var footer: some View { EmptyView() }

    private func localWarningMessage(_ urls: [URL]) -> String {
        guard let firstDebName = urls.first(where: { $0.pathExtension.lowercased() == "deb" })?.lastPathComponent else { return "" }
        return String(format: NSLocalizedString("You’ve selected at least one Debian Package “%@”. It will not work as it was in a jailbroken environment.", comment: ""), firstDebName)
    }

    private func preprocessURL(_ url: URL) -> URL {
        let isInbox = url.path.contains("/Documents/Inbox/")
        guard isInbox else { return url }
        let fileNameNoExt = url.deletingPathExtension().lastPathComponent
        let fileNameComps = fileNameNoExt.components(separatedBy: CharacterSet(charactersIn: "._- "))
        guard let lastComp = fileNameComps.last, fileNameComps.count > 1, lastComp.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else { return url }
        let newURL = url.deletingLastPathComponent().appendingPathComponent(String(fileNameNoExt.prefix(fileNameNoExt.count - lastComp.count - 1))).appendingPathExtension(url.pathExtension)
        do {
            try? FileManager.default.removeItem(at: newURL)
            try FileManager.default.copyItem(at: url, to: newURL)
            return newURL
        } catch { return url }
    }
}

extension View {
    @ViewBuilder func if_iOS16_ClearBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }

    @ViewBuilder func hideListRowSeparator() -> some View {
        if #available(iOS 15.0, *) {
            self.listRowSeparator(.hidden)
        } else {
            self
        }
    }
}

struct URLIdentifiable: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
