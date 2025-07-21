//
//  CustomNavigationController.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit

/// 디자인 맞춤형 UI를 위해 시스템 기본 네비게이션 바를 숨기고,
/// 커스텀 백 버튼을 사용하는 상황에서도 interactive pop gesture(스와이프 뒤로가기 제스처)를
/// iOS 12 이하 포함 모든 버전에서 정상적으로 작동시키기 위한 UINavigationController 서브클래스입니다.
/// - 시스템 기본 동작은 네비게이션 바가 없거나 커스텀 백 버튼을 사용할 경우 제스처가 비활성화됩니다.
/// - 이 클래스를 사용하면, 뷰 내부에 디자인 요소에 맞춘 커스텀 백 버튼을 자유롭게 배치하면서도
///   시스템의 '스와이프 뒤로가기 제스처'를 그대로 유지할 수 있습니다.
/// - gestureRecognizer의 delegate를 직접 설정하고, 제스처 실행 여부를 추적하는 구조로 구현되어 있습니다.
/// - 외부에서 UINavigationControllerDelegate를 설정한 경우에도 위임(forwarding)을 통해 모두 호환됩니다.
final class CustomNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    /// 뒤로가기 제스처가 시작되었는지 여부 (viewWillDisappear 등에서 확인용)
    var isPopGesture: Bool = false
    
    /// 현재 push 애니메이션 중인지 여부
    private var isPushingViewController: Bool = false
    
    /// 외부에서 설정한 delegate (내부에서 처리한 뒤 위임)
    private weak var externalDelegate: UINavigationControllerDelegate?

    
    // MARK: - Delegate Override
    
    override var delegate: UINavigationControllerDelegate? {
        get { externalDelegate }
        set {
            if newValue !== self {
                externalDelegate = newValue
            } else {
                externalDelegate = nil
            }
            super.delegate = newValue == nil ? nil : self
        }
    }
    
    
    // MARK: - Lifecycle
    
    deinit {
        delegate = nil
        interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if delegate == nil {
            delegate = self
        }
        
        interactivePopGestureRecognizer?.delegate = self
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        isPushingViewController = true
        super.pushViewController(viewController, animated: animated)
    }
    
    
    // MARK: - UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isPopGesture = false
        isPushingViewController = false
        
        assert(interactivePopGestureRecognizer?.delegate === self,
               "CustomNavigationController의 interactivePopGestureRecognizer.delegate는 변경하지 마세요.")
        
        externalDelegate?.navigationController?(navigationController, didShow: viewController, animated: animated)
    }
    
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === interactivePopGestureRecognizer {
            if !isPopGesture {
                isPopGesture = true
            }
            return viewControllers.count > 1 && !isPushingViewController
        }
        return true
    }
    
    
    // MARK: - Delegate Forwarding
    
    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector) || externalDelegate?.responds(to: aSelector) == true
    }
    
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        if externalDelegate?.responds(to: aSelector) == true {
            return externalDelegate
        }
        return super.forwardingTarget(for: aSelector)
    }
}
