//
//  AppSettings.swift
//  MySecretS
//
//  Created by 양동국 on 7/7/25.
//

import Foundation

// MARK: - Key Definitions
enum AppSettingKey {
    static let selectedTapIndex = "dTapNum"
    static let sortOptionIndex = "dList"
    static let timeOutIndex = "dTimeOut"
    static let usePassword = "dUsePassword"
    static let imageBlur = "dImageBlur"
    static let passcodeLockOptions = "dPasscodeDefault"
    static let didShowHelp = "dHelpInitial"
    static let mainPasscode = "dMainPasscode"
    static let isInitialLaunch = "dInitial"
}

// MARK: - Core Data Entity Names
struct CoreEntityName {
    static let information = "Information"
    static let photos = "Photos"
    static let passcode = "Passcode"
}

// MARK: - App Settings

/// 앱 설정 값을 UserDefaults 기반으로 통합 관리하는 구조체입니다.
///
/// - Bool/Int 값을 문자열("1", "0" 등)로 저장하여 이전 앱 버전과의 호환성을 유지합니다.
/// - 타입 일관성으로 크래시 및 마이그레이션 리스크를 최소화합니다.
/// - 일부 설정은 배열([String]) 형태로 UI와 직접 연동됩니다.
/// - 모든 키는 enum(AppSettingKey)로 분리해 관리합니다.
/// - 테스트 환경에서는 UserDefaults 주입(inject)도 지원합니다.
///
/// NOTE:
/// 값 타입의 일관성(Bool/Int → String) 유지는 타입 변환 오류를 줄이고,
/// 예기치 않은 크래시 방지에 도움이 됩니다.
struct AppSettings {
    
    // MARK: - Internal Properties
    // UserDefaults 인스턴스를 외부 주입 가능하도록 분리 (유닛 테스트 대응)
    private static var defaults = UserDefaults.standard
    static let timeoutOptions = [10, 30, 60, 90]
    
    // MARK: - Stored Properties (UserDefaults-backed)

    static var mainPasscode: String? {
        get { defaults.string(forKey: AppSettingKey.mainPasscode) }
        set { defaults.set(newValue, forKey: AppSettingKey.mainPasscode) }
    }

    static var didShowHelp: Bool {
        get {
            let str = defaults.string(forKey: AppSettingKey.didShowHelp)
            return str == "1"
        }
        set {
            defaults.set(newValue ? "1" : "0", forKey: AppSettingKey.didShowHelp)
        }
    }

    static var selectedTapIndex: Int {
        get {
            if let str = defaults.string(forKey: AppSettingKey.selectedTapIndex),
               let intVal = Int(str) {
                return intVal
            }
            return defaults.integer(forKey: AppSettingKey.selectedTapIndex)
        }
        set {
            defaults.set("\(newValue)", forKey: AppSettingKey.selectedTapIndex)
        }
    }

    static var sortOptionIndex: Int {
        get {
            if let str = defaults.string(forKey: AppSettingKey.sortOptionIndex),
               let intVal = Int(str) {
                return intVal
            }
            return defaults.integer(forKey: AppSettingKey.sortOptionIndex)
        }
        set {
            defaults.set("\(newValue)", forKey: AppSettingKey.sortOptionIndex)
        }
    }

    static var timeOutIndex: Int {
        get {
            if let str = defaults.string(forKey: AppSettingKey.timeOutIndex),
               let intVal = Int(str) {
                return intVal
            }
            return defaults.integer(forKey: AppSettingKey.timeOutIndex)
        }
        set {
            defaults.set("\(newValue)", forKey: AppSettingKey.timeOutIndex)
        }
    }
    
    // NOTE: Bool 값을 "1"/"0" 문자열로 저장하는 이유는 기존 앱 버전과의 호환성을 위한 설계 결정입니다.
    static var isUsingPassword: Bool {
        get {
            let str = defaults.string(forKey: AppSettingKey.usePassword) ?? "1"
            return str != "0"
        }
        set {
            defaults.set(newValue ? "1" : "0", forKey: AppSettingKey.usePassword)
        }
    }

    static var isImageBlurred: Bool {
        get { defaults.string(forKey: AppSettingKey.imageBlur) != "0" }
        set { defaults.set(newValue ? "1" : "0", forKey: AppSettingKey.imageBlur) }
    }

    static var passcodeLockOptions: [Bool] {
        get {
            if let arr = defaults.array(forKey: AppSettingKey.passcodeLockOptions) as? [String] {
                return arr.map { $0 == "1" }
            }
            return [false, false, false, false]
        }
        set {
            let stringArray = newValue.map { $0 ? "1" : "0" }
            defaults.set(stringArray, forKey: AppSettingKey.passcodeLockOptions)
        }
    }

    static var isInitialLaunch: Bool {
        get { defaults.string(forKey: AppSettingKey.isInitialLaunch) == "1" }
        set { defaults.set(newValue ? "1" : "0", forKey: AppSettingKey.isInitialLaunch) }
    }
    
    // MARK: - Utility Functions
    
    /// 테스트용 UserDefaults 주입
    static func inject(_ newDefaults: UserDefaults) {
        self.defaults = newDefaults
    }

    static func removeMainPasscode() {
        defaults.removeObject(forKey: AppSettingKey.mainPasscode)
    }

    /// 초기 실행 시 기본값을 설정
    static func registerDefaultValues() {
        let defaultValues: [String: Any] = [
            AppSettingKey.selectedTapIndex: "0",
            AppSettingKey.timeOutIndex: "2",
            AppSettingKey.sortOptionIndex: "1",
            AppSettingKey.imageBlur: "0",
            AppSettingKey.usePassword: "1",
            AppSettingKey.passcodeLockOptions: ["0", "0", "0", "0"]
        ]
        defaults.register(defaults: defaultValues)
    }

    static func timeOutSeconds() -> Int {
        return timeoutOptions[safe: timeOutIndex] ?? 30
    }
}
