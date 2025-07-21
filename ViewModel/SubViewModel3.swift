//
//  SubController2ViewModel.swift
//  MySecretS
//
//  Created by 양동국 on 7/3/25.
//
import UIKit
import CoreData

/// Passcode(CoreData) 객체의 생성/수정/삭제 등 상세 데이터 상태를 관리하는 ViewModel.
/// - add/edit 모드를 지원하며, 각 필드, 잠금상태, 태그, 날짜 등 뷰 상태 및 저장 로직을 담당
/// - Core Data context 주입 및 상태 바인딩, 변경 감지 기능 포함
/// - 필드가 소수(4개)이고, 각 필드가 뷰/DB에서 역할이 명확해 배열 대신 명시적 변수 사용
class SubViewModel3 {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    
    var currentPasscode: Passcode?
    var currentDate: Date = Date()
    var tagColorIndex: Int = 0
    var titleText: String = ""
    var isAddMode: Bool
    var dateText: String {
        return dateString(currentDate)
    }
    /// pass1~pass4, passLock1~passLock4는
    /// - 각 필드의 의미가 명확하고, 필드 수가 적어 배열로 관리하지 않고 명시적으로 선언함.
    /// - 가독성 및 유지보수 편의성을 고려한 설계.
    var pass1: String = ""
    var pass2: String = ""
    var pass3: String = ""
    var pass4: String = ""
    var passLock1 = false
    var passLock2 = false
    var passLock3 = false
    var passLock4 = false
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, isAddMode: Bool = false) {
        self.context = context
        self.isAddMode = isAddMode
    }
    
    // MARK: - Data Setup
    func setPasscode(_ passCode: Passcode) {
        currentPasscode = passCode
        titleText = passCode.title ?? ""
        pass1 = passCode.field1 ?? ""
        pass2 = passCode.field2 ?? ""
        pass3 = passCode.field3 ?? ""
        pass4 = passCode.field4 ?? ""
        passLock1 = passCode.lock1
        passLock2 = passCode.lock2
        passLock3 = passCode.lock3
        passLock4 = passCode.lock4
        tagColorIndex = Int(passCode.tmpString1 ?? "") ?? 0
        currentDate = passCode.date ?? Date()
    }
    
    func resetData() {
        currentPasscode = nil
        titleText = ""
        pass1 = ""
        pass2 = ""
        pass3 = ""
        pass4 = ""
        passLock1 = false
        passLock2 = false
        passLock3 = false
        passLock4 = false
        tagColorIndex = 0
        currentDate = Date()
        isAddMode = true
    }
    
    
    // MARK: - State Update
    func hasAnyContent() -> Bool {
        return isNotBlank(titleText) ||
               isNotBlank(pass1) ||
               isNotBlank(pass2) ||
               isNotBlank(pass3) ||
               isNotBlank(pass4)
    }
    
    func updateTitle(_ text: String) {
        titleText = text
        currentDate = Date()
    }
    
    func updatePasscode(_ text: String, num: Int) {
        switch num {
        case 0:
            pass1 = text
        case 1:
            pass2 = text
        case 2:
            pass3 = text
        case 3:
            pass4 = text
        default:
            break
        }
        currentDate = Date()
    }
        
    func updateLock(_ changed:Bool, num:Int) {
        switch num {
        case 0:
            passLock1 = changed
        case 1:
            passLock2 = changed
        case 2:
            passLock3 = changed
        case 3:
            passLock4 = changed
        default:
            break
        }
    }
    
    func updateTag(_ num: Int) {
        tagColorIndex = num
    }

    // MARK: - Save & Delete
    func save() {
        if isAddMode {
            createNewPasscode()
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
        guard let target = currentPasscode else { return }
        context.delete(target)
        do {
            try context.save()
        } catch {
            print("Core Data 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    private func updateChanged() -> Bool {
        guard let passCode = currentPasscode else { return false }
        var didChange = false
        
        // 제목이 비어 있을 경우 dateText를 제목으로 자동 설정
        if !isNotBlank(titleText) {
            titleText = dateText
        }
        
        if passCode.title != titleText {
            passCode.title = titleText
            didChange = true
        }
        if passCode.field1 != pass1 {
            passCode.field1 = pass1
            didChange = true
        }
        if passCode.field2 != pass2 {
            passCode.field2 = pass2
            didChange = true
        }
        if passCode.field3 != pass3 {
            passCode.field3 = pass3
            didChange = true
        }
        if passCode.field4 != pass4 {
            passCode.field4 = pass4
            didChange = true
        }
        if passCode.lock1 != passLock1 {
            passCode.lock1 = passLock1
            didChange = true
        }
        if passCode.lock2 != passLock2 {
            passCode.lock2 = passLock2
            didChange = true
        }
        if passCode.lock3 != passLock3 {
            passCode.lock3 = passLock3
            didChange = true
        }
        if passCode.lock4 != passLock4 {
            passCode.lock4 = passLock4
            didChange = true
        }
        if passCode.tmpString1 != String(tagColorIndex) {
            passCode.tmpString1 = String(tagColorIndex)
            didChange = true
        }
        if passCode.date != currentDate {
            passCode.date = currentDate
            didChange = true
        }
        return didChange
    }
    
    private func createNewPasscode() {
        guard let newPass = NSEntityDescription.insertNewObject(
            forEntityName: CoreEntityName.passcode,
            into: context
        ) as? Passcode else { return }
        newPass.title = isNotBlank(titleText) ? titleText : dateText
        print("xxxx \(titleText) \(newPass.title ?? "")")
        newPass.field1 = pass1
        newPass.field2 = pass2
        newPass.field3 = pass3
        newPass.field4 = pass4
        newPass.lock1 = passLock1
        newPass.lock2 = passLock2
        newPass.lock3 = passLock3
        newPass.lock4 = passLock4
        newPass.tmpString1 = String(tagColorIndex)
        newPass.date = currentDate
        self.currentPasscode = newPass
    }
}
