# 🍒 Cherry Pick – 여행 짐싸기 및 항공규정 체크 앱

AI 기반 여행 짐싸기 및 항공 규정 확인을 도와주는 모바일 애플리케이션입니다.  
여행 준비 과정에서 발생하는 짐 누락, 항공 규정 위반, 불필요한 짐 문제를 줄이기 위해 기획되었습니다.

---

## 📌 Project Background

Cherry Pick은 캡스톤 디자인 팀 프로젝트로,  
초행 여행자나 국제선 이용 시 복잡한 수하물 규정으로 어려움을 겪는 사용자를 주요 타겟으로 설계되었습니다.

여행 전 짐을 체계적으로 관리하고,  
카메라 스캔과 AI 분석을 통해 항공 규정 위반 여부를 사전에 확인할 수 있도록 돕는 것을 목표로 합니다.

---

## ✨ 주요 기능

### 🍒 체리픽 (짐 관리)
- 가방별 아이템 관리
- 패킹 상태 추적
- 검색 기능
- 카테고리별 분류

### 📷 스캔
- 카메라로 물품 스캔
- AI 기반 항공 규정 확인
- 기내 / 위탁 수하물 허용 여부 표시
- 주의사항 안내

### ✈️ 항공 규정
- 국가 / 항공사별 수하물 규정
- 기내 / 위탁 수하물 제한사항
- 금지 품목 안내
- 면세 한도 정보

### 🌍 여행 추천
- 여행지별 맞춤 추천
- 날씨 정보
- 인기 아이템
- 옷차림 가이드
- 쇼핑 가이드

---

## 👤 My Role (Frontend)

본 프로젝트는 **3인 팀으로 진행된 캡스톤 디자인 프로젝트**이며,  
저는 **Flutter 기반 프론트엔드 개발을 전담**했습니다.

### 주요 담당 업무
- 전체 UI/UX 구조 설계 및 화면 구현
- Provider 기반 상태 관리 구조 설계
- GoRouter를 활용한 화면 네비게이션 구성
- 백엔드 API 연동 및 데이터 바인딩
- 카메라 / 이미지 스캔 기능 UI 구현
- 항공 규정 결과에 따른 UI 분기 처리
- 로딩 / 에러 상태 처리 및 사용자 피드백 설계

---

## 🔗 Backend Integration

백엔드는 팀 내 다른 구성원이 개발했으며,  
프론트엔드에서는 **REST API 방식**으로 연동했습니다.

### 연동 방식
- HTTP 기반 REST API 통신
- 여행 정보, 짐 아이템, 스캔 결과 데이터를 API로 요청
- 응답 데이터를 Provider 상태로 관리하여 UI에 반영

### 프론트엔드 관점에서의 역할
- API 요청 / 응답 모델 정의
- 비동기 통신에 따른 로딩 및 에러 상태 처리
- 항공 규정 결과에 따른 사용자 안내 UI 구성

---

## 🧱 Frontend Architecture

- Presentation Layer: Screens / Widgets
- State Management: Provider
- Navigation: GoRouter
- Data Flow: API → Provider → UI

---

## 🛠 기술 스택

- **Flutter** – 크로스 플랫폼 모바일 앱 개발
- **Dart** – 프로그래밍 언어
- **Provider** – 상태 관리
- **GoRouter** – 네비게이션
- **Camera** – 카메라 기능
- **Image Picker** – 이미지 선택

---

## 🚀 설치 및 실행

### 필수 요구사항
- Flutter SDK 3.0.0 이상
- Dart SDK 3.0.0 이상
- Android Studio 또는 VS Code
- Android / iOS 개발 환경

### 설치 방법

    git clone <repository-url>
    cd cherrypick-app
    flutter pub get
    flutter run

---

## 📂 프로젝트 구조

    lib/
    ├── main.dart                     # 앱 진입점
    ├── models/                       # 데이터 모델 정의
    │   ├── airline_ref.dart
    │   ├── airport_ref.dart
    │   ├── bag.dart
    │   ├── cabin_class_ref.dart
    │   ├── country_ref.dart
    │   ├── device_register.dart
    │   ├── item_preview_sample.dart
    │   ├── outfit_recommendation.dart
    │   ├── packing_item.dart
    │   ├── preview_request.dart
    │   ├── preview_response.dart
    │   └── trip.dart
    │
    ├── providers/                    # Provider 기반 상태 관리
    │   ├── device_provider.dart
    │   ├── packing_provider.dart
    │   ├── preview_provider.dart
    │   ├── reference_provider.dart
    │   └── trip_provider.dart
    │
    ├── screens/                      # 화면 단위 UI
    │   ├── checklist_screen.dart
    │   ├── home_screen.dart
    │   ├── initial_trip_screen.dart
    │   ├── item_preview_screen.dart
    │   ├── luggage_screen.dart
    │   ├── onboarding_screen.dart
    │   ├── recommendations_screen.dart
    │   ├── rules_check_result_screen.dart
    │   ├── scan_screen.dart
    │   └── splash_screen.dart
    │
    ├── service/                      # 백엔드 API 통신 레이어
    │   ├── bag_api.dart
    │   ├── detect_api.dart
    │   ├── device_api.dart
    │   ├── fx_api.dart
    │   ├── item_api.dart
    │   ├── preview_api.dart
    │   ├── recommendation_api.dart
    │   ├── reference_api.dart
    │   ├── rules_api.dart
    │   └── trip_api.dart
    │
    ├── theme/                        # 앱 테마 설정
    │   └── app_theme.dart
    │
    ├── widgets/                      # 재사용 UI 컴포넌트
    │   ├── add_bag_dialog.dart
    │   ├── add_item_dialog.dart
    │   ├── add_trip_dialog.dart
    │   ├── app_header.dart
    │   ├── bag_card.dart
    │   ├── bottom_navigation.dart
    │   ├── cherry_app_bar.dart
    │   ├── fx_widgets.dart
    │   ├── item_list.dart
    │   ├── item_scanner.dart
    │   ├── item_status_styles.dart
    │   ├── packing_manager.dart
    │   ├── primary_button.dart
    │   ├── regulation_checker.dart
    │   ├── simple_header.dart
    │   ├── travel_recommendations.dart
    │   ├── trip_selector_dialog.dart
    │   └── yolo_scanner.dart
    │
    └── utils.ts                      # 공통 유틸리티 함수

---

## 🧩 주요 특징

### UI / UX
- 반응형 디자인 (다양한 화면 크기 지원)
- Material Design 3 적용
- 다크 / 라이트 테마 지원
- 직관적인 네비게이션 구조

### State Management
- Provider 패턴 기반 상태 관리
- 효율적인 상태 업데이트 및 데이터 흐름 관리

### User Experience
- 부드러운 화면 전환 및 애니메이션
- 사용자 피드백 중심 UI 구성

---

> Originally developed as a team capstone project under an academic organization repository.
