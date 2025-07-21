//
//  MainViewModel.swift
//  MySecretS
//
//  Created by 양동국 on 7/9/25.
//
import UIKit
import CoreData

/// 앱 메인 화면의 CoreData 리스트 관리 및 잠금 타이머, 삭제 기능을 담당하는 ViewModel.
///
/// - CoreData fetch, 삭제, 배치 삭제, 타임아웃 관리 등 주요 메서드 제공
/// - AppSettings(설정값) 기반 정렬 및 fetchKey 적용
/// - 배경 진입/복귀 시간 기록 및 자동 잠금 판단
class MainViewModel {
    
    // MARK: - Properties
    let context: NSManagedObjectContext
    private var backgroundEnterTime: Date?
    var fetchedObjects: [NSManagedObject] = []
    
    // MARK: - Initializer
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Core Data Fetch
    
    /// 현재 탭(AppSettings.selectedTapIndex)에 해당하는 엔티티에서 리스트 데이터를 fetch한다.
    /// 정렬 옵션(AppSettings.sortOptionIndex)에 따라 정렬 방식 결정.
    func fetch() {
        let entityName: String
        switch AppSettings.selectedTapIndex {
        case 0: entityName = CoreEntityName.information
        case 1: entityName = CoreEntityName.photos
        case 2: entityName = CoreEntityName.passcode
        default: entityName = CoreEntityName.information
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.propertiesToFetch = ["title", "date"]
        
        let sortDescriptor: NSSortDescriptor
        let sortOption = AppSettings.sortOptionIndex
        if sortOption == 0 {
            sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        } else if sortOption == 1 {
            sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        } else {
            sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        }
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.fetchBatchSize = 30
        fetchRequest.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(fetchRequest)
            fetchedObjects = results
        } catch {
            print("Fetch error: \(error)")
            fetchedObjects = []
        }
    }
    
    // MARK: - Core Data Save & Delete
    private func save() {
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Core Data 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 전체 리스트 객체 삭제
    func deleteAll() {
        for item in fetchedObjects {
            self.context.delete(item)
        }
        fetchedObjects.removeAll()
        save()
    }
    
    /// 특정 인덱스의 객체 삭제
    func deleteAtIndex(_ index: Int) {
        context.delete(fetchedObjects[index])
        fetchedObjects.remove(at: index)
        save()
    }
    
    /// 다중 선택 삭제 (IndexPath 배열)
    func deleteItems(_ selected: [IndexPath]) {
        let objectsToDelete = selected.compactMap { indexPath -> NSManagedObject? in
            guard indexPath.row < fetchedObjects.count else { return nil }
            return fetchedObjects[indexPath.row]
        }
        
        for object in objectsToDelete {
            context.delete(object)
        }
        let deleteIDs = Set(objectsToDelete.map { $0.objectID })
        fetchedObjects.removeAll { deleteIDs.contains($0.objectID) }
        save()
    }
    
    // MARK: - Background/Lock 관리
    
    /// 앱이 백그라운드 진입 시 시간 기록
    func markBackgroundTime() {
        backgroundEnterTime = Date()
    }
    
    /// 복귀 시 자동 잠금 여부 판별 (설정값에 따라)
    func shouldLock() -> Bool {
        guard let previous = backgroundEnterTime else { return false }
        let interval = Date().timeIntervalSince(previous)
        if interval > Double(AppSettings.timeOutSeconds()) {
            backgroundEnterTime = nil
            return true
        }
        return false
    }
    
}
