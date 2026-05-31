//
//  SuccessView.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//

import SwiftUI

struct SuccessView: View {
    let title: String
    let subtitle: String?
    let logFileURL: URL?

    @State private var isSharePresented = false

    var body: some View {
        List {
            // SECTION 1: TRẠNG THÁI HOÀN THÀNH
            Section {
                VStack(spacing: 16) {
                    Spacer()
                    
                    // ICON ICON XANH NATIVE CHUẨN ĐÉT Apple
                    ZStack {
                        Circle()
                            .fill(Color(.systemGreen).opacity(0.12))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        } else {
                            Text(NSLocalizedString("Tweak injected successfully!", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear) // Xoá nền ô này để icon nổi lên đẹp hơn
                .padding(.vertical, 20)
            }
            
            // SECTION 2: FILE LOGS HỆ THỐNG (NẾU CÓ)
            if let logFileURL = logFileURL {
                Section {
                    // NÚT XEM LOGS
                    NavigationLink {
                        LogsView(url: logFileURL)
                    } label: {
                        Label {
                            Text(NSLocalizedString("View Output Logs", comment: ""))
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    // NÚT CHIA SẺ LOGS
                    Button {
                        isSharePresented = true
                    } label: {
                        Label {
                            Text(NSLocalizedString("Share Logs", comment: ""))
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentColor)
                        }
                    }
                } header: {
                    Text(NSLocalizedString("Diagnostics", comment: ""))
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $isSharePresented) {
            if let logFileURL = logFileURL {
                ActivityView(activityItems: [logFileURL])
            }
        }
    }
}

// Lớp cầu nối hiển thị bảng chia sẻ tệp tin mặc định của iOS
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
