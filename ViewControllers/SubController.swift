//
//  SubController.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit
import CoreData

/// 메모(Information) 상세 입력/편집 화면 컨트롤러
/// - 제목, 메모, 태그, 날짜 등 입력 및 수정 UI 제공
/// - ViewModel로 데이터 바인딩 및 상태 관리, 실시간 저장/삭제/초기화 지원
/// - 키보드, 태그 선택 등 다양한 예외/UX 처리 포함
class SubController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    // MARK: - Properties (UI & Data)
    @IBOutlet var tagButtons: [UIButton]!    // 태그 선택 버튼 모음
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var tagView: UIView!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var delBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var tagBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIView!
    
    private var tagBackView: UIView!
    var viewModel: SubViewModel!
    var isChanged = false
    var textViewFrame = CGRect()
    
    // MARK: - Initialization
    init(viewModel: SubViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SubController", bundle: nil)
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

        // 텍스트 필드/뷰 세팅
        titleField.delegate = self
        titleField.placeholder = localString("Title")
        titleField.addTarget(self, action: #selector(titleFieldEditingChanged), for: .editingChanged)
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)

        // 신규/수정 모드 분기
        if viewModel.isAddMode {
            dateLabel.text = dateString(viewModel.currentDate)
            titleField.becomeFirstResponder()
            delBtn.isEnabled = false
            plusBtn.isEnabled = false
        } else {
            titleField.text = viewModel.titleText
            dateLabel.text = viewModel.dateText
            textView.text = viewModel.memoText
            topView.backgroundColor = tagColor(viewModel.tagColorIndex)
        }
        doneBtn.setTitle(localString("Done"), for: .normal)
        
        let tagged = (viewModel.tagColorIndex != 0)
        backBtn.isSelected = tagged
        tagBtn.isSelected = tagged
        doneBtn.setTitleColor(tagged ? .white : rgb(0, 122, 255, 1), for: .normal)
    }
    
    // MARK: - Notification & App State Handling
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    // 앱 비활성화 시 키보드 내리기
    @objc private func willResignActive(_ notification: Notification) {
        if titleField.isFirstResponder {
            titleField.resignFirstResponder()
        } else if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }
       
    // MARK: - Keyboard Events (Selector Methods)
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        tagBtn.isHidden = true
        doneBtn.isHidden = false
        guard let userInfo = notification.userInfo,
              let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = view.convert(keyboardFrameValue.cgRectValue, from: nil).height
        let bottomViewHeight = bottomView.frame.height + view.safeAreaInsets.bottom
        textViewBottomConstraint.constant = keyboardHeight - bottomViewHeight
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        tagBtn.isHidden = false
        doneBtn.isHidden = true
        textViewBottomConstraint.constant = 1
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    // MARK: - IBActions
    /// 태그 선택(레이어) 버튼 탭
    @IBAction func tagButtonTapped(_ sender: UIButton) {
        if tagBackView == nil {
            let v = UIView()
            v.backgroundColor = UIColor(white: 0, alpha: 0.3)
            v.alpha = 0
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tagViewBackgroundTapped))
            tapGesture.numberOfTapsRequired = 1
            v.addGestureRecognizer(tapGesture)
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
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        showDeleteAlert(autoDelete: false)
    }
    /// 뒤로가기 버튼(화면 닫기)
    @IBAction func backButtonTapped(_ sender: UIButton) {
        cancelAndPop()
    }
    /// 신규 추가/초기화 버튼
    @IBAction func addButtonTapped(_ sender: UIButton) {
        resetView()
    }
    /// 완료 버튼(키보드 내리기)
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        if titleField.isFirstResponder { titleField.resignFirstResponder() }
        if textView.isFirstResponder { textView.resignFirstResponder() }
    }
    /// 태그 변경 버튼
    @IBAction func tagChangeButtonTapped(_ sender: UIButton) {
        guard let index = tagButtons.firstIndex(of: sender) else { return }
        viewModel.updateTag(index)
        topView.backgroundColor = tagColor(viewModel.tagColorIndex)
        let tagged = (viewModel.tagColorIndex != 0)
        backBtn.isSelected = tagged
        tagBtn.isSelected = tagged
        doneBtn.setTitleColor(tagged ? .white : rgb(0, 122, 255, 1), for: .normal)
        // 제목, 메모 모두 비어있지 않을 때만 저장
        let isTitleBlank = !isNotBlank(titleField.text)
        let isMemoBlank = !isNotBlank(textView.text)
        if isTitleBlank && isMemoBlank { return }
        viewModel.save()
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.textView.becomeFirstResponder()
        return false
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        changedContents(isTitle: true)
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        isChanged = true
        return true
    }
    @objc private func titleFieldEditingChanged(_ textField: UITextField) {
        isChanged = true
    }
    
    // MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        isChanged = true
        if textView.text.hasSuffix("\n") {
            CATransaction.begin()
            CATransaction.setCompletionBlock { [weak self] in
                self?.scrolltoCaretInTextView(textView, animated: false)
            }
            CATransaction.commit()
        } else {
            scrolltoCaretInTextView(textView, animated: false)
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        changedContents(isTitle: false)
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.1) {
            textView.alpha = 0.95
        } completion: { [weak self] _ in
            guard let self = self else { return }
            textView.alpha = 1
            self.scrolltoCaretInTextView(self.textView, animated: true)
        }
    }
    // 커서가 보이도록 스크롤
    func scrolltoCaretInTextView(_ textView: UITextView, animated: Bool) {
        guard let range = textView.selectedTextRange else { return }
        var rect = textView.caretRect(for: range.end)
        rect.size.height += textView.textContainerInset.bottom
        textView.scrollRectToVisible(rect, animated: animated)
    }

    // MARK: - TagView & Alert
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
    
    /// 삭제 확인 알림
    func showDeleteAlert(autoDelete: Bool) {
        let title = localString("Are you sure you want to delete?")
        let message = autoDelete ? localString("The title and content are both empty. This memo will be deleted.") : nil
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localString("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localString("Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.delete()
            self?.cancelAndPop()
        })
        present(alert, animated: true)
    }

    // MARK: - Data Change/Reset
    /// 타이틀/메모 변경시 ViewModel로 저장 요청
    func changedContents(isTitle: Bool) {
        guard isChanged else { return }
        let text = isTitle ? (titleField.text ?? "") : (textView.text ?? "")
        if viewModel.updateIfNeeded(text: text, isTitle: isTitle) {
            dateLabel.text = viewModel.dateText
            delBtn.isEnabled = true
            plusBtn.isEnabled = true
        }
        isChanged = false
    }
    
    /// 뒤로가기(키보드 내리고 pop)
    func cancelAndPop() {
        if titleField.isFirstResponder {
            titleField.resignFirstResponder()
        } else if textView.isFirstResponder {
            textView.resignFirstResponder()
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
    /// 신규 입력 화면 초기화
    func resetView() {
        viewModel.resetData()
        delBtn.isEnabled = false
        plusBtn.isEnabled = false
        titleField.text = nil
        textView.text = nil
        isChanged = false
        dateLabel.text = dateString(viewModel.currentDate)
        titleField.becomeFirstResponder()
        topView.backgroundColor = tagColor(viewModel.tagColorIndex)
        backBtn.isSelected = false
        tagBtn.isSelected = false
        doneBtn.setTitleColor(rgb(0,122,255,1), for: .normal)
    }
}
