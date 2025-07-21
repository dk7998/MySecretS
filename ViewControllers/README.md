# Controllers 폴더

실제 화면(ViewController) 구현 파일을 모아둔 폴더입니다.  
각 화면별로 역할이 명확한 뷰컨트롤러를 관리합니다.

## 포함 파일 예시
- MainViewController.swift : 메인(탭/리스트) 화면
- SetController.swift : 환경설정 화면
- SubController.swift : 메모(Information) 입력/수정 화면
- SubController2.swift : 이미지(Photos) 상세/편집 화면
- SubController3.swift : 패스코드(Passcode) 관리 화면
- LockViewController.swift :
앱 잠금(비밀번호 입력) 전용 화면.
앱 최초 실행 또는 백그라운드 복귀 시,
보안 목적으로 락(잠금) 상태를 표시하고
올바른 패스코드 입력 시에만 앱 사용 가능하게 제한
