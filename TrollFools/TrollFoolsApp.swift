//
//  TrollFoolsApp.swift
//  TrollFools
//
//  Created by Lessica on 2024/7/19.
//

import SwiftUI
import UserNotifications
import BackgroundTasks

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    func setup() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // Ép hiện notification banner khi đang mở app
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

// AppDelegate để xử lý Background Fetch (Khi app chạy ngầm / vuốt về Home)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.trollaov.fetchAlert", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        fetchNgam { success in
            task.setTaskCompleted(success: success)
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.trollaov.fetchAlert")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
    
    func fetchNgam(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/AWSCognito.json") else {
        // guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/pubg.json") else {
        // guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/freefire.json") else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ServerAlert.self, from: data) else {
                completion(false)
                return
            }
            
            let lastID = UserDefaults.standard.string(forKey: "lastAlertID") ?? ""
            
            if decoded.isShow && decoded.id != lastID {
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
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

@main
struct TrollFoolsApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @AppStorage("isDisclaimerHiddenV2")
    var isDisclaimerHidden: Bool = false
    
    @AppStorage("lastAlertID") var lastAlertID: String = ""
    
    // Khởi tạo Timer: Cứ 10 giây sẽ kích hoạt vòng lặp 1 lần
    // Ông có thể đổi 10 thành 30 hoặc 60 nếu sợ request quá nhiều gây nóng máy
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

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
                            // Fetch lần đầu ngay khi vừa mở app
                            fetchServerAndNotify()
                        }
                        // Lắng nghe Timer để request liên tục khi app đang hoạt động
                        .onReceive(timer) { _ in
                            fetchServerAndNotify()
                        }
                } else {
                    DisclaimerView(isDisclaimerHidden: $isDisclaimerHidden)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isDisclaimerHidden)
        }
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

    // Hàm gọi API check tin mới (Dùng chung cho cả lúc mở app và lúc Timer chạy)
    func fetchServerAndNotify() {
        guard let url = URL(string: "https://dylib.serverhhnios.io.vn/alert/AWSCognito.json") else { return } //AOV
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ServerAlert.self, from: data) else { return }
            
            DispatchQueue.main.async {
                // Kiểm tra ID: Nếu có bài mới (khác ID cũ) thì mới bắn thông báo
                if decoded.isShow && decoded.id != self.lastAlertID {
                    self.sendPushNotification(title: decoded.title, body: decoded.message)
                    // Cập nhật ID mới để chốt vòng lặp, tránh spam
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
        
        // Hiện ngay lập tức
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

struct ServerAlert: Codable {
    let id: String
    let title: String
    let message: String
    let isShow: Bool
}
