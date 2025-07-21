//
//  SubController2ViewModel.swift
//  MySecretS
//
//  Created by 양동국 on 7/3/25.
//
import UIKit
import CoreData

/// Information(CoreData) 객체의 생성/수정/삭제 등 상세 데이터 상태를 관리하는 ViewModel.
/// - add/edit 모드를 지원하며, 텍스트, 태그, 날짜 등 상태 및 저장 로직을 담당
/// - Core Data context 주입 및 상태 바인딩, 변경 감지 기능 포함
class SubViewModel {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    
    var infoData: Information?
    var currentDate: Date = Date()
    var tagColorIndex: Int = 0
    var titleText: String = ""
    var memoText: String = ""
    var isAddMode: Bool
    /// 현재 날짜를 문자열로 반환 (ex: 2025-07-14)
    var dateText: String {
        return dateString(currentDate)
    }
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, isAddMode: Bool = false) {
        self.context = context
        self.isAddMode = isAddMode
    }
    
    // MARK: - Data Setup
    func setInfo(_ info: Information) {
        infoData = info
        titleText = info.title ?? ""
        memoText = info.memo ?? ""
        tagColorIndex = Int(info.tmpString1 ?? "") ?? 0
        currentDate = info.date ?? Date()
    }
    
    func resetData() {
        tagColorIndex = 0
        titleText = ""
        memoText = ""
        infoData = nil
        currentDate = Date()
        isAddMode = true
    }
    
    
    // MARK: - State Update
    func updateTitle(_ text: String) {
        titleText = text
        currentDate = Date()
    }
    func updateMemo(_ text: String) {
        memoText = text
        currentDate = Date()
    }
    func updateTag(_ num: Int) {
        tagColorIndex = num
    }
      
    func updateIfNeeded(text: String, isTitle: Bool) -> Bool {
        guard isNotBlank(text) else { return false }
        
        if isTitle && text != titleText {
            updateTitle(text)
        } else if !isTitle && text != memoText {
            updateMemo(text)
        }

        save()
        return true
    }
    
    
    // MARK: - Save & Delete
    func save() {
        titleNullCheck()
        if isAddMode {
            createNewInfo()
        }
        else if !updateChanged() {
            return
        }
        
        do {
            if context.hasChanges {
                try context.save()
                if isAddMode {
                    isAddMode = false
                }
            }
        } catch {
            print("Core Data 저장 실패: \(error.localizedDescription)")
        }
    }
    
    func delete() {
        guard let target = infoData else { return }
        context.delete(target)
        do {
            try context.save()
        } catch {
            print("Core Data 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    private func updateChanged() -> Bool {
        guard let info = infoData else { return false }
        var didChange = false
        if info.title != titleText {
            info.title = titleText
            didChange = true
        }
        if info.memo != memoText {
            info.memo = memoText
            didChange = true
        }
        if info.tmpString1 != String(tagColorIndex) {
            info.tmpString1 = String(tagColorIndex)
            didChange = true
        }
        if info.date != currentDate {
            info.date = currentDate
            didChange = true
        }
        return didChange
    }
    
    private func createNewInfo() {
        guard let newInfo = NSEntityDescription.insertNewObject(
            forEntityName: CoreEntityName.information,
            into: context
        ) as? Information else { return }

        newInfo.title = titleText
        newInfo.memo = memoText
        newInfo.tmpString1 = String(tagColorIndex)
        newInfo.date = currentDate
        self.infoData = newInfo
    }
    
    // 타이틀 공란일 경우, 메모 첫 줄에서 자동 추출
    private func titleNullCheck() {
        if !isNotBlank(titleText) {
            let string = memoText
            let firstLine = string.components(separatedBy: .newlines).first ?? ""
            titleText = String(firstLine.prefix(24))
        }
    }
}
