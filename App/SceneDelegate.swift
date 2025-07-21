//
//  SceneDelegate.swift
//  MySecretS
//
//  Created by 양동국 on 6/2/25.
//



import UIKit
import CoreData

/// iOS 13 이상에서 앱의 각 Scene의 생명주기를 관리하는 클래스입니다.
/// - 루트 뷰 컨트롤러 설정
/// - Scene 상태 변화에 따른 Privacy 처리
@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    var naviCon : UINavigationController?

    // MARK: - Scene Setup
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let rootVC = storyboard.instantiateViewController(withIdentifier: "MainViewController") as? MainViewController else {
            fatalError("MainViewController 로드 실패")
        }
        
        let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext ?? NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let viewModel = MainViewModel(context: context)
        rootVC.viewModel = viewModel

        let navigation = CustomNavigationController(rootViewController: rootVC)
        navigation.isNavigationBarHidden = true

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigation
        self.window = window
        window.makeKeyAndVisible()
        
        PrivacyCoverManager.shared.setup(in: window)
    }
    
    // MARK: - Scene State Handling
    
    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        /// 앱이 다시 활성화될 때, 보안 커버뷰 제거
        PrivacyCoverManager.shared.hide()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        /// 앱이 비활성화되기 직전, 보안 커버뷰 표시
        PrivacyCoverManager.shared.show()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    // MARK: - Core Data Support
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

