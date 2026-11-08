# iOS용 톈이 위키

[简体中文](README.md) | [English](README.en.md) | [Français](README.fr.md) | [日本語](README.ja.md) | 한국어 | [文言](README.lzh.md)

**장쑤성 톈이 중학교 비공식 위키**의 iPhone 및 iPad 클라이언트입니다. 커뮤니티가 학교 역사, 교내 장소, 동아리, 행사 및 학교 문화를 기록합니다. 학교 또는 Wikimedia Foundation의 공식 앱이 아니며 공식 입장을 대변하지 않습니다.

[Wikipedia iOS](https://github.com/wikimedia/wikipedia-ios)를 fork하여 `WMFData`의 네트워크, 요청 취소 및 저장 기능과 `WMFComponents`의 탐색 컨트롤러, 글꼴 및 HTML 요약 처리를 재사용합니다. 톈이의 MediaWiki API용 어댑터를 별도로 구현했습니다. 저작권 고지와 [원본 README](docs/upstream-wikipedia-ios.md)를 보존합니다.

## 기능과 언어

- iOS / iPadOS 26 이상에서는 기본 탐색 및 탭 막대에 Liquid Glass를 적용하고 시스템 화면 및 손쉬운 사용 설정을 따릅니다. 본문은 가독성을 우선하며 이전 시스템은 호환되는 기본 스타일을 사용합니다.
- `Bad Apple!!`는 전체 온라인 페이지로 열어 본문 애니메이션, 음악, 일시 정지 및 종료 기능을 유지합니다. 오프라인 본문 기능은 아닙니다.
- 중국어 간체, 영어, 프랑스어, 일본어, 한국어 및 한문(文言) 인터페이스.
- 앱 언어와 위키 언어를 별도로 선택할 수 있습니다. 한국어 인터페이스에서 중국어 또는 일본어 문서도 읽을 수 있습니다.
- 네이티브 검색, 학교 둘러보기, 최근 바뀜 및 임의 문서.
- `action=parse`를 통한 본문 표시, 목차, 글자 크기, 공유 및 문서 역사 링크.
- 문서 언어 메뉴는 기존 언어 간 링크를 사용합니다. 대응하는 문서가 없는 경우 자동 번역하지 않습니다.
- 저장한 본문을 오프라인에서 읽고 최대 200개의 읽기 기록을 유지합니다. 이미지, 음성 및 동영상은 인터넷이 필요합니다.
- 제공된 원본 글씨를 다시 그리지 않고 흰색 정사각형 배경에 배치한 앱 아이콘.

| 위키 언어 | 주소 |
| --- | --- |
| 中文 | https://zh-wiki.tyzx.org |
| English | https://en-wiki.tyzx.org |
| Français | https://fr-wiki.tyzx.org |
| 日本語 | https://ja-wiki.tyzx.org |
| 한국어 | https://ko-wiki.tyzx.org |
| 文言 | https://lzh-wiki.tyzx.org |

언어 사이트마다 문서 범위가 다르며 기존 언어 간 링크의 대상 문서가 아직 없을 수 있습니다. 이 경우 누락 안내와 해당 사이트 대문으로 가는 버튼을 표시합니다. 번역문을 자동 생성하지 않습니다.

## 실행

Swift 6.2 이상을 지원하는 Xcode가 필요합니다. 최소 지원 버전은 iOS / iPadOS 17이며 개발 검증에는 Xcode 27.2를 사용했습니다.

**`TianyiWiki.xcodeproj`**를 열고 **`TianyiWiki`** scheme을 선택하세요. Swift Package 의존성 확인 후 시뮬레이터에서 실행할 수 있습니다. 실제 기기에서는 본인의 Apple 개발 팀을 선택하고 필요하면 `org.tyzx.TianyiWiki` 식별자를 변경하세요. `Wikipedia.xcodeproj`는 원본 상위 프로젝트이며 톈이 앱의 시작 지점이 아닙니다.

```sh
xcodebuild -project TianyiWiki.xcodeproj -scheme TianyiWiki \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' \
  -derivedDataPath /tmp/tyzx-fork-build CODE_SIGNING_ALLOWED=NO build
```

## 개발 상태, 개인정보 및 라이선스

현재 개발 버전이며 App Store에 출시되지 않았습니다. 네이티브 로그인 및 편집, 알림, Wikimedia 추천, 기기 간 동기화는 이식되지 않았습니다. 분류 및 특수 문서는 기존 웹사이트를 이용합니다. 저장된 본문은 오래될 수 있으므로 직접 새로 고쳐야 합니다.

저장 목록과 기록은 기기에 보관합니다. Wikimedia 인증, 분석 또는 기부 서비스를 초기화하지 않습니다. 톈이 사이트와 외부 미디어로 보내는 요청에는 해당 서비스의 개인정보 처리 방식이 적용됩니다.

원본 코드와 톈이 추가 코드는 [MIT License](LICENSE.txt)를 따르며 © 2013–2025 Wikimedia Foundation et al. 고지를 유지합니다. 브랜드 이미지, 문서 및 미디어의 권리는 별도로 확인해야 합니다. 코드 라이선스가 해당 권리를 부여하지 않습니다. 출시 전 신고 및 콘텐츠 관리, 개인정보 보호, 필요한 계정 관리, 실제 기기 테스트 및 지역 요건을 준비해야 합니다. [App Store 검토 문서](TianyiWiki/APP_STORE.md)는 중국어 간체로 제공됩니다. 빌드 성공은 Apple 심사 통과를 보장하지 않습니다.
