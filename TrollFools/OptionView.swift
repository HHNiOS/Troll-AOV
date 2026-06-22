//
//  OptionView.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//

import SwiftUI
import Foundation

struct OptionView: View {
    let app: App

    @Environment(\.verticalSizeClass) var verticalSizeClass

    @State var isImporterSelected = false
    @State var isSettingsPresented = false
    @State var importerResult: Result<[URL], any Error>?
    @State var numberOfPlugIns: Int = 0
    
    @State var isDownloading = false
    @State var isEjecting = false 

    @AppStorage var useWeakReference: Bool
    @AppStorage var preferMainExecutable: Bool
    @AppStorage var useFrameworkEnumerationFallback: Bool
    @AppStorage var injectStrategy: InjectorV3.Strategy

    init(_ app: App) {
        self.app = app
        _useWeakReference = AppStorage(wrappedValue: true, "UseWeakReference-\(app.bid)")
        _preferMainExecutable = AppStorage(wrappedValue: false, "PreferMainExecutable-\(app.bid)")
        _useFrameworkEnumerationFallback = AppStorage(wrappedValue: true, "UseFrameworkEnumerationFallback-\(app.bid)")
        _injectStrategy = AppStorage(wrappedValue: .lexicographic, "InjectStrategy-\(app.bid)")
    }

    var body: some View {
        wrappedContent
    }

    var wrappedContent: some View {
        content.toolbar { toolbarContent }
    }

    var content: some View {
        List {
            // SECTION 1: KHỐI THAO TÁC CHÍNH
            Section {
                // NÚT INJECT TỰ ĐỘNG
                Button {
                    if !isDownloading && !isEjecting {
                        downloadAndInject()
                    }
                } label: {
                    HStack(spacing: 12) {
                        OptionCell(option: .attach, detachCount: 0, isLoading: isDownloading)
                        
                        if isDownloading {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isDownloading || isEjecting)
                
                // NÚT GỠ TOÀN BỘ TWEAK
                Button {
                    if !isDownloading && !isEjecting {
                        ejectAllTweaks()
                    }
                } label: {
                    HStack(spacing: 12) {
                        OptionCell(option: .detach, detachCount: numberOfPlugIns, isLoading: isEjecting)
                        
                        Spacer()
                        
                        if isEjecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else if numberOfPlugIns > 0 {
                            Text("\(min(numberOfPlugIns, 99))")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(.systemRed)))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(numberOfPlugIns == 0 || isDownloading || isEjecting)
            } header: {
                Text(NSLocalizedString("Actions", comment: ""))
            }
            
            // SECTION 2: CÀI ĐẶT NHANH
            Section {
                Button {
                    isSettingsPresented = true
                } label: {
                    HStack {
                        Label(NSLocalizedString("Advanced Settings", comment: ""), systemImage: "gearshape")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundColor(Color(.placeholderText))
                    }
                }
            } header: {
                Text(NSLocalizedString("Preferences", comment: ""))
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(app.name)
        .background(Group {
            NavigationLink(isActive: $isImporterSelected) {
                if let result = importerResult {
                    switch result {
                    case let .success(urls):
                        InjectView(app, urlList: urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }))
                    case let .failure(error):
                        FailureView(
                            title: NSLocalizedString("Error", comment: ""),
                            error: error
                        )
                    }
                }
            } label: { }
        })
        .onViewWillAppear { _ in
            recalculatePlugInCount()
        }
        .onAppear {
            recalculatePlugInCount()
        }
        .sheet(isPresented: $isSettingsPresented) {
            if #available(iOS 16, *) {
                SettingsView(app)
                    .presentationDetents([.medium, .large])
            } else {
                SettingsView(app)
            }
        }
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            EmptyView()
        }
    }

    // MARK: - ANTI DEBUGGER (SYSCTL)
    private func isBeingDebugged() -> Bool {
        var mib = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        
        let result = mib.withUnsafeMutableBufferPointer { mibPtr -> Int32 in
            return sysctl(mibPtr.baseAddress, 4, &info, &size, nil, 0)
        }
        
        if result == -1 { return true }
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }

    // MARK: - LOGIC TỰ ĐỘNG TẢI TWEAK (THUẦN BASE64 + ANTI DEBUG)
    private func downloadAndInject() {
        // Bẫy chặn nếu phát hiện có thợ đang gỡ lỗi ngầm
        if isBeingDebugged() {
            return
        }

        let encodedURL = "aHR0cHM6Ly9keWxpYi5zZXJ2ZXJoaG5pb3MuaW8udm4vdHdlYWsvQVdTQ29nbml0by56aXA=" // Lien Quan
        // let encodedURL = "aHR0cHM6Ly9keWxpYi5zZXJ2ZXJoaG5pb3MuaW8udm4vdHdlYWsvcHViZy5keWxpYg==" // PUBG
        // let encodedURL = "aHR0cHM6Ly9keWxpYi5zZXJ2ZXJoaG5pb3MuaW8udm4vdHdlYWsvZnJlZWZpcmUuZHlsaWI=" // FreeFire

        guard let data = Data(base64Encoded: encodedURL),
              let urlString = String(data: data, encoding: .utf8),
              let url = URL(string: urlString) else {
            return
        }

        isDownloading = true

        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            defer {
                DispatchQueue.main.async {
                    isDownloading = false
                }
            }

            if let error = error {
                DispatchQueue.main.async {
                    importerResult = .failure(error)
                    isImporterSelected = true
                }
                return
            }

            guard let localURL = localURL else { return }

            let tempDirectory = FileManager.default.temporaryDirectory
            let destinationURL = tempDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.copyItem(at: localURL, to: destinationURL)

                DispatchQueue.main.async {
                    importerResult = .success([destinationURL])
                    isImporterSelected = true
                }

            } catch {
                DispatchQueue.main.async {
                    importerResult = .failure(error)
                    isImporterSelected = true
                }
            }
        }

        task.resume()
    }

    // MARK: - LOGIC GỠ TOÀN BỘ TWEAK SỬ DỤNG API GỐC CỦA HỆ THỐNG
    private func ejectAllTweaks() {
        do {
            let injector = try InjectorV3(app.url)
            if injector.appID.isEmpty { injector.appID = app.bid }
            if injector.teamID.isEmpty { injector.teamID = app.teamID }
            
            injector.useWeakReference = useWeakReference
            injector.preferMainExecutable = preferMainExecutable
            injector.useFrameworkEnumerationFallback = useFrameworkEnumerationFallback
            injector.injectStrategy = injectStrategy

            isEjecting = true

            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    DispatchQueue.main.async {
                        isEjecting = false
                        app.reload()
                        recalculatePlugInCount()
                    }
                }

                do {
                    try injector.ejectAll(shouldDesist: true)
                } catch {
                    print("Lỗi tháo gỡ tweak hệ thống: \(error)")
                }
            }
        } catch {
            print("Không thể khởi tạo Injector cấu hình: \(error)")
        }
    }

    private func recalculatePlugInCount() {
        var urls = [URL]()
        urls += InjectorV3.main.injectedAssetURLsInBundle(app.url)
        let enabledNames = urls.map { $0.lastPathComponent }
        urls += InjectorV3.main.persistedAssetURLs(bid: app.bid)
            .filter { !enabledNames.contains($0.lastPathComponent) }
        numberOfPlugIns = urls.count
    }
}
