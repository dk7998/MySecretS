//
//  Untitled.swift
//  MySecretS
//
//  Created by 양동국 on 7/9/25.
//

import UIKit

/// 앱이 백그라운드로 전환될 때 민감한 정보를 보호하기 위해 LaunchScreen 기반 커버 뷰를 보여주는 싱글톤 매니저입니다.
/// - `setup(in:)`: 앱 시작 시 한 번만 호출하여 커버 뷰를 윈도우에 추가합니다.
/// - `show()`: 커버 뷰를 보여줍니다 (예: 홈 버튼 또는 앱 전환 시).
/// - `hide()`: 커버 뷰를 숨깁니다 (예: 앱 다시 활성화 시).
class PrivacyCoverManager {
    // MARK: - Singleton Instance
    static let shared = PrivacyCoverManager()
    
    // MARK: - Properties
    private var coverView: UIView?

    // MARK: - Initialization
    private init() {}

    // MARK: - Setup
    func setup(in window: UIWindow) {
        guard let cover = Bundle.main.loadNibNamed("Launch", owner: nil, options: nil)?.first as? UIView else {
            return
        }
        cover.frame = window.bounds
        cover.isHidden = true
        window.addSubview(cover)
        coverView = cover
    }

    // MARK: - Public Methods
    func show() {
        coverView?.isHidden = false
    }

    func hide() {
        coverView?.isHidden = true
    }
}
