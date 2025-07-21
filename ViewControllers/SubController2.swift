//
//  SubController2.swift
//  MySecretS
//
//  Created by 양동국 on 6/3/25.
//

import UIKit
import CoreData

/// 사진(Photos) 객체 상세 보기/편집 화면 컨트롤러
/// - 사진 추가/삭제, 이미지 편집(회전/반전), 카메라/앨범/붙여넣기 지원
/// - ViewModel 바인딩, 이미지 피커/콜렉션뷰/툴바/키보드 등 다양한 UI/UX 제어
class SubController2: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    // MARK: - Properties
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cameraViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var retakeBtn: UIButton!
    @IBOutlet weak var delBtn: UIButton!
    @IBOutlet weak var cameraBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var pasteBtn: UIButton!
    @IBOutlet weak var rotateBtn: UIButton!
    @IBOutlet weak var reflectBtn: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var naviBar: UIView!
    @IBOutlet weak var toolBar: UIView!

    private var cameraBackView: UIView?
    var viewModel: SubViewModel2!
    var lastVisibleIndexPath: IndexPath?
    var isChanged: Bool = false
    var statusBarHidden: Bool = false
    let viewBounds: CGRect = UIScreen.main.bounds
    var photoPic: UIImagePickerController?
    var tap: UITapGestureRecognizer?

    // MARK: - Initialization
    init(viewModel: SubViewModel2) {
        self.viewModel = viewModel
        super.init(nibName: "SubController2", bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotification()
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            cameraBtn.isEnabled = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.isAddMode {
            titleField.becomeFirstResponder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarHidden = false
        setNeedsStatusBarAppearanceUpdate()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 붙여넣기 활성화
        let pasteboard: UIPasteboard = .general
        pasteBtn.isEnabled = pasteboard.hasImages

        collectionView.register(ZoomableImageCell.self, forCellWithReuseIdentifier: "ZoomCell")

        // 카메라 뷰 스타일
        cameraView.layer.cornerRadius = 10
        cameraView.layer.masksToBounds = false
        cameraView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cameraView.layer.shadowRadius = 3
        cameraView.layer.shadowOpacity = 0.5

        // 날짜 라벨 스타일
        dateLabel.layer.cornerRadius = 6
        dateLabel.layer.masksToBounds = true

        titleField.delegate = self
        titleField.placeholder = localString("Title")
        titleField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // 신규/수정 분기
        if viewModel.isAddMode {
            delBtn.isEnabled = false
            plusBtn.isEnabled = false
            retakeBtn.isHidden = true
            dateLabel.text = viewModel.dateText
        } else {
            titleField.text = viewModel.titleText
            updatePageScroll()
            dateLabel.text = viewModel.dateText
        }
    }
    
    //MARK: - Notification & App State Handling
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func didBecomeActive(_ notification: Notification) {
        // 붙여넣기 가능 상태 반영
        let pasteBoard = UIPasteboard.general
        pasteBtn.isEnabled = pasteBoard.hasImages
    }

    @objc func willResignActive(_ notification: Notification) {
        // 카메라/키보드 닫기
        if let picker = photoPic, presentationController == picker {
            imagePickerControllerDidCancel(picker)
        }
        if titleField.isFirstResponder {
            titleField.resignFirstResponder()
        }
    }
    
    // MARK: - Camera/Photo View Handling
    /// 백그라운드 터치시 뷰 제거
    @objc func cameraBackgroundTapped() {
        if cameraBackView != nil {
            UIView.animate(withDuration: 0.25) {
                self.cameraView.alpha = 0
                self.cameraBackView?.alpha = 0
            } completion: { [weak self] _ in
                guard let self = self else { return }
                self.cameraBackView?.removeFromSuperview()
                self.cameraBackView = nil
            }
        }
    }
    /// 사진 찍기 버튼
    @IBAction func takePictureButtonTapped(_ sender: UIButton) {
        if titleField.isFirstResponder { titleField.resignFirstResponder() }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true)
        photoPic = picker
    }
    /// 사진 선택 버튼
    @IBAction func photoSelectButtonTapped(_ sender: UIButton) {
        if titleField.isFirstResponder { titleField.resignFirstResponder() }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
        photoPic = picker
    }
    /// 붙여넣기 버튼
    @IBAction func pasteButtonTapped(_ sender: UIButton) {
        if titleField.isFirstResponder { titleField.resignFirstResponder() }
        let pasteboard = UIPasteboard.general
        if pasteboard.hasImages, let image = pasteboard.image {
            viewModel.addImage(image)
            viewModel.save()
            collectionView.reloadData()
            updatePageScroll()
        }
        cameraBackgroundTapped()
    }
    /// Retake 버튼시 카메라 뷰 보이기
    @IBAction func retakeButtonTapped(_ sender: UIButton) {
        // 카메라 뷰 확장, 반전/회전 버튼 노출
        if cameraViewConstraint.constant == 120 {
            cameraViewConstraint.constant = 190
            reflectBtn.isHidden = false
            rotateBtn.isHidden = false
        }
        if cameraBackView == nil {
            let v = UIView()
            v.backgroundColor = UIColor(white: 0, alpha: 0.3)
            v.alpha = 0
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(cameraBackgroundTapped))
            tapGestureRecognizer.numberOfTapsRequired = 1
            v.addGestureRecognizer(tapGestureRecognizer)
            cameraBackView = v
        }
        guard let backView = cameraBackView else { return }
        view.insertSubview(backView, belowSubview: cameraView)
        autolayoutAdd(backView, view)
        UIView.animate(withDuration: 0.25) {
            self.cameraView.alpha = 1
            backView.alpha = 1
        }
    }
    /// 이미지 좌우 반전
    @IBAction func reflectButtonTapped(_ sender: UIButton) {
        
        if let page = currentVisibleCell(),
           let pageImage = page.imageView.image,
           let indexPath = collectionView.indexPathsForVisibleItems.first {
            let reflectedImage = viewModel.reflectChange(pageImage)
            page.setImage(reflectedImage)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.viewModel.updateImage(reflectedImage, at: indexPath.item)
                self.dateLabel.text = self.viewModel.dateText
            }
        }
    }
    /// 이미지 90도씩 회전
    @IBAction func orientationButtonTapped(_ sender: UIButton) {
        if let page = currentVisibleCell(),
           let pageImage = page.imageView.image,
           let indexPath = collectionView.indexPathsForVisibleItems.first {
            let orientationImage = viewModel.orientationChange(pageImage)
            page.setImage(orientationImage)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.viewModel.updateImage(orientationImage, at: indexPath.item)
                self.dateLabel.text = self.viewModel.dateText
            }
        }
    }
    
    // MARK: - IBActions
    
    /// 삭제 버튼
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: localString("Are you sure you want to delete?"), message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localString("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localString("Delete"), style: .destructive) { [weak self] _ in
            self?.viewModel.delete()
            self?.cancelAndPop()
        })
        present(alert, animated: true)
    }
    /// 뒤로가기 버튼(화면 닫기)
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
    /// 신규 추가/초기화 버튼
    @IBAction func addButtonTapped(_ sender: UIButton) {
        // 새 사진 추가/초기화
        retakeBtn.isHidden = true
        let pasteboard = UIPasteboard.general
        pasteBtn.isEnabled = pasteboard.hasImages
        resetView()
    }

    // MARK: - CollectionView/ScrollView Delegate & DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photosArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ZoomCell", for: indexPath) as! ZoomableImageCell
        if let image = viewModel.image(at: indexPath.item) {
            cell.setImage(image)
        } else {
            cell.setImage(UIImage()) // placeholder
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let inset: CGFloat = 32
        return CGSize(width: collectionView.frame.width - inset, height: collectionView.frame.height)
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        viewModel.selectPhoto(at: pageIndex)
        titleField.text = viewModel.titleText
        dateLabel.text = viewModel.dateText
        guard let current = collectionView.indexPathsForVisibleItems.first else { return }
        if let last = lastVisibleIndexPath, last != current,
           let oldCell = collectionView.cellForItem(at: last) as? ZoomableImageCell {
            oldCell.resetZoom()
        }
        lastVisibleIndexPath = current
    }

    // MARK: - Image Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let originalImage = info[.originalImage] as? UIImage else { return }
        viewModel.addImage(originalImage)
        viewModel.save()
        collectionView.reloadData()
        updatePageScroll()
        cameraBackgroundTapped()
        picker.dismiss(animated: true)
        photoPic = nil
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        photoPic = nil
    }

    // MARK: - UITextFieldDelegate
    @objc func textFieldDidChange(_ textField: UITextField) {
        isChanged = true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard isChanged else { return }
        guard let text = titleField.text, text != viewModel.titleText else {
            isChanged = false
            return
        }
        viewModel.updateTitle(text)
        dateLabel.text = viewModel.dateText
        if !viewModel.isImageEmpty {
            viewModel.save()
        }
        isChanged = false
    }

    // MARK: - Dynamic UI (Page/Scroll Handling)
    @objc func toggleNavigationBar() {
        // 네비/툴바 토글 + 배경색 변경
        if naviBar.alpha == 1 {
            statusBarHidden = true
            setNeedsStatusBarAppearanceUpdate()
            collectionView.isScrollEnabled = true
            if titleField.isFirstResponder { titleField.resignFirstResponder() }
            UIView.animate(withDuration: 0.25) {
                self.collectionView.backgroundColor = .black
                self.naviBar.alpha = 0
                self.toolBar.alpha = 0
            }
        } else {
            statusBarHidden = false
            setNeedsStatusBarAppearanceUpdate()
            collectionView.isScrollEnabled = false
            UIView.animate(withDuration: 0.25) {
                self.collectionView.backgroundColor = .clear
                self.naviBar.alpha = 1
                self.toolBar.alpha = 1
            }
        }
    }
    
    func updatePageScroll() {
        // 현재 선택된 사진 페이지/스크롤 적용 및 탭 제스처 등록
        if tap == nil {
            tap = UITapGestureRecognizer(target: self, action: #selector(toggleNavigationBar))
            collectionView.addGestureRecognizer(tap!)
        }
        cameraView.alpha = 0
        retakeBtn.isHidden = false
        if viewModel.imageData != nil {
            delBtn.isEnabled = true
            plusBtn.isEnabled = true
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(item: viewModel.pageIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    func currentVisibleCell() -> ZoomableImageCell? {
        // 현재 보이는 셀(사진) 반환
        if let indexPath = collectionView.indexPathsForVisibleItems.first,
           let cell = collectionView.cellForItem(at: indexPath) as? ZoomableImageCell {
            return cell
        }
        return nil
    }

    // MARK: - Data Change/Reset
    /// 뒤로가기(키보드 내리고 pop)
    func cancelAndPop() {
        if titleField.isFirstResponder { titleField.resignFirstResponder() }
        navigationController?.popToRootViewController(animated: true)
    }
    
    /// 신규 입력 화면 초기화
    func resetView() {
        viewModel.resetData()
        delBtn.isEnabled = false
        plusBtn.isEnabled = false
        if tap != nil {
            collectionView.removeGestureRecognizer(tap!)
            tap = nil
        }
        titleField.text = nil
        cameraView.alpha = 1
        rotateBtn.isHidden = true
        reflectBtn.isHidden = true
        cameraViewConstraint.constant = 120
        dateLabel.text = viewModel.dateText
        collectionView.reloadData()
    }
}
