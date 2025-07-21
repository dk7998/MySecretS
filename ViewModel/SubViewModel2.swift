//
//  SubController2ViewModel.swift
//  MySecretS
//
//  Created by 양동국 on 7/3/25.
//
import UIKit
import CoreData

/// Photos(CoreData) 객체의 생성/수정/삭제, 이미지 편집(반전/회전) 등 상세 상태를 관리하는 ViewModel.
/// - add/edit 모드 지원, 사진/제목/날짜 등 상태 및 저장/삭제 로직을 담당
/// - 이미지 NSCache로 메모리 최적화, Core Data context 주입 및 상태 바인딩, 변경 감지 기능 포함
class SubViewModel2 {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let imageCache = NSCache<NSNumber, UIImage>()

    var imageData: Data?
    var currentDate: Date = Date()
    var photosArray: [Photos] = []
    var currentPhoto: Photos?
    var titleText: String = ""
    var isAddMode: Bool
    
    // MARK: - Computed Properties
    var dateText: String {
        return dateString(currentDate)
    }
    
    var pageIndex: Int {
        guard let pts = currentPhoto else { return 0 }
        return photosArray.firstIndex(of: pts) ?? 0
    }
    
    var isImageEmpty: Bool {
        return imageData == nil
    }
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext, isAddMode: Bool = false) {
        self.context = context
        self.isAddMode = isAddMode
    }
    
    // MARK: - Data Setup
    func setPTSArray(_ array: [Photos]) {
        photosArray = array
        imageCache.removeAllObjects()
    }
    func resetData() {
        imageCache.removeAllObjects()
        photosArray.removeAll()
        imageData = nil
        titleText = ""
        currentPhoto = nil
        currentDate = Date()
        isAddMode = true
    }
    
    // MARK: - Data Access
    func image(at index: Int) -> UIImage? {
        if let cached = imageCache.object(forKey: NSNumber(value: index)) {
            return cached
        } else if let data = photosArray[safe: index]?.image,
                  let image = UIImage(data: data) {
            imageCache.setObject(image, forKey: NSNumber(value: index))
            return image
        }
        return nil
    }
    
    func selectPhoto(at index: Int) {
        guard index >= 0 && index < photosArray.count else { return }
        let selected = photosArray[index]
        currentPhoto = selected
        titleText = selected.title ?? ""
        imageData = selected.image
        currentDate = selected.date ?? Date()
    }
    
    // MARK: - State Update
    func updateTitle(_ text: String) {
        titleText = text
        currentDate = Date()
    }
    
    func updateImage(_ image: UIImage, at index: Int) {
        guard index >= 0 && index < photosArray.count else { return }
        imageData = image.jpegData(compressionQuality: 1.0)
        photosArray[index].image = imageData
        photosArray[index].thumb = makeThumbnailData(from:imageData!)
        photosArray[index].date = Date()

        imageCache.setObject(image, forKey: NSNumber(value: index))  // 캐시에 저장
        currentDate = Date()
    }
    
    func addImage(_ image: UIImage) {
        imageData = image.jpegData(compressionQuality: 1.0)
        currentDate = Date()
        
        if isAddMode {
            // 아직 CoreData에 저장되지 않은 경우, 캐시에만 미리 등록
            let nextIndex = photosArray.count
            imageCache.setObject(image, forKey: NSNumber(value: nextIndex))
        } else if let index = photosArray.firstIndex(where: { $0 == currentPhoto }) {
            imageCache.setObject(image, forKey: NSNumber(value: index))
        }
    }

    // MARK: - Save & Delete
    func save() {
        if isAddMode {
            createNewPhoto()
        } else if !updateChanged() {
            return
        }
        
        do {
            if context.hasChanges {
                try context.save()
                if isAddMode {
                    if let saved = currentPhoto {
                        photosArray.append(saved)
                    }
                    isAddMode = false
                }
            }
        } catch {
            print("Core Data 저장 실패: \(error.localizedDescription)")
        }
    }
    
    func delete() {
        guard let target = currentPhoto else { return }
        context.delete(target)
        do {
            try context.save()
        } catch {
            print("Core Data 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Image Processing
    /// 원본 이미지 Data에서 썸네일 JPEG 데이터를 생성합니다.
    /// - Parameter imageData: 원본 이미지 데이터
    /// - Returns: 썸네일 JPEG 데이터 (압축률 1.0)
    private func makeThumbnailData(from imageData: Data) -> Data {
        guard let img = UIImage(data: imageData) else { return Data() }
        return img.jpegData(compressionQuality: 1.0) ?? Data()
    }
    
    ///이미지 좌우 반전
    func reflectChange(_ img: UIImage) -> UIImage {
        let size = img.size
        let scale = img.scale
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return img }

        // 좌우 반전
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)

        // Orientation 처리를 위해 draw 사용
        img.draw(in: CGRect(origin: .zero, size: size))

        let flippedImage = UIGraphicsGetImageFromCurrentImageContext() ?? img
        UIGraphicsEndImageContext()
        return flippedImage
    }
    
    ///이미지 회전
    func orientationChange(_ image: UIImage) -> UIImage {
        var orientation = image.imageOrientation
        orientation = {
            switch orientation {
            case .left: return .up
            case .up: return .right
            case .right: return .down
            case .down: return .left
            case .leftMirrored: return .upMirrored
            case .upMirrored: return .rightMirrored
            case .rightMirrored: return .downMirrored
            case .downMirrored: return .leftMirrored
            default: return orientation
            }
        }()
        let newImage = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: orientation)
        UIGraphicsBeginImageContextWithOptions(newImage.size, false, newImage.scale)
        newImage.draw(in: CGRect(origin: .zero, size: newImage.size))
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return finalImage
    }
    
    // MARK: - Private Helpers
    private func createNewPhoto() {
        guard let newPhoto = NSEntityDescription.insertNewObject(
            forEntityName: CoreEntityName.photos,
            into: context
        ) as? Photos else { return }

        newPhoto.title = isNotBlank(titleText) ? titleText : dateText
        newPhoto.image = imageData
        newPhoto.thumb = makeThumbnailData(from:imageData!)
        newPhoto.date = currentDate
        self.currentPhoto = newPhoto
    }
    
    private func updateChanged() -> Bool {
        guard let pts = currentPhoto else { return false }
        var didChange = false
        if pts.title != titleText {
            pts.title = titleText
            didChange = true
        }
        if let tmpData = imageData, tmpData != pts.image {
            pts.image = tmpData
            pts.thumb = makeThumbnailData(from:tmpData)
            didChange = true
        }
        if pts.date != currentDate {
            pts.date = currentDate
            didChange = true
        }
        
        return didChange
    }
}
