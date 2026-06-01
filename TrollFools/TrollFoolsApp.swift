//
//  TrollFoolsApp.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//

import SwiftUI
import UserNotifications
import BackgroundTasks // Thêm thư viện chạy nền

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    func setup() {
        UNUserNotificationCenter.current().delegate = self
    }
    
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

// Tạo AppDelegate để hứng sự kiện Background Fetch của iOS
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Đăng ký Background Task (ID này phải y hệt lúc tạo trong Xcode)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.trollaov.fetchAlert", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }
    
    // Hàm này sẽ bị gọi ngầm khi iOS đánh thức app
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Đặt lịch cho lần đánh thức tiếp theo (khoảng 2 tiếng sau)
        scheduleAppRefresh()
        
        // Gọi API ngầm
        fetchNgam { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.trollaov.fetchAlert")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60) // Check mỗi 2 tiếng
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func fetchNgam(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/AWSCognito.json") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ServerAlert.self, from: data) else {
                completion(false)
                return
            }
            
            // Lấy ID cũ lưu trong UserDefaults ra so sánh
            let lastID = UserDefaults.standard.string(forKey: "lastAlertID") ?? ""
            
            if decoded.isShow && decoded.id != lastID {
                // Có tin mới -> Bắn Local Notification
                self.sendPush(title: decoded.title, body: decoded.message)
                UserDefaults.standard.set(decoded.id, forKey: "lastAlertID")
                completion(true)
            } else {
                completion(true)
            }
        }.resume()
    }
    
    func sendPush(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil) // Nổ ngay lập tức
        UNUserNotificationCenter.current().add(request)
    }
}

@main
struct TrollFoolsApp: SwiftUI.App {
    // Nhúng AppDelegate vào SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("isDisclaimerHiddenV2")
    var isDisclaimerHidden: Bool = false
    
    @AppStorage("lastAlertID") var lastAlertID: String = ""

    init() {
        try? FileManager.default.removeItem(at: InjectorV3.temporaryRoot)
        NotificationManager.shared.setup()
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
                            // Lần đầu mở app cũng tự check luôn
                            fetchServerAndNotify()
                        }
                } else {
                    DisclaimerView(isDisclaimerHidden: $isDisclaimerHidden)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isDisclaimerHidden)
        }
        // Đặt lịch chạy ngầm khi app lui về nền (Background)
        .onChange(of: UIApplication.shared.applicationState) { state in
            if state == .background {
                appDelegate.scheduleAppRefresh()
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Đã cấp quyền thông báo!")
            }
        }
    }

    // Hàm check lúc đang mở app (Foreground)
    func fetchServerAndNotify() {
        guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/AWSCognito.json") else { return } //AOV
        // guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/pubg.json") else { return } //PUBG
        // guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/freefire.json") else { return } //Free Fire
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ServerAlert.self, from: data) else { return }
            
            DispatchQueue.main.async {
                if decoded.isShow && decoded.id != self.lastAlertID {
                    self.sendPushNotification(title: decoded.title, body: decoded.message)
                    self.lastAlertID = decoded.id 
                }
            }
        }.resume()
    }

    func sendPushNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

struct ServerAlert: Codable {
    let id: String
    let title: String
    let message: String
    let isShow: Bool
}
