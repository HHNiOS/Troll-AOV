//
//  OptionCell.swift
//  TrollFools
//
//  Created by 82Flex on 2024/10/30.
//

import SwiftUI

struct OptionCell: View {
    let option: Option
    let detachCount: Int
    let isLoading: Bool

    var iconName: String {
        if #available(iOS 16, *) {
            option == .attach ? "syringe.fill" : "trash.fill"
        } else {
            option == .attach ? "arrow.down.circle.fill" : "trash.fill"
        }
    }

    var tintColor: Color {
        option == .attach ? .green : .red
    }

    var body: some View {
        HStack(spacing: 16) {
            // ICON TRÒN NỀN MỜ NATIVE
            ZStack {
                Circle()
                    .fill(tintColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .shadow(color: tintColor.opacity(0.3), radius: 6, x: 0, y: 3)
                
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(tintColor)
            }
            
            // TIÊU ĐỀ CELL
            VStack(alignment: .leading, spacing: 4) {
                Text(option == .attach
                    ? NSLocalizedString("Inject Tweak", comment: "")
                    : NSLocalizedString("Remove Tweak", comment: ""))
                    .font(.headline.weight(.bold))
                    .foregroundColor(.primary)
                
                Text(option == .attach
                    ? (isLoading ? NSLocalizedString("Downloading...", comment: "") : NSLocalizedString("Download and inject dylib", comment: ""))
                    : (isLoading ? NSLocalizedString("Ejecting...", comment: "") : NSLocalizedString("Clean app bundle", comment: "")))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        // SỬA TẠI ĐÂY: Chỉ khóa mờ hiển thị đối với nút gỡ khi không có tweak, nút inject luôn sáng rõ
        .opacity((option == .detach && detachCount == 0) ? 0.4 : 1.0)
        .animation(.easeInOut, value: isLoading)
    }
}
