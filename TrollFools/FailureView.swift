//
//  FailureView.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//

import SwiftUI

struct FailureView: View {
    let title: String
    let error: Error?

    var logFileURL: URL? {
        (error as? NSError)?.userInfo[NSURLErrorKey] as? URL
    }

    @State private var isSharePresented = false

    var body: some View {
        List {
            // SECTION 1: TRẠNG THÁI THẤT BẠI
            Section {
                VStack(spacing: 16) {
                    Spacer()
                    
                    // ICON ĐỎ NATIVE CHUẨN ĐÉT Apple
                    ZStack {
                        Circle()
                            .fill(Color(.systemRed).opacity(0.12))
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        if let error = error {
                            Text(error.localizedDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        } else {
                            Text(NSLocalizedString("An unknown error occurred.", comment: ""))
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

#Preview {
    FailureView(
        title: "Hello, World!",
        error: nil
    )
}
