# 天一維基 iOS

[简体中文](README.md) | [English](README.en.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | 文言

此乃**江蘇省天一中學非官方維基**之 iPhone、iPad 用程式也。眾人共記校史、園中諸地、學社、校事與風俗。非校方所設，亦非 Wikimedia Foundation 官方之作，不代其言。

本庫自 [Wikipedia iOS](https://github.com/wikimedia/wikipedia-ios) 分支而來。用其 `WMFData` 以行網路請求、止已廢之索、存本機之錄；用其 `WMFComponents` 以設導覽、字體及 HTML 摘文。另作適配，以接天一 MediaWiki 之 API。[上游原序](docs/upstream-wikipedia-ios.md)、作者與授權之文，悉仍存焉。

## 原生首頁與離線播映

首頁取中文站實有之文，配維護者所賜透明字標與校園諸圖，作原生卡片。文圖內置，初啟雖斷網亦可覽；快照隨程式版本而新。近改聯網更新，藏於本機；每條惟留末次之改，至多五條。

iOS 二十六以上，閱覽之具用真 glassEffect。暗色兼及圖說、表格與必要之網頁；網頁之頂端告示與導覽皆隱。

Bad Apple!! 以 AVPlayer 播本機之樂，按原生時刻驅正文黑幕。初覽須聯網取樂、幀與正文，既藏則不啟原網頁亦可播。外圖與外鏈或仍須網。清離線所藏，亦刪彩蛋素材。

評論仍循網站登入與權限。無評論之區者，告「此條已閉評論」，不以議論頁代之。評論須聯網，未於正站發試評。尋常黑幕可觸而揭之。

## 所能與諸語

- iOS、iPadOS 二十六以上，導覽與分頁用系統 Liquid Glass 之式，隨明暗及輔助之設而變；正文以易讀為先，舊系統仍用相容原生之式。
- 介面有簡中、英、法、日、韓、文言六語。
- 介面之語與所覽之站各別。用文言介面，亦可讀中文、英文及諸語條目。
- 可索條目、遊校園、察近改、隨覽一條。
- 以 `action=parse` 取正文，具目錄、字級、分享及修訂舊錄之門。
- 條目之語，依既有跨語之鏈相通。無相應之條，則不擅譯而造之。
- 藏其正文，斷網亦可閱；圖像影音仍須聯網。閱歷至多二百條，存於本機。
- 圖標用維護者所賜原字標，加純白方底，筆跡不易。

| 站語 | 所在 |
| --- | --- |
| 中文 | https://zh-wiki.tyzx.org |
| English | https://en-wiki.tyzx.org |
| Français | https://fr-wiki.tyzx.org |
| 日本語 | https://ja-wiki.tyzx.org |
| 한국어 | https://ko-wiki.tyzx.org |
| 文言 | https://lzh-wiki.tyzx.org |

六站所載各異，跨語之鏈或有而其頁未成。遇之則明告闕文，並設所選之站首頁之門，不擅造譯文。

## 啟用之法

須 Xcode 能用 Swift 6.2 或其後者。所需系統，iOS、iPadOS 十七以上；今以 Xcode 27.2 驗之。

啟 **`TianyiWiki.xcodeproj`**，擇 **`TianyiWiki`** scheme，俟 Swift Package 諸依賴備，乃可於模擬器行之。若用真機，須擇己之 Apple 開發團隊，酌改 `org.tyzx.TianyiWiki`。`Wikipedia.xcodeproj` 仍為上游原工程，非天一版之入口。

```sh
xcodebuild -project TianyiWiki.xcodeproj -scheme TianyiWiki \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4' \
  -derivedDataPath /tmp/tyzx-fork-build CODE_SIGNING_ALLOWED=NO build
```

## 今狀與權責

今尚在開發，未登 App Store。登入及編輯之原生移植、推播、Wikimedia 推薦、跨機同步，皆未備。分類與特殊頁仍用既有網站。所藏正文或舊，宜時更新。

所藏與閱歷留於本機，不啟 Wikimedia 認證、統計、募款之服務。然天一網站與外部影音之請求，仍依各自私隱之約。

上游及天一新增源碼依 [MIT 授權](LICENSE.txt)，原著作權 © 2013–2025 Wikimedia Foundation et al. 之文仍存。字標、條目、圖像影音之權，各從其實；源碼授權不足代之。欲上架，尚須備檢舉處置、內容治理、私隱文書、必要之帳號管理、真機之驗及各地法規所需。[上架評估](TianyiWiki/APP_STORE.md)以簡中書之。編譯雖成，非謂 Apple 已許其上架也。
