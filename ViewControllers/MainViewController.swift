//
//  MainViewController.swift
//  MySecretS
//
//  Created by 양동국 on 6/2/25.
//

import UIKit
import CoreData

/// 앱 메인 화면을 담당하는 ViewController.
/// - 각 탭(메모, 이미지, 패스코드) 전환, 잠금화면, 테이블뷰 등 앱 주요 상태 관리
/// - ViewModel/Delegate 패턴 및 MARK 구조로 기능별 분리
class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate, LockDelegate {

    // MARK: - Properties

    @IBOutlet var taps: [UIButton]!
    @IBOutlet weak var newBtn: UIButton!
    @IBOutlet weak var setBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var delBtn: UIButton!
    @IBOutlet weak var delAllBtn: UIButton!

    var viewModel: MainViewModel!
    var lockVC: LockViewController!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNotification()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTableView()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup View

    private func setupView() {
        for (index, bt) in taps.enumerated() {
            bt.isSelected = (index == AppSettings.selectedTapIndex)
        }

        delAllBtn.setTitle(localString("Delete all"), for: .normal)

        let nib = UINib(nibName: "TableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "TableCell")

        updateTitle()
        presentLockViewIfNeeded()
    }
    
    // MARK: - Notification & App State Handling
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBack), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func didBecomeActive(_ notification: Notification) {
        if viewModel.shouldLock() {
            presentLockViewIfNeeded()
        }
    }

    @objc func didEnterBack(_ notification: Notification) {
        viewModel.markBackgroundTime()
    }

    // MARK: - Setup Subviews

    private func presentHelpView() {
        let help = HelpView()
        help.alpha = 0
        view.addSubview(help)
        autolayoutAdd(help, view)
        UIView.animate(withDuration: 0.25) {
            help.alpha = 1
        }
    }

    private func updateTitle() {
        switch AppSettings.selectedTapIndex {
        case 0: titleLabel.text = localString("Memo")
        case 1: titleLabel.text = localString("Image")
        default: titleLabel.text = localString("Passcode")
        }
    }

    private func updateTableView() {
        viewModel.fetch()
        editBtn.isEnabled = !viewModel.fetchedObjects.isEmpty
        tableView.separatorInset = (AppSettings.selectedTapIndex == 1)
            ? UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 0)
            : UIEdgeInsets(top: 0, left: 44, bottom: 0, right: 0)
        tableView.reloadData()
    }

    private func updateDeleteButtonState() {
        if let selectedRows = tableView.indexPathsForSelectedRows, selectedRows.count > 0 {
            delBtn.isEnabled = true
        } else {
            delBtn.isEnabled = false
        }
    }

    // MARK: - Lock View Setup

    /// 잠금(락) 화면을 동적으로 추가하여 앱 접근을 차단하는 함수입니다.
    /// - 이미 락뷰가 활성화되어 있으면 중복 추가하지 않음
    /// - LockViewController를 자식 뷰 컨트롤러로 등록 및 오토레이아웃 적용
    func presentLockViewIfNeeded() {
        guard lockVC == nil else { return }

        let lockVC = LockViewController()
        lockVC.delegate = self
        self.lockVC = lockVC

        addChild(lockVC)
        view.addSubview(lockVC.view)
        autolayoutAdd(lockVC.view, view)
        lockVC.didMove(toParent: self)
        lockVC.configureView()
    }

    /// 락(잠금) 화면을 정상적으로 해제 및 뷰 계층에서 제거합니다.
    /// - LockViewController의 라이프사이클을 올바르게 관리하여 메모리 누수/이벤트 충돌 방지
    func removeLockView() {
        lockVC?.willMove(toParent: nil)
        lockVC?.view.removeFromSuperview()
        lockVC?.removeFromParent()
        lockVC = nil

        if !AppSettings.didShowHelp {
            presentHelpView()
        }
    }

    // MARK: - IBActions

    @IBAction func editButtonTapped(_ sender: UIButton) {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            editView.isHidden = false
            newBtn.isEnabled = false
            editBtn.setTitle(localString("Done"), for: .normal)
            editBtn.setImage(nil, for: .normal)
        } else {
            delBtn.isEnabled = false
            editView.isHidden = true
            newBtn.isEnabled = true
            editBtn.setTitle(nil, for: .normal)
            editBtn.setImage(imageFrom3x(named:"edit"), for: .normal)
        }
    }

    @IBAction func deleteAllTapped(_ sender: Any) {
        let str2 = localString("Are you sure you want to delete?")
        let alert = UIAlertController(title: str2, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: localString("Cancel"), style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: localString("Delete"), style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            viewModel.deleteAll()
            self.tableView.reloadData()
            editButtonTapped(UIButton()) // obj-c는 nil 처리 했지만 액션 nil오류나서
        }
        alert.addAction(cancelAction)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func addButtonTapped(_ sender: UIButton) {
        if AppSettings.selectedTapIndex == 0 {
            let subViewModel = SubViewModel(context: viewModel.context, isAddMode: true)
            let subVC = SubController(viewModel: subViewModel)
            navigationController?.pushViewController(subVC, animated: true)
        } else if AppSettings.selectedTapIndex == 1 {
            let subViewModel = SubViewModel2(context: viewModel.context, isAddMode: true)
            let subVC = SubController2(viewModel: subViewModel)
            navigationController?.pushViewController(subVC, animated: true)
        } else {
            let subViewModel = SubViewModel3(context: viewModel.context, isAddMode: true)
            let subVC = SubController3(viewModel: subViewModel)
            navigationController?.pushViewController(subVC, animated: true)
        }
    }

    @IBAction func tabButtonTapped(_ sender: UIButton) {
        guard let index = taps.firstIndex(of: sender), AppSettings.selectedTapIndex != index else { return }
        AppSettings.selectedTapIndex = index
        for (i, bt) in taps.enumerated() {
            bt.isSelected = (i == index)
        }
        updateTitle()
        updateTableView()
    }

    @IBAction func deleteSelectedTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: localString("Are you sure you want to delete?"),
            message: nil,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: localString("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localString("Delete"), style: .destructive) { [weak self] _ in
            guard let self, let selected = tableView.indexPathsForSelectedRows else { return }
            viewModel.deleteItems(selected)
            self.tableView.reloadData()
            self.delBtn.isEnabled = false
        })
        present(alert, animated: true)
    }

    @IBAction func settingTapped(_ sender: UIButton) {
        let setCon = SetController()
        navigationController?.pushViewController(setCon, animated: true)
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.fetchedObjects.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath) as! TableCell
        let item = viewModel.fetchedObjects[indexPath.row]
        cell.configure(with: item, check: AppSettings.selectedTapIndex)
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteAtIndex(indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if tableView.isEditing {
            return .delete
        }
        return .none
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateDeleteButtonState()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateDeleteButtonState()
        } else {
            if AppSettings.selectedTapIndex == 0 {
                let subViewModel = SubViewModel(context: viewModel.context, isAddMode: false)
                let info = viewModel.fetchedObjects[indexPath.row] as? Information
                subViewModel.setInfo(info!)
                let subVC = SubController(viewModel: subViewModel)
                navigationController?.pushViewController(subVC, animated: true)
            } else if AppSettings.selectedTapIndex == 1 {
                let subViewModel = SubViewModel2(context: viewModel.context, isAddMode: false)
                if let photoArray = viewModel.fetchedObjects as? [Photos] {
                    subViewModel.setPTSArray(photoArray)
                }
                subViewModel.selectPhoto(at: indexPath.row)
                let subVC = SubController2(viewModel: subViewModel)
                navigationController?.pushViewController(subVC, animated: true)
            } else {
                let subViewModel = SubViewModel3(context: viewModel.context, isAddMode: false)
                let pass = viewModel.fetchedObjects[indexPath.row] as? Passcode
                subViewModel.setPasscode(pass!)
                let subVC = SubController3(viewModel: subViewModel)
                navigationController?.pushViewController(subVC, animated: true)
            }
        }
    }
}
