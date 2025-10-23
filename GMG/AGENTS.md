# Repository Guidelines

## Collaboration Principles
- 우리는 허밍 기반 코드 추천 앱을 함께 완성하는 든든한 파트너다.
- 나는 SwiftUI·AudioKit·Core ML을 다루는 시니어 개발자로서 SOLID 원칙과 객체지향 패턴 준수를 책임진다.
- 당신은 제품 방향을 이끌고, 나는 설계·품질·기술 의사결정에서 적극적으로 제안하며 끝까지 지원한다.
- 모든 변경 사항은 페어로 리뷰하고, 학습한 내용과 결정 사항은 문서화해 팀 전체가 공유할 수 있게 한다.
- 코드 리뷰나 제안 시에는 수정될 부분만 구체적으로 제시한다.

## ChordProgress UI Notes
- 화면 위치: `Scenes/ChordProgress`, MVI 구성(View/Container/Model/Intent/Effect)을 따른다.
- 상단: BPM·조성·박자 정보, 코드 삭제, Undo/Redo를 노출한다.
- 중단: 마디별 코드 셀과 허밍 파형을 수평으로 배치하고 재생 시 셀/파형이 색 채워지며 재생바가 이동한다.
- 하단: 재생/정지 버튼과 코드 후보 리스트(셀 선택 시 4~5개의 대체 코드)를 표시한다.
- 삭제 시 해당 코드 셀(마디)이 제거되고 이전 마디가 길이를 채운다.
- 코드 변경·삭제·후보 선택은 Undo/Redo 히스토리에 포함한다.
- 허밍과 코드 사운드는 개별 로컬 파일로 동시에 재생하며 재생바 이동은 자연스러운 속도를 유지한다.
- 파형은 원본 녹음 파일 기반으로 시각화하며 확대/스크롤 요구는 없다.

## Project Structure & Module Organization
- `GMG/App` bootstraps the SwiftUI entry point (`GMGApp`).
- `GMG/Scenes`, `Navigation`, and `UI` host presentation flows, routers, and view components.
- `GMG/Core` contains shared logic—domain models, services, utilities, and design-system assets.
- `GMGTests/FeaturesTests` stores feature-level scenarios using Apple’s new `Testing` framework.
- `fastlane` and the `Gemfile` pin delivery tooling; keep credentials out of version control.

## Build, Test, and Development Commands
- `xed GMG.xcodeproj` opens the project in Xcode for iterative development.
- `xcodebuild -scheme GMG -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build` validates a clean build.
- `xcodebuild test -scheme GMG -destination 'platform=iOS Simulator,name=iPhone 15'` runs the `Testing`-based test suite.
- `bundle exec fastlane ios custom_lane` executes the default fastlane automation pipeline.

## Coding Style & Naming Conventions
- Swift 5.9+, 4-space indentation, and brace-on-same-line per Swift API Design.
- Types use PascalCase (`ContentView`), methods and properties use lowerCamelCase (`font(customFont:)`).
- Group related behaviors in extensions; favor value types and protocol-first designs.
- Keep design tokens centralized under `Core/DesignSystem`; avoid hardcoding fonts or spacing in views.

## Testing Guidelines
- Write `Testing` structs per feature with descriptive method names: `@Test func chordSuggestion_updatesProgression()`.
- Cover new services, audio-processing branches, and routing logic. Aim for parity between UI flows and domain utilities.
- Tag flaky or async-heavy tests with comments explaining mitigation; run the simulator tests before pushing.

## Commit & Pull Request Guidelines
- Follow the existing `[type] message` commit prefix (`[feature]`, `[fix]`, `[chore]`, `[refactor]`).
- Commits should stay focused; squash noisy WIP history before opening a PR.
- PRs must describe the user scenario, list testing evidence (`xcodebuild test` output or screenshots), and link Jira/issue IDs when available.
- Capture UI changes with before/after images or screen recordings of the humming-to-chords flow.

## Audio & ML Notes
- Verify BPM/time-signature handling in `TimeSignatureView` before recording sessions.
- When updating Core ML models, document feature extraction steps and update any latency expectations in `chordLoadingView`.
- Ensure chord previews play back through AudioKit with graceful failure handling when devices lack microphone access.
