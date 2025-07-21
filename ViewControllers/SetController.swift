//
//  Untitled.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit
import LocalAuthentication

// MARK: - Section Titles enum

enum SettingSection: Int, CaseIterable {
    case setting, autoLock, unlockMethod, sortOrder, hideThumbnails, defaultStr
    var localizedTitle: String {
        switch self {
        case .setting:return localString("Setting")
        case .autoLock:return localString("Auto Lock")
        case .unlockMethod:return localString("How to unlock")
        case .sortOrder:return localString("List Sort Order")
        case .hideThumbnails:return localString("Hide thumbnails")
        case .defaultStr: return localString("Default")
        }
    }
}

/// 앱의 주요 환경설정(Setting) 화면을 담당하는 UIViewController
/// - 자동 잠금, 정렬, 썸네일 숨김, 인증 방식 등 전반적인 사용자 옵션을 구성/반영
/// - 섹션/옵션별 로컬라이징, 하드코딩 최소화(enum화), 버튼 상태 관리, 인증 환경 등 UI 전반을 관리
/// - AppSettings, LocalAuthentication 연동 및 뷰 구성 중심
class SetController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet var sectionLabels: [UILabel]!
    @IBOutlet var lockTimeBtns: [UIButton]!
    @IBOutlet var sortOptionBtns: [UIButton]!
    @IBOutlet var lockBtns: [UIButton]!
    @IBOutlet weak var imgSegment: UISegmentedControl!
    @IBOutlet weak var passBtn: UIButton!
    @IBOutlet weak var biometryBtn: UIButton!
    @IBOutlet weak var setPassBtn: UIButton!
    @IBOutlet weak var helpBtn: UIButton!

    // MARK: - Initialization
    init() {
        super.init(nibName: "SetController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UI Setup
    private func setupUI() {
        setupPasscodeDefaultLock()
        setupImageSegment()
        setupLockTimeButtons()
        setupSections()
        setupSortOptions()
        setupPasscodeModeButtons()
        setupBiometryUI()
        updateAuthToggleColors()
    }

    private func setupPasscodeDefaultLock() {
        for (index, btn) in lockBtns.enumerated() {
            btn.isSelected = AppSettings.passcodeLockOptions[index]
            btn.addTarget(self, action: #selector(passcodeDefaultLockChange(_:)), for: .touchUpInside)
        }
    }

    private func setupImageSegment() {
        imgSegment.selectedSegmentIndex = !AppSettings.isImageBlurred ? 1 : 0
    }

    private func setupLockTimeButtons() {
        for (index, btn) in lockTimeBtns.enumerated() {
            let sec = AppSettings.timeoutOptions[index]
            let str = localString("sec")
            btn.setTitle("\(sec) \(str)", for: .normal)
            btn.isSelected = (index == AppSettings.timeOutIndex)
            btn.addTarget(self, action: #selector(lockTimeChange(_:)), for: .touchUpInside)
        }
    }

    private func setupSections() {
        for (index, label) in sectionLabels.enumerated() {
            guard let section = SettingSection(rawValue: index) else { continue }
            label.text = section.localizedTitle
        }
    }

    private func setupSortOptions() {
        let titles = ["Date", "Modified", "Title"]
        for (index, btn) in sortOptionBtns.enumerated() {
            guard index < titles.count else { break }
            btn.setTitle(localString(titles[index]), for: .normal)
            btn.isSelected = (index == AppSettings.sortOptionIndex)
            btn.addTarget(self, action: #selector(sortOptionsChange(_:)), for: .touchUpInside)
        }
    }

    private func setupPasscodeModeButtons() {
        setPassBtn.setTitle(localString("Set Passcode"), for: .normal)
        setPassBtn.layer.cornerRadius = 8
        helpBtn.setTitle(localString("Help"), for: .normal)
        helpBtn.layer.cornerRadius = 6
        let isPass = AppSettings.isUsingPassword
        biometryBtn.isSelected = !isPass
        passBtn.isSelected = isPass
        passBtn.setTitle(localString("Use passcode"), for: .normal)
    }

    private func setupBiometryUI() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID {
                biometryBtn.setTitle("Face ID", for: .normal)
            } else if context.biometryType == .touchID {
                biometryBtn.setTitle("Touch ID", for: .normal)
            } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let str = "iPhone \(localString("Passcode"))"
                biometryBtn.setTitle(str, for: .normal)
            } else {
                disableTouchOption()
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let str = "iPhone \(localString("Passcode"))"
            biometryBtn.setTitle(str, for: .normal)
        } else {
            disableTouchOption()
        }
    }

    // MARK: - IBActions
    @IBAction func showHelpView() {
        let help = HelpView()
        help.alpha = 0
        view.addSubview(help)
        autolayoutAdd(help, view)
        UIView.animate(withDuration: 0.25) {
            help.alpha = 1
        }
    }

    @IBAction func back(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    /// 패스코드 변경(또는 최초등록) 뷰 표시
    @IBAction func passcodeChange(_ sender: UIButton) {
        let mode: PasscodeMode = (AppSettings.mainPasscode != nil) ? .change : .add
        let pv = PassCodeView(mode: mode)
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
    
    /// 인증 방식 토글 변경 (패스코드/생체인증 전환)
    @IBAction func authToggleChanged(_ sender: UIButton) {
        let usePassword = (sender == passBtn)
        AppSettings.isUsingPassword = usePassword
        biometryBtn.isSelected = !usePassword
        passBtn.isSelected = usePassword
        updateAuthToggleColors()
        showPasscodeChangeAlert()
    }

    /// 썸네일 이미지 블러/일반 토글
    @IBAction func imgSegmentChanged(_ sender: UISegmentedControl) {
        AppSettings.isImageBlurred = (imgSegment.selectedSegmentIndex == 0)
    }

    // MARK: - Selector Methods
    /// 자동 잠금 시간 옵션 변경
    @objc func lockTimeChange(_ sender: UIButton) {
        guard let index = lockTimeBtns.firstIndex(of: sender) else { return }
        AppSettings.timeOutIndex = index
        for (i, btn) in lockTimeBtns.enumerated() {
            btn.isSelected = (i == index)
        }
    }
    
    /// 패스코드 기본 잠금 옵션 토글
    @objc func passcodeDefaultLockChange(_ sender: UIButton) {
        sender.isSelected.toggle()
        AppSettings.passcodeLockOptions = lockBtns.map { $0.isSelected }
    }
    
    /// MainViewController TableView 정렬 옵션 변경
    @objc func sortOptionsChange(_ sender: UIButton) {
        guard let index = sortOptionBtns.firstIndex(of: sender) else { return }
        AppSettings.sortOptionIndex = index
        for (i, btn) in sortOptionBtns.enumerated() {
            btn.isSelected = (i == index)
        }
    }

    // MARK: - Private Methods
    /// 생체인증 옵션 비활성화 처리
    private func disableTouchOption() {
        biometryBtn.isEnabled = false
        passBtn.isSelected = true
        passBtn.isEnabled = false
        AppSettings.isUsingPassword = true
    }
    
    /// 인증 방식 토글 버튼 색상 상태 갱신
    private func updateAuthToggleColors() {
        let white = UIColor.white
        let orange = rgb(245, 165, 81, 1)
        if biometryBtn.isSelected {
            biometryBtn.backgroundColor = orange
            passBtn.backgroundColor = white
        } else {
            biometryBtn.backgroundColor = white
            passBtn.backgroundColor = orange
        }
    }
    
    /// 인증 방식 변경시 안내 알림
    private func showPasscodeChangeAlert() {
        let message = localString("The unlocking method has been changed.")
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localString("OK"), style: .default))
        self.present(alert, animated: true)
    }
}
