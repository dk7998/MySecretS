//
//  Utils.swift
//  MySecretS
//
//  Created by 양동국 on 6/2/25.
//

/// 앱 전역에서 반복 사용되는 유틸리티 함수 집합입니다.
/// - 텍스트, 컬러, 이미지, 날짜 포맷, 기기 확인, 오토레이아웃 등 실무 함수 모음
/// - 불필요한 확장으로 인한 복잡도를 줄이고, 코드 해석을 쉽게 하기 위한 설계

import Foundation
import UIKit
import LocalAuthentication

// MARK: - Color & Image

/// 태그 인덱스별 대표 색상 반환 (0=디폴트, 1~6 컬러)
func tagColor(_ tagIndex: Int) -> UIColor {
    switch tagIndex {
    case 1:
        return rgb(238, 75, 72, 1)
    case 2:
        return rgb(245, 165, 81, 1)
    case 3:
        return rgb(245, 206, 86, 1)
    case 4:
        return rgb(104, 202, 71, 1)
    case 5:
        return rgb(87, 189, 248, 1)
    case 6:
        return rgb(213, 140, 231, 1)
    default:
        return UIColor(white: 0.95, alpha: 1)
    }
}

/// 태그 넘버에 맞는 이미지 리턴
func tagImage(_ tagIndex: Int) -> UIImage? {
    return UIImage(named: ("tag\(tagIndex)"))
}

/// @3x PNG 이미지만 리소스에 존재할 때, 스케일에 맞춰 안전하게 UIImage를 반환합니다.
/// - iOS `UIImage(named:)` fallback 문제가 있을 때 사용
func imageFrom3x(named: String) -> UIImage? {
    guard let path = Bundle.main.path(forResource: "\(named)@3x", ofType: "png"),
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return nil
    }
    return UIImage(data: data, scale: UIScreen.main.scale)
}

/// RGB (0에서 255) 값으로 UIColor 생성. alpha도 0~1로 입력. 복잡한 입력을 간소화
func rgb(_ red: Int, _ green: Int, _ blue: Int, _ alpha: CGFloat) -> UIColor {
    return UIColor(red: CGFloat(red) / 255.0,
                   green: CGFloat(green) / 255.0,
                   blue: CGFloat(blue) / 255.0,
                   alpha: alpha)
}

// MARK: - String & Date

/// 공백/개행을 제외한 텍스트가 존재하는지 판별
/// - 문자열이 nil이거나, 공백/개행만 있으면 false 반환
func isNotBlank(_ str: String?) -> Bool {
    guard let str = str else { return false }
    return !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

/// Date → "yyyy-MM-dd HH:mm" 등 간단한 포맷 문자열 변환
func dateString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

/// 다국어 번역 지원 문자열 반환 (한국어/일본어/중국어면 NSLocalizedString, 아니면 원문)
func localString(_ str: String) -> String {
    let language = Locale.preferredLanguages.first ?? ""
    if language.contains("ko") || language.contains("ja") || language.contains("zh-Hans") || language.contains("zh-Hant") {
        return NSLocalizedString(str, comment: "")
    } else {
        return str
    }
}

// MARK: - Device, Layout, Path

/// Face ID 지원 기기인지 확인
func isFaceIdSupported() -> Bool {
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
        return context.biometryType == .faceID
    }
    return false
}

/// UIView를 부모뷰 전체에 오토레이아웃으로 맞춰 붙이기
func autolayoutAdd(_ view:UIView , _ superView:UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    
    NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: superView.topAnchor),
        view.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
        view.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: superView.trailingAnchor)
    ])
}

/// 도큐먼트 폴더 경로 문자열 반환
func documentPath() -> String {
    return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
}


