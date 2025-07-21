//
//  AppDelegate.swift
//  MySecretS
//
//  Created by 양동국 on 6/2/25.
//

import UIKit
import CoreData

/// 앱 생명주기 및 Core Data 스택을 관리하는 AppDelegate 클래스입니다.
/// - iOS 13 이상은 SceneDelegate 사용
/// - iOS 12 이하를 위한 루트 뷰 설정 포함
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    var naviCon : UINavigationController?
    
    // MARK: - UIApplicationDelegate
    
    func applicationWillResignActive(_ application: UIApplication) {
        if #available(iOS 13.0, *) { return }
        PrivacyCoverManager.shared.show()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 13.0, *) { return }
        PrivacyCoverManager.shared.hide()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppSettings.registerDefaultValues()
        if #available(iOS 13.0, *) {
            // iOS 13 이상은 SceneDelegate에서 처리
        } else {
            setupLegacyRootViewController()
        }
        return true
    }
    
    // MARK: - iOS 12 이하용 초기화
    
    /// iOS 12 이하에서 루트 뷰 컨트롤러를 설정
    private func setupLegacyRootViewController() {
        window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController else {
            fatalError("MainViewController 로드 실패")
        }
        let viewModel = MainViewModel(context: persistentContainer.viewContext)
        rootVC.viewModel = viewModel

        let navigation = CustomNavigationController(rootViewController: rootVC)
        navigation.isNavigationBarHidden = true
        window?.rootViewController = navigation
        window?.makeKeyAndVisible()
        
        if let window = window {
            PrivacyCoverManager.shared.setup(in: window)
        }
    }

    // MARK: - UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MySecretS")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

