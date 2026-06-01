//
//  TrollFoolsApp.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//

import SwiftUI
import UserNotifications // Thêm thư viện quản lý thông báo

// Thêm Class này để "ép" iOS hiện thông báo ngay cả khi đang mở App (Foreground)
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    func setup() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Hàm này bắt buộc hệ thống bung banner xuống dù đang dùng app
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}

@main
struct TrollFoolsApp: SwiftUI.App {

    @AppStorage("isDisclaimerHiddenV2")
    var isDisclaimerHidden: Bool = false
    
    // Biến này để lưu lại ID thông báo, tránh việc mở app lên là bị spam liên tục
    @AppStorage("lastAlertID") var lastAlertID: String = ""

    init() {
        try? FileManager.default.removeItem(at: InjectorV3.temporaryRoot)
        
        // Gọi setup delegate để ép hiện thông báo
        NotificationManager.shared.setup()
        
        // Xin quyền gửi thông báo ngay lúc mới mở app
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isDisclaimerHidden {
                    AppListView()
                        .environmentObject(AppListModel())
                        .transition(.opacity)
                        .onAppear {
                            // Mở app lên là chạy ngầm check API
                            fetchServerAndNotify()
                        }
                } else {
                    DisclaimerView(isDisclaimerHidden: $isDisclaimerHidden)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isDisclaimerHidden)
        }
    }

    // Hàm 1: Xin phép user cho hiện thông báo
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Đã cấp quyền thông báo!")
            }
        }
    }

    // Hàm 2: Gọi API server để lấy data
    func fetchServerAndNotify() {
        guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/AWSCognito.json") else { return } //Liên Quân
        // guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/pubg.json") else { return } //PUBG
        // guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/freefire.json") else { return } //Free Fire
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ServerAlert.self, from: data) else { return }
            
            DispatchQueue.main.async {
                // Check: Nếu server cho phép hiện (isShow) VÀ id thông báo này khác với cái cũ
                if decoded.isShow && decoded.id != self.lastAlertID {
                    self.sendPushNotification(title: decoded.title, body: decoded.message)
                    // Cập nhật lại ID để lần sau mở app không bị báo lại cái này nữa
                    self.lastAlertID = decoded.id 
                }
            }
        }.resume()
    }

    // Hàm 3: Render ra cái thông báo rớt xuống màn hình
    func sendPushNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Hẹn giờ nổ thông báo (sau 1 giây)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

// Cấu trúc Data khớp với file JSON
struct ServerAlert: Codable {
    let id: String
    let title: String
    let message: String
    let isShow: Bool
}
