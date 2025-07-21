//
//  HelpView.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit

// MARK: - Constants & Enums

struct PasscodeConstants {
    static let width: CGFloat = 40
    static let height: CGFloat = 40
    static let maxLength = 6
}

enum PasscodeMode {
    case add, delete, pass, change
}

// MARK: - Protocol

protocol PasscodeDelegate: AnyObject {
    func passcodeConfirm()
    func showBioUsageAlert()
}

// MARK: - View Class

/// 패스코드 입력을 위한 사용자 정의 UIView입니다.
///
/// - 다양한 모드를 지원합니다: `.add`, `.delete`, `.pass`, `.change`
/// - 패스코드 입력은 6자리 텍스트필드로 구성됩니다.
/// - 시각적 피드백과 생체 인증 권장 메시지를 포함합니다.
///
/// ## 주요 기능
/// - 비밀번호 입력 및 검증 흐름
/// - 비밀번호 변경/삭제/입력 검증
/// - 입력 실패 시 3회 제한 및 시각적 경고 처리
/// - 키보드 노출 시 자동 레이아웃 조정
/// - 닫기 버튼 및 뷰 제거 애니메이션 포함
final class PassCodeView: UIView, UITextFieldDelegate {
    
    // MARK: - Properties
    
    weak var delegate: PasscodeDelegate?
    var bottomConstraint: NSLayoutConstraint?
    
    private var passMode: PasscodeMode
    private var currentPasscode: String?
    private var isVerifying = false
    private var hasConfirmedOldPasscode = false
    private var isInputDelayed = false
    private var failedCount = 0
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let fakeTextField = UITextField(frame: .zero)
    private var passcodeFields: [UITextField] = []
    private let mainView = UIView()
    private let mainSubView = UIView()
    private let closeButton = UIButton()
    
    // MARK: - Initialization
    
    init(mode: PasscodeMode) {
        self.passMode = mode
        super.init(frame: .zero)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
    }
    
    // MARK: - Setup View
    private func setupView() {
        backgroundColor = UIColor(white: 0.95, alpha: 1)

        var titleStr = ""
        switch passMode {
        case .add:
            titleStr = NSLocalizedString("Enter Passcode", comment: "")
        case .change:
            currentPasscode = AppSettings.mainPasscode
            titleStr = NSLocalizedString("Enter your old passcode", comment: "")
        default:
            currentPasscode = AppSettings.mainPasscode
            titleStr = NSLocalizedString("Enter your passcode", comment: "")
        }

        setupMainLayout()
        setupPasscodeFields()
        setupCloseButton()
        setupTitleLabel(with: titleStr)
        setupSummaryLabel()
        setupFakeTextField()
        registerKeyboardNotifications()
        
        // 앱 첫 실행 시 설명 메시지 추가
        if AppSettings.isInitialLaunch == false {
            showInitialPasscodeHint()
        }
    }
    
    // MARK: - Setup Subviews
    
    private func setupMainLayout() {
        let safeArea = self.safeAreaLayoutGuide
        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.backgroundColor = .clear
        addSubview(mainView)
        
        NSLayoutConstraint.activate([
            mainView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            mainView.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor),
            mainView.widthAnchor.constraint(equalToConstant: 320),
            mainView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        mainSubView.translatesAutoresizingMaskIntoConstraints = false
        mainSubView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        mainSubView.layer.cornerRadius = 10
        mainSubView.layer.borderColor = UIColor.white.cgColor
        mainSubView.layer.borderWidth = 4

        mainView.addSubview(mainSubView)

        NSLayoutConstraint.activate([
            mainSubView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 10),
            mainSubView.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 40),
            mainSubView.widthAnchor.constraint(equalToConstant: 300),
            mainSubView.heightAnchor.constraint(equalToConstant: 116)
        ])
    }

    private func setupPasscodeFields() {
        var previousTextField: UITextField? = nil
        for _ in 0..<6 {
            let textField = createPasscodeEntry()
            passcodeFields.append(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            mainSubView.addSubview(textField)
            
            NSLayoutConstraint.activate([
                textField.topAnchor.constraint(equalTo: mainSubView.topAnchor, constant: 56),
                textField.widthAnchor.constraint(equalToConstant: PasscodeConstants.width),
                textField.heightAnchor.constraint(equalToConstant: PasscodeConstants.height),
            ])
            
            if let prev = previousTextField {
                textField.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: 6).isActive = true
            } else {
                textField.leadingAnchor.constraint(equalTo: mainSubView.leadingAnchor, constant: 15).isActive = true
            }
            previousTextField = textField
        }
    }

    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.backgroundColor = .clear
        closeButton.setImage(UIImage(named: "xImg"), for: .normal)
        closeButton.addTarget(self, action: #selector(animateAndRemoveSelf), for: .touchUpInside)
        mainSubView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: mainSubView.trailingAnchor, constant: -4),
            closeButton.topAnchor.constraint(equalTo: mainSubView.topAnchor, constant: 3),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupTitleLabel(with title: String) {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.5
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.backgroundColor = .clear
        mainSubView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: mainSubView.leadingAnchor, constant: 45),
            titleLabel.topAnchor.constraint(equalTo: mainSubView.topAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -5),
            titleLabel.heightAnchor.constraint(equalToConstant: 50)
        ])

    }

    private func setupSummaryLabel() {
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.font = UIFont.boldSystemFont(ofSize: 15)
        summaryLabel.numberOfLines = 0
        summaryLabel.baselineAdjustment = .none
        summaryLabel.textAlignment = .center
        summaryLabel.textColor = .white
        summaryLabel.layer.cornerRadius = 8
        summaryLabel.clipsToBounds = true
        mainSubView.addSubview(summaryLabel)

        NSLayoutConstraint.activate([
            summaryLabel.leadingAnchor.constraint(equalTo: mainSubView.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: mainSubView.trailingAnchor),
            summaryLabel.topAnchor.constraint(equalTo: mainSubView.topAnchor, constant: 124),
            summaryLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    private func setupFakeTextField() {
        fakeTextField.delegate = self
        fakeTextField.alpha = 0
        fakeTextField.keyboardType = .numberPad
        fakeTextField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fakeTextField)
        fakeTextField.becomeFirstResponder()
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func showInitialPasscodeHint() {
        let str = NSLocalizedString("Please set a passcode.\nPasscode settings are required to use this app.", comment: "")
        let help = UILabel()
        help.font = UIFont.italicSystemFont(ofSize: 16)
        help.textColor = .darkGray
        help.text = str
        help.textAlignment = .center
        help.numberOfLines = 0
        help.backgroundColor = .clear
        help.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(help)

        NSLayoutConstraint.activate([
            help.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            help.topAnchor.constraint(equalTo: mainView.topAnchor, constant: -40),
            help.widthAnchor.constraint(equalToConstant: 300),
            help.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if #available(iOS 9.0, *) {
            let item = textField.inputAssistantItem
            item.leadingBarButtonGroups = []
            item.trailingBarButtonGroups = []
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if isInputDelayed { return false }
        if string.count > 0 && Int(string) == nil { return false }
        
        guard let currentText = textField.text as NSString? else { return false }
        let newPasscode = currentText.replacingCharacters(in: range, with: string)
        var index = newPasscode.count
        if string.isEmpty {
            index += 1
        }
        
        if index <= PasscodeConstants.maxLength {
            if index - 1 < passcodeFields.count {
                passcodeFields[index - 1].text = string
            }
            
            if index == PasscodeConstants.maxLength {
                isInputDelayed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                    self?.handlePasscodeInput(passcode: newPasscode)
                }
            }
            return true
        }
        return false
    }
    
    // MARK: - Passcode Logic
    
    private func handlePasscodeInput(passcode: String) {
        isInputDelayed = false
        switch passMode {
        case .add:
            if !isVerifying {
                currentPasscode = passcode
                promptReenterPasscode()
                isVerifying = true
            } else {
                if currentPasscode == passcode {
                    savePasscode()
                    cleanupAndRemove()
                } else {
                    showMismatchError()
                }
            }
        case .delete:
            if currentPasscode == passcode {
                deletePasscode()
                cleanupAndRemove()
            } else {
                handleFailedAttempts()
            }
        case .pass:
            if currentPasscode == passcode {
                cleanupAndRemove()
                delegate?.passcodeConfirm()
            } else {
                handleFailedAttempts()
            }
        case .change:
            if !hasConfirmedOldPasscode {
                if currentPasscode == passcode {
                    hasConfirmedOldPasscode = true
                    changeConfirmed()
                } else {
                    handleFailedAttempts()
                }
            } else {
                if !isVerifying {
                    currentPasscode = passcode
                    promptReenterPasscode()
                    isVerifying = true
                } else {
                    if currentPasscode == passcode {
                        savePasscode()
                        cleanupAndRemove()
                    } else {
                        showMismatchError()
                    }
                }
            }
        }
    }
    
    private func promptReenterPasscode() {
        summaryLabel.text = nil
        summaryLabel.backgroundColor = .clear
        
        if passMode == .change {
            titleLabel.text = NSLocalizedString("Re-enter your new passcode", comment: "")
        } else {
            titleLabel.text = NSLocalizedString("Re-enter your passcode", comment: "")
        }
        
        clearPasscodeFields()
    }
    
    private func changeConfirmed() {
        summaryLabel.text = nil
        summaryLabel.backgroundColor = .clear
        
        titleLabel.text = NSLocalizedString("Enter your new passcode", comment: "")
        currentPasscode = nil
        clearPasscodeFields()
    }
    
    private func clearPasscodeFields() {
        for tf in passcodeFields {
            tf.text = nil
        }
        fakeTextField.text = nil
    }
    
    private func savePasscode() {
        if let pass = currentPasscode {
            AppSettings.mainPasscode = pass
        }
        if AppSettings.isInitialLaunch == false {
            delegate?.showBioUsageAlert()
        }
    }
    
    private func deletePasscode() {
        AppSettings.removeMainPasscode()
    }
    
    // MARK: - Feedback & Animation
    
    private func animateInvalidEntry() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.values = [-10, 10, -10, 10, -5, 5, -3, 3, 0]
        animation.isRemovedOnCompletion = true
        mainView.layer.add(animation, forKey: nil)
    }
    
    private func prepareDenyUI() {
        clearPasscodeFields()
        animateInvalidEntry()
        summaryLabel.backgroundColor = .red
    }
    
    private func showMismatchError() {
        prepareDenyUI()
        summaryLabel.text = NSLocalizedString("Passcodes did not match. Try again.", comment: "")
    }
    
    private func handleFailedAttempts() {
        failedCount += 1
        if failedCount == 3 {
            summaryLabel.text = String(format: NSLocalizedString("%d Passcode Failed Attempts", comment: ""), failedCount)
            animateInvalidEntry()
            perform(#selector(cleanupAndRemove), with: nil, afterDelay: 0.8)
        } else {
            prepareDenyUI()
            if failedCount == 1 {
                summaryLabel.text = NSLocalizedString("1 Passcode Failed Attempt", comment: "")
            } else {
                summaryLabel.text = String(format: NSLocalizedString("%d Passcode Failed Attempts", comment: ""), failedCount)
            }
        }
    }
    
    // MARK: - Keyboard Events (Selector Methods)
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        let keyboardFrame = frameValue.cgRectValue
        let keyboardHeight = keyboardFrame.height
        
        guard keyboardHeight > 100 else { return }
        
        bottomConstraint?.constant = -keyboardHeight
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16),
            animations: { [weak self] in
                self?.superview?.layoutIfNeeded()
            }
        )
    }
    
    @objc private func keyboardDidHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        
        bottomConstraint?.constant = 0
        
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16),
            animations: { [weak self] in
                self?.superview?.layoutIfNeeded()
            }
        )
    }
    
    
    // MARK: - Helpers
    
    private func createPasscodeEntry() -> UITextField {
        let tf = UITextField()
        tf.isUserInteractionEnabled = false
        tf.borderStyle = .none
        tf.textColor = .black
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 28)
        tf.isSecureTextEntry = true
        tf.backgroundColor = .white
        tf.layer.cornerRadius = 5
        tf.clipsToBounds = true
        tf.keyboardType = .numberPad
        return tf
    }
    
    @objc private func animateAndRemoveSelf() {
        fakeTextField.resignFirstResponder()
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { [weak self] _ in
            self?.cleanupAndRemove()
        }
    }

    @objc private func cleanupAndRemove() {
        NotificationCenter.default.removeObserver(self)
        removeFromSuperview()
    }
}
