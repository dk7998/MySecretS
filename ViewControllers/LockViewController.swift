//
//  LockViewController.swift
//  MySecretS
//
//  Created by 양동국 on 6/2/25.
//

import UIKit
import LocalAuthentication

protocol LockDelegate: AnyObject {
    func removeLockView()
}

/// 앱 잠금 화면을 담당하는 뷰 컨트롤러입니다.
/// - 생체 인증(Face ID / Touch ID / 디바이스 암호) 기반 인증 흐름 처리
class LockViewController: UIViewController, PasscodeDelegate {

    // MARK: - Properties
    weak var delegate: LockDelegate?

    @IBOutlet weak var openBtn: UIButton!
    @IBOutlet weak var message: UILabel!

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    // MARK: - UI Setup
    func configureView() {
        openBtn.setTitle(localString("Tap to Open"), for: .normal)
        message.text = localString("Waiting to Unlock")

        if AppSettings.isUsingPassword {
            addPasscodeView()
        } else {
            tapTouched(nil)
        }
    }

    func addPasscodeView() {
        // 중복 방지
        guard view.subviews.contains(where: { $0 is PassCodeView }) == false else { return }

        let mode: PasscodeMode = AppSettings.mainPasscode != nil ? .pass : .add
        let pv = PassCodeView(mode: mode)
        pv.delegate = self
        pv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pv)

        pv.bottomConstraint = pv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        pv.bottomConstraint?.isActive = true
        NSLayoutConstraint.activate([
            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pv.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    // MARK: - Actions
    @IBAction func tapTouched(_ sender: Any?) {
        if AppSettings.isUsingPassword {
            addPasscodeView()
        } else {
            Task {
                try? await authenticate()
            }
        }
    }

    func passcodeConfirm() {
        delegate?.removeLockView()
    }

    func showBioUsageAlert() {
        let str = localString("You can use Touch ID or Face ID or iPhone Passcode. Would you like to use it?")
        let alertController = UIAlertController(title: str, message: nil, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: localString("NO"), style: .cancel, handler: { _ in
            AppSettings.isInitialLaunch = true
        }))

        alertController.addAction(UIAlertAction(title: localString("YES"), style: .destructive, handler: { [weak self] _ in
            Task {
                try? await self?.authenticate()
                AppSettings.isInitialLaunch = true
                AppSettings.isUsingPassword = false
            }
        }))

        present(alertController, animated: true)
    }

    // MARK: - Authentication
    func authenticate() async throws {
        try await BiometricAuthenticator.authenticate(
            reason: localString("Open My Secret Pocket"),
            fallbackTitle: localString("Enter Passcode"),
            hidesFallback: false
        )
        delegate?.removeLockView()
    }

    // MARK: - Alert
    func presentAlertController(message: String) {
        let title = isFaceIdSupported() ? localString("Face ID") : localString("Touch ID")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: localString("OK"), style: .default))
        present(alertController, animated: true)
    }
}
