//
//  AppListView.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//  UI Upgraded 🚀 (Glassmorphism & Perfectly Aligned Layout by HHNiOS)
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
    @State private var isInfoSheetPresented = false

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
                .opacity(0.6)
            
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
        .listStyle(.insetGrouped)
        .navigationTitle(appList.isSelectorMode ? NSLocalizedString("Select Application", comment: "") : NSLocalizedString("Nakoto Panel", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    isInfoSheetPresented = true
                } label: {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .principal) {
                if appList.isSelectorMode, let selectorURL = appList.selectorURL {
                    VStack(spacing: 2) {
                        Text(selectorURL.lastPathComponent).font(.subheadline).fontWeight(.bold)
                        Text(NSLocalizedString("Select Application to Inject", comment: "")).font(.caption2).foregroundColor(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $isInfoSheetPresented) {
            InfoView()
                .applyPresentationDetents()
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
                .padding(.vertical, 12)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .applyGlassMaterial()
                )
                .transition(.scale.combined(with: .opacity))
        }

        if !appList.filter.isSearching && !appList.filter.showPatchedOnly && !appList.isRebuildNeeded {
            if appList.activeScope == .system {
                Text(NSLocalizedString("Only removable system applications are eligible and listed.", comment: ""))
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .hideListRowSeparator()
                    .transition(.opacity)
            } else if appList.activeScope != .troll && appList.unsupportedCount > 0 {
                Text(String(format: NSLocalizedString("And %d more unsupported user applications.", comment: ""), appList.unsupportedCount))
                    .font(.footnote.weight(.medium))
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
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Rebuild Icon Cache", comment: ""))
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text(NSLocalizedString("Rebuild cache in TrollStore to apply changes.", comment: ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary.opacity(0.7))
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
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .applyGlassMaterial()
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
    }

    @available(iOS 15.0, *)
    var advertisementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("⚡ KEY & SUPPORT", comment: ""))
                .textCase(.uppercase)
                .font(.caption.weight(.heavy))
                .foregroundColor(.orange)
                .padding(.leading, 6)
            
            Button {
                UIApplication.shared.open(App.advertisementApp.url)
            } label: {
                HStack(spacing: 12) {
                    AppListCell(app: App.advertisementApp)
                        .padding(.vertical, 4)
                    Spacer()
                    Image(systemName: "cart.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(LinearGradient(colors: [.orange, .red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Circle())
                        .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .applyGlassMaterial()
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(NSLocalizedString("Buy keys through my Mini App bot!!", comment: ""))
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.leading, 6)
        }
        }
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

// MARK: - Modern InfoSheet View
struct InfoView: View {
    let encodedURLs = [
        "aHR0cHM6Ly93ZWFuc2hobi5naXRodWIuaW8="
    ]
    
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    func decodeURL(_ encodedURL: String) -> URL? {
        guard let data = Data(base64Encoded: encodedURL),
              let decodedString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return URL(string: decodedString)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Image("Weans")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                                )
                            
                            Text("HHN iOS")
                                .font(.title2.weight(.heavy))
                                .foregroundColor(.primary)
                            
                            Text("Phiên bản \(appVersion)")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        }
                        .padding(.top, 20)

                        VStack(spacing: 12) {
                            InfoCardButton(title: "Weans (HHNiOS)", subtitle: "Nhà phát triển & Modder", icon: "person.crop.circle.fill", gradient: [.blue, .purple], image: "Weans") {
                                if let decodedURL = decodeURL(encodedURLs[0]) {
                                    UIApplication.shared.open(decodedURL)
                                }
                            }
                            
                            InfoCardButton(title: "TrollFools", subtitle: "Mã nguồn gốc (Github)", icon: "chevron.left.forwardslash.chevron.right", gradient: [.purple, .pink], image: "TrollFools") {
                                if let webURL = URL(string: "https://github.com/Lessica/TrollFools") {
                                    UIApplication.shared.open(webURL)
                                }
                            }
                            
                            InfoCardButton(title: "Cộng đồng Telegram", subtitle: "Tham gia nhóm HHN iOS", icon: "paperplane.fill", gradient: [.blue, .green], image: "Weans") {
                                if let webURL = URL(string: "https://t.me/hhn_ios") {
                                    UIApplication.shared.open(webURL)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle("Thông tin & Liên hệ", displayMode: .inline)
        }
    }
}

struct InfoCardButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let image: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(gradient.first ?? .blue)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Safe Glass Fallback Extension
extension Shape {
    @ViewBuilder func applyGlassMaterial() -> some View {
        if #available(iOS 15.0, *) {
            self.fill(.ultraThinMaterial)
        } else {
            self.fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.85))
        }
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
    
    @ViewBuilder func applyPresentationDetents() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.medium, .large])
        } else {
            self
        }
    }
}

struct URLIdentifiable: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
