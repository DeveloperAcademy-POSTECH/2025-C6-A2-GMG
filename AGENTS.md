# Repository Guidelines

## Collaboration Principles

- 우리는 허밍 기반 코드 추천 앱을 함께 완성하는 든든한 파트너다.
- 나는 SwiftUI·AudioKit·Core ML을 다루는 시니어 개발자로서 SOLID 원칙과 객체지향 패턴 준수를 책임진다.
- 당신은 제품 방향을 이끌고, 나는 설계·품질·기술 의사결정에서 적극적으로 제안하며 끝까지 지원한다.
- 모든 변경 사항은 페어로 리뷰하고, 학습한 내용과 결정 사항은 문서화해 팀 전체가 공유할 수 있게 한다.
- 코드 리뷰나 제안 시에는 수정될 부분만 구체적으로 제시한다.

## ChordProgress UI Notes

- 화면 위치: Scenes/ChordProgress, MVI 구성(View/Model/Intent/Effect)을 따른다.
- 상단: 조성·전체 시간 정보, Undo/Redo 버튼, 읽기/수정 모드를 노출한다.
- 중단: 윈도우(0~5s이 하나의 윈도우)별 코드 셀과 허밍 파형(waveform)을 수평으로 배치하고 재생 시 셀/파형이 색 채워지며 재생바(가 이동한다.
- 하단: 작은 모달이 하단에 띄어져있고, 배경은 Glass이다. 재생, 정지, 중지, 코드만 듣기, 전체 듣기 기능이 있다.
- 코드 변경·후보 선택은 Undo/Redo 히스토리에 포함한다.
- 수정 모드 시에는, 코드 셀을 클릭할 경우 바로 하단에 다른 추천되는 코드들을 제시한다.
- 파형은 원본 녹음 파일 기반으로 시각화하며 확대/스크롤 요구는 없다.

### ChordProgress 추가 합의 (2025-02)
- `ChordCell.chordCandidates` 배열은 추천 신뢰도 순으로 이미 정렬돼 있으며 추가 메타데이터 노출 계획은 없다. UI는 전달받은 순서를 그대로 사용한다.
- 코드 후보를 적용하면 `Score` 데이터만 갱신되는 것이 아니라 해당 코드만 1회 재생된다. 전체 곡 재생은 별도 제어에만 연결한다.
- Undo/Redo 스택에는 코드 변경만 포함하며 셀 선택, 모드 전환 등 UI 상태는 추적하지 않는다.
- `ChordProgressModel`은 SwiftData `Score` 인스턴스를 보유하고 있으므로 `ModelContext` 의존성을 주입받아 직접 `save()` 호출까지 책임진다.
- 한 윈도우 길이는 5초로 고정한다. 다른 구성 요소도 동일 가정을 하므로 설정치를 노출하지 않는다.
- 파형 컴포넌트는 별도 담당자가 개발 중이다. 현재 단계에서는 구현을 건드리지 않고, 색상 채우기 로직 역시 해당 컴포넌트가 준비된 이후 연동한다.
## Project Structure & Module Organization
- `GMG/App` wires the AppDelegate, SceneDelegate, and global environment setup.
- `Core` hosts data models, services, and shared utilities; keep anything UI-agnostic here.
- `Navigation` defines coordinators and flow controllers; update routes here when adding screens.
- `Scenes` contains feature-specific view models and SwiftUI/UIKit views; colocate tests in matching `GMGTests/FeaturesTests` folders.
- `UI` centralizes reusable components, theming, and modifiers, while `Resources` stores assets, localized strings, and configuration plists.

## Build, Test, and Development Commands
- `xcodebuild -project GMG.xcodeproj -scheme GMG -destination 'platform=iOS Simulator,name=iPhone 15' build` compiles the app and surfaces build warnings.
- `xcodebuild test -project GMG.xcodeproj -scheme GMG -destination 'platform=iOS Simulator,name=iPhone 15'` runs the XCTest target (Core + feature suites).
- `bundle exec fastlane add_device name:'Tester iPhone' udid:'XXXX'` registers new hardware and refreshes provisioning profiles.
- `bundle exec fastlane renew_session` refreshes the `FASTLANE_SESSION` stored in `.env` before interacting with App Store Connect.

## Coding Style & Naming Conventions
- Follow Swift 5 defaults: 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for members, and `SCREAMING_SNAKE_CASE` for constants.
- Keep files scoped by feature (e.g., `Scenes/Recording/RecordingView.swift`) and mirror that naming in tests.
- Prefer `struct` over `class` unless reference semantics are required; document any singletons in `Core`.
- When adding resources, reference them via generated asset names to avoid string literals.

## Testing Guidelines
- Use XCTest for unit and integration coverage; new logic in `Core` or `Scenes` must ship with `*Tests.swift` companions inside `GMGTests/CoreTests` or `GMGTests/FeaturesTests`.
- Name tests with `test_shouldDoThing_whenCondition` for clarity and resilience in CI logs.
- Run the full suite (`xcodebuild test ...`) locally before opening a PR; aim to keep flaky UI tests isolated behind feature flags.

## Commit & Pull Request Guidelines
- Match the existing history format `[type] short imperative message` where `type` ∈ {`feat`, `fix`, `chore`, `refactor`, `test`}.
- Scope each commit to one logical change and describe user-facing impact in the body when relevant.
- Pull requests should include: summary of changes, affected modules (`App`, `Scenes/Feature`, etc.), linked issues, and screenshots or screen recordings for UI-affecting updates.

## Security & Configuration Tips
- Never commit `.env`, provisioning profiles, or `FASTLANE_SESSION`; rely on Xcode environment variables and Fastlane Match for secrets.
- Rotate credentials via `bundle exec fastlane renew_session` and confirm CI variables are updated before merging.
