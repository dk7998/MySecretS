//
//  SubController3.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit
import CoreData

/// 패스코드(Passcode) 상세 입력/편집 화면 컨트롤러
/// - 패스코드 입력, 잠금, 복사, 태그, 날짜 등 다양한 상태/입력 UI 제공
/// - ViewModel로 데이터 바인딩 및 상태 관리, 실시간 저장/삭제/초기화 지원
/// - 키보드, 태그 선택 등 다양한 예외/UX 처리 포함
class SubController3: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {

    // MARK: - Properties

    @IBOutlet var lockButtons: [UIButton]!
    @IBOutlet var copyButtons: [UIButton]!
    @IBOutlet var inputFields: [UITextField]!
    @IBOutlet var tagButtons: [UIButton]!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var delBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var tagBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var dateLabel: UILabel!

    private var tagBackView: UIView?
    var isChanged: Bool = false
    let viewModel: SubViewModel3!

    // MARK: - Initialization

    init(viewModel: SubViewModel3) {
        self.viewModel = viewModel
        super.init(nibName: "SubController3", bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotification()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 신규 작성 화면에서 뒤로가면 자동 저장
        if let navi = self.navigationController as? CustomNavigationController, navi.isPopGesture, viewModel.isAddMode {
            viewModel.save()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func setupUI() {
        // 태그 뷰 그림자 등 시각 효과
        tagView.layer.masksToBounds = false
        tagView.layer.shadowOffset = CGSize(width: 0, height: 5)
        tagView.layer.shadowRadius = 5
        tagView.layer.shadowOpacity = 0.5
        tagView.alpha = 0

        // 타이틀/필드 세팅
        titleField.delegate = self
        titleField.placeholder = localString("Title")
        for tf in inputFields {
            tf.delegate = self
        }

        if viewModel.isAddMode {
            titleField.becomeFirstResponder()
            dateLabel.text = viewModel.dateText
            delBtn.isEnabled = false
            plusBtn.isEnabled = false

            // 잠금 버튼 상태 반영
            for (index, btn) in lockButtons.enumerated() {
                btn.isSelected = AppSettings.passcodeLockOptions[index]
                viewModel.updateLock(btn.isSelected, num: index)
                if btn.isSelected, inputFields.indices.contains(index) {
                    inputFields[index].isSecureTextEntry = true
                }
            }
        } else {
            titleField.text = viewModel.titleText
            dateLabel.text = viewModel.dateText

            let passArray = [viewModel.pass1, viewModel.pass2, viewModel.pass3, viewModel.pass4]
            for (index, text) in passArray.enumerated() {
                inputFields[index].text = text
            }
            let selectedArray = [viewModel.passLock1, viewModel.passLock2, viewModel.passLock3, viewModel.passLock4]
            for (index, selected) in selectedArray.enumerated() {
                lockButtons[index].isSelected = selected
                if selected {
                    inputFields[index].isSecureTextEntry = true
                }
            }
            topView.backgroundColor = tagColor(viewModel.tagColorIndex)
        }

        doneBtn.setTitle(localString("Done"), for: .normal)
        let hasTag = viewModel.tagColorIndex != 0
        backBtn.isSelected = hasTag
        tagBtn.isSelected = hasTag
        doneBtn.setTitleColor(hasTag ? .white : rgb(0, 122, 255, 1), for: .normal)
    }

    // MARK: - Notification & App State Handling

    private func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    // 앱 비활성화 시 키보드 내리기
    @objc private func willResignActive(_ notification: Notification) {
        if titleField.isFirstResponder {
            titleField.resignFirstResponder()
        } else {
            for passField in inputFields {
                if passField.isFirstResponder {
                    passField.resignFirstResponder()
                    break
                }
            }
        }
    }
    
    // MARK: - Keyboard Events (Selector Methods)
    @objc private func keyboardWillShow(_ notification: Notification) {
        doneBtn.isHidden = false
        tagBtn.isHidden = true
    }
    @objc private func keyboardWillHide(_ notification: Notification) {
        doneBtn.isHidden = true
        tagBtn.isHidden = false
    }
    
    // MARK: - Selector Methods (TagView/InfoMessage 등)
    @objc func tagViewBackgroundTapped() {
        UIView.animate(withDuration: 0.25) {
            self.tagView.alpha = 0
            self.tagBackView?.alpha = 0
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.tagBackView?.removeFromSuperview()
            self.tagBackView = nil
        }
    }

    func showInfoMessage(_ title: String) {
        var rect: CGRect = topView.frame
        let labelRect = rect
        let height = rect.maxY
        rect.size.height = height
        rect.origin.y = -height
        let infoView = UIView(frame: rect)
        infoView.layer.shadowColor = UIColor.black.cgColor
        infoView.layer.shadowOffset = CGSize(width: 0, height: 2)
        infoView.layer.shadowOpacity = 0.33
        view.addSubview(infoView)

        rect.origin.y = 0
        let imageView = UIImageView(image: imageFrom3x(named:"gradient"))
        imageView.frame = rect
        infoView.addSubview(imageView)

        let label = UILabel(frame: labelRect)
        label.text = title
        label.font = .boldSystemFont(ofSize: 19)
        label.backgroundColor = .clear
        label.textColor = .white
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        infoView.addSubview(label)

        UIView.animate(withDuration: 0.3) {
            infoView.frame = rect
        } completion: { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.removeInfoMessage(infoView)
            }
        }
    }

    func removeInfoMessage(_ infoView: UIView) {
        var rect: CGRect = infoView.frame
        rect.origin.y = -infoView.frame.size.height
        UIView.animate(withDuration: 0.3) {
            infoView.frame = rect
        } completion: { finished in
            infoView.removeFromSuperview()
        }
    }
    // MARK: - IBActions
    /// 태그 선택(레이어) 버튼 탭
    @IBAction func tagButtonTapped(_ sender: UIButton) {
        if tagBackView == nil {
            let v = UIView()
            v.backgroundColor = UIColor(white: 0, alpha: 0.3)
            v.alpha = 0
            let tapGesutreRecognizer = UITapGestureRecognizer(target: self, action: #selector(tagViewBackgroundTapped))
            tapGesutreRecognizer.numberOfTapsRequired = 1
            v.addGestureRecognizer(tapGesutreRecognizer)
            tagBackView = v
        }
        guard let backView = tagBackView else { return }
        view.insertSubview(backView, belowSubview: tagView)
        autolayoutAdd(backView, view)
        UIView.animate(withDuration: 0.25) {
            self.tagView.alpha = 1
            backView.alpha = 1
        }
    }
    /// 삭제 버튼
    @IBAction func deleteButtonTapped() {
        let alert = UIAlertController(title: localString("Are you sure you want to delete?"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localString("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localString("Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.delete()
            self?.cancelAndPop()
        })
        present(alert, animated: true)
    }
    /// 뒤로가기 버튼(화면 닫기)
    @IBAction func backButtonTapped() {
        cancelAndPop()
    }
    /// 신규 추가/초기화 버튼
    @IBAction func addButtonTapped(_ sender: UIButton) {
        resetView()
    }
    /// 완료 버튼(키보드 내리기)
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        if titleField.isFirstResponder {
            titleField.resignFirstResponder()
        } else {
            for passField in inputFields {
                if passField.isFirstResponder {
                    passField.resignFirstResponder()
                    break
                }
            }
        }
    }
    
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        isChanged = true
    }
    /// 텍스트 필드 내용 복사
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        if let index = copyButtons.firstIndex(of: sender),
           inputFields.indices.contains(index) {
            let tmpField = inputFields[index]
            if let text = tmpField.text, isNotBlank(text) {
                UIPasteboard.general.string = text
                showInfoMessage(localString("Copied to Clipboard."))
            }
        }
    }
    /// 입력 필드 보안입력 토글
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        if let index = lockButtons.firstIndex(of: sender),
           inputFields.indices.contains(index) {
            inputFields[index].isSecureTextEntry = sender.isSelected
            viewModel.updateLock(sender.isSelected, num: index)
            if !viewModel.isAddMode {
                viewModel.save()
            }
        }
    }
    
    /// 태그 변경 버튼
    @IBAction func tagChangeButtonTapped(_ sender: UIButton) {
        guard let index = tagButtons.firstIndex(of: sender) else { return }
        viewModel.updateTag(index)
        topView.backgroundColor = tagColor(viewModel.tagColorIndex)
        let hasTag = viewModel.tagColorIndex != 0
        backBtn.isSelected = hasTag
        tagBtn.isSelected = hasTag
        doneBtn.setTitleColor(hasTag ? .white : rgb(0, 122, 255, 1), for: .normal)
        if !viewModel.isAddMode {
            viewModel.save()
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            inputFields.first?.becomeFirstResponder()
        } else if let index = inputFields.firstIndex(of: textField) {
            let nextIndex = index + 1
            if inputFields.indices.contains(nextIndex) {
                inputFields[nextIndex].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
        return false
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        isChanged = true
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        changedContents(textField)
    }
    
    // MARK: - Data Change/Reset
    
    /// 타이틀/패스워드 필드 변경시 ViewModel로 저장 요청
    func changedContents(_ textField: UITextField) {
        guard isChanged else { return }
        let text = textField.text ?? ""
        if textField == titleField {
            viewModel.updateTitle(text)
        } else if let index = inputFields.firstIndex(of: textField) {
            viewModel.updatePasscode(text, num: index)
        }
        dateLabel.text = viewModel.dateText
        delBtn.isEnabled = true
        plusBtn.isEnabled = true
        isChanged = false
        viewModel.save()
    }
    
    /// 뒤로가기(키보드 내리고 pop)
    func cancelAndPop() {
        if titleField.isFirstResponder {
            titleField.resignFirstResponder()
        } else {
            for passField in inputFields {
                if passField.isFirstResponder {
                    passField.resignFirstResponder()
                    break
                }
            }
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
    /// 신규 입력 화면 초기화
    func resetView() {
        viewModel.resetData()
        delBtn.isEnabled = false
        plusBtn.isEnabled = false
        titleField.text = nil
        for passField in inputFields {
            passField.text = nil
        }
        for (index, btn) in lockButtons.enumerated() {
            btn.isSelected = AppSettings.passcodeLockOptions[index]
            viewModel.updateLock(btn.isSelected, num: index)
        }
        dateLabel.text = viewModel.dateText
        titleField.becomeFirstResponder()
        topView.backgroundColor = tagColor(viewModel.tagColorIndex)
        backBtn.isSelected = false
        tagBtn.isSelected = false
        doneBtn.setTitleColor(rgb(0, 122, 255, 1), for: .normal)
    }
}
