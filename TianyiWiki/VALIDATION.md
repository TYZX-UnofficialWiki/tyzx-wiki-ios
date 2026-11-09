# 验证记录

最新账号、标签页与评论验收：2026-11-09，见文末。以下保留此前版本记录。

日期：2026-11-08。上游基线：`0b9980f19f5307f82d072298c3624e568bc1c6be`。工具链：Xcode 27.2、Swift 6.4.2；天一应用采用 Swift 6 语言模式。

## 已通过

- iOS Simulator Debug 构建与 iPhoneOS Release 无签名构建。
- 8 项天一数据层测试：中文及特殊字符 URL、多语言域名白名单、上游服务调用、HTTP/API 错误、取消、离线正文、存储、跨语言链接和缺页处理；其中多个断言集中在同一用例。
- 20 项上游 `WMFBasicServiceTests`，与天一测试合计 28 项通过。
- iPhone 17 Pro / iOS 26.5：完整 5 项 UI 测试通过，覆盖搜索、正文、收藏、重启后恢复、已保存正文、六种界面、设置内即时更换语言、英文界面阅读中文并切换英文对应词条，以及 Bad Apple!! 彩蛋。
- 73 个界面翻译键，六种语言的键集合及非空值检查通过；六个 README 的本地链接检查通过。
- 六站 `Bad Apple!!` 的标准 `action=parse` 正文及跨语言数据均可获取。部分校史跨语链接的目标词条尚未创建，客户端提供缺页说明和站点首页入口。
- Bad Apple!!：完整在线网页模式，点击播放后计时前进，正文出现黑幕动画，暂停与“阅读词条”退出正常；音频 Range 请求返回 206，动画帧 JSON 返回 200。截图在 `Screenshots/BadApple-playing.png` 与 `BadApple-restored.png`。
- iPad mini / iOS 26.4：深色并配置减少透明度后的首页截图检查；iPhone 与 iPad 均在脱离 Xcode 测试运行器环境后独立安装、启动并确认进程保持运行。
- 图标为原图白底合成，1024×1024，无透明通道；原图保留，未生成式重绘文字。
- 新版系统导航使用上游 `WMFComponentNavigationController.applySystemGlassAppearance` 分支和原生 `UITab`；旧系统保留兼容分支。

独立启动检查发现了测试环境没有暴露的动态库搜索路径缺失，已补充 `@executable_path/Frameworks`，再验证 Rive 运行库随包加载。语言切换时的标签刷新及当前页恢复问题亦已修复并通过 UI 测试。

## 尚未通过或未验证

上游 WMFData 全量测试曾运行，`WMFFundraisingCampaignDataControllerTests.loadMaybeLaterAssetSixHoursLater()` 的断言失败。本次没有修改募款功能，天一应用也没有初始化募款服务；没有将全量上游测试宣称为通过。上述 28 项相关测试及 5 项天一 UI 测试单独验收通过。

尚未真机验收、实际扬声器音质检查、完成整首彩蛋连续播放测试，亦未覆盖 iOS 17–25 的运行时、每一篇条目及所有辅助功能组合。音乐计时与动画效果已在模拟器中检查，不能替代真机测试。

登录、注册、编辑、文件上传、账号删除和内容举报服务未完成原生适配。未支付 Apple 会员、上传 TestFlight、提交审核或完成 APP 备案。发布条件见 `APP_STORE.md`。

## 复验命令

在仓库根目录运行 UI 测试，选择本机已有模拟器；包测试在 WMFData 目录运行。不要把两个测试进程同时分配到同一个模拟器。

```sh
xcodebuild -project TianyiWiki.xcodeproj -scheme TianyiWiki \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

```sh
cd WMFData
xcodebuild -scheme WMFData \
  -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro),OS=26.4' \
  -only-testing:WMFDataTests/WMFTianyiDataControllerTests \
  -only-testing:WMFDataTests/WMFBasicServiceTests \
  CODE_SIGNING_ALLOWED=NO test
```

## 原生首页及播放器修订验收

2026-11-08：9 项天一数据层测试通过（新增最近更改去重、按时间排序及 5 条上限）。修订后的完整 5 项 UI 流程通过；另一次独立离线流程通过：先缓存 Bad Apple，再以 Debug 禁网开关禁止 API 和素材下载，重启后首页可见，缓存词条从阅读历史打开，AVPlayer 播放时间继续前进。此模式用于测试，不是给正式版用户的网络设置。

首页现在是中文首页内容与图片的内置原生快照，随版本更新；第一屏字标按维护者最新提供的透明 PNG 替代校徽。最近更改单独联网刷新并缓存。Bad Apple 用本地音频及帧数据驱动本地正文黑幕，无需在线原页面；普通图片和外链仍可能需要网络。iOS 26+ 阅读底栏改为真实 glassEffect，兼容页面隐藏顶端公告、导航并跟随深色模式。

Bad Apple 当前服务端无评论区域；测试已确认显示“此词条关闭了评论功能”。有评论区域时保留站点表单与权限，没有向生产站点发布测试评论，尚未验证真实账号发言。保留媒体版权发布前核验要求。

修订版 Debug 与无签名 Release 均成功构建。截图 `native-home-offline.png`、`native-BadApple-offline.png` 来自实际验收。

## iPad 专项验收（2026-11-09）

| 模拟器 | 外观 | 结果 |
| --- | --- | --- |
| iPad mini（A17 Pro），iPadOS 26.5 | 深色 | 7 项主流程全部通过，另补测开启评论区域的实际可见性 |
| iPad Pro 13 英寸（M5），iPadOS 27.0 | 浅色 | 7 项主流程全部通过，另补测开启评论区域的实际可见性 |
| iPhone 17 Pro，iOS 26.5 | 系统默认 | 阅读、收藏、搜索、彩蛋及评论区域回归通过 |

每台 iPad 的主流程覆盖：搜索与收藏重启恢复、六语言界面、设置内切换语言、英文界面阅读中文并切换英文对应词条、原生彩蛋播放/暂停/恢复正文及评论关闭提示、禁用 API 和素材下载后的首页/彩蛋缓存，以及纵横屏切换、目录/语言面板、字号菜单、分享弹窗和返回首页恢复标签栏。大字号场景从 1.6 倍开始，不是默认字号。

本轮修复：

- iPadOS 18+ 的顶部浮动标签使用 `setTabBarHidden` 管理阅读状态，避免沿用底部标签隐藏标记后丢失词条标题及返回按钮。返回及取消返回手势后均同步标签状态。
- 天一自定义 `tyzx-infobox`、图片框及图注跟随深色模式，覆盖模板自带的浅色样式。
- 字号调整改为正文字体缩放并重新排版，避免 WebKit 整页缩放造成横向溢出。
- 评论检测提前到文档就绪，不等待图片、音乐等全部加载。评论面板保留原 DOM、表单事件及权限，只展示评论区域，避免滚动位置变化后评论留在屏幕下方。无区域仍显示“此词条关闭了评论功能”。
- 项目生成器补全 Debug 编译标记，使播放器禁网测试开关确实参与 Debug 构建，Release 不启用该开关。
- UI 测试同时识别 iPhone 底部标签与 iPad 顶部标签，并检查评论标题位于可见面板内、加载占位消失。iPadOS 27 的 WebKit 文本节点可能短暂报告无效点击坐标，因此静态标题采用可见边界断言。

开启评论的“江苏省天一中学”已检查实际显示；当前匿名状态保留原站“您未被允许发表评论。”权限提示。Bad Apple!! 的关闭评论提示已复测。没有发布生产评论，登录后的提交、删除、审核及验证码流程仍未验收。

截图见 `Screenshots/iPad-mini-dark-home.png`、`iPad-mini-dark-reader-large-text.png`、`iPad-mini-offline-BadApple.png`、`iPad-Pro-light-home.png`、`iPad-Pro-light-reader-large-text.png`、`iPad-Pro-share-popover.png` 和 `iPad-comments-enabled.png`。截图均来自模拟器，保留大字号压力测试画面。

主流程结果包位于本次开发机 `/tmp/tyzx-ipad-mini-final.xcresult`、`/tmp/tyzx-ipad-pro-final.xcresult`；评论修复后补测为 `/tmp/tyzx-ipad-comments-fixed.xcresult`、`/tmp/tyzx-ipad-comment-visibility.xcresult`、`/tmp/tyzx-ipad-pro-comment-visibility.xcresult` 与 `/tmp/tyzx-ipad-iphone-comment-visibility.xcresult`。Debug 和无签名 iPhoneOS Release 构建成功。

尚未覆盖 iPad 真机、iPadOS 17–25 运行时、分屏/台前调度窗口尺寸、外接键盘及 Apple Pencil、真实扬声器音质和整首彩蛋连续播放。本次没有重跑与应用界面改动无关的全部上游包测试；此前募款测试失败记录仍保留。

复验新增 iPad 用例（完整 scheme 现在包含 8 项 UI 测试；iPhone 会跳过仅适用于 iPad 的布局用例）：

```sh
xcodebuild -project TianyiWiki.xcodeproj -scheme TianyiWiki \
  -destination 'platform=iOS Simulator,name=iPad mini (A17 Pro),OS=26.5' \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
```

## 上游阅读底栏移植（2026-11-09）

已确认用户截图中的底栏实现在本仓库上游 `Wikipedia/Code/ArticleToolbarController.swift`，图标按钮在 `IconBarButtonItem.swift`。天一版移植这两处的 UIToolbar 排列与 UIButton/customView 构造，沿用 WMF 的省略号字体配置；六组 PDF 图标与上游 imageset 逐字节一致。原始上游文件及 MIT 声明保留，详见 [来源说明](Branding/ToolbarSources.md)。

iOS 26+：目录独立在左，语言、收藏、页内查找、字号、更多合为右侧系统玻璃组。旧系统使用上游同一方法的兼容排列。移除了原先手绘的 SwiftUI glassEffect 整条胶囊，底栏交给 UINavigationController 自带的 UIToolbar；UIKit 容器持有 toolbarItems，正文由上游 WMFComponentHostingController 承载，避免 SwiftUI 自动清空原生工具项。

动作接入天一现有数据与服务：评论、分享、修订历史、刷新和原网页入口移至更多菜单；字号保留独立按钮；页内查找使用 WebKit 本地 UIFindInteraction。没有迁入 Wikipedia 账号、监视列表、编辑器或统计流程，也没有生成无效菜单项。

83 个界面键在六语言中集合一致、非空；六组图标与上游原件一致；六个 README 已同步底栏说明、截图和来源。新增原生工具栏与查找用例，并更新旧评论测试以先打开更多菜单。原有离线阅读及 Bad Apple 播放机制不变。

本轮验证：iPhone 17 Pro / iOS 26.5 的八个 iPhone 流程逐项验证通过，iPad 专用布局用例跳过；iPhone 18 Pro / iOS 27 的底栏/查找、阅读收藏及 Bad Apple 三项通过；iPad mini / iPadOS 26.5 的纵横屏、目录/语言/字号面板、更多菜单分享弹窗、查找和评论可见性通过。Debug 与无签名 Release 构建成功。

首轮评论用例仍等待原来的直达评论按钮，已改为先打开更多菜单。另一次完整批次中，关闭评论提示的在线网页加载超过原来的 15 秒等待；与其他在线页面统一为 30 秒后，彩蛋及关闭提示单独复测通过。没有把该失败批次宣称为完整通过。其他正文、六语言、跨语言、收藏与离线流程在该批次通过；最终补测三个用例全部通过。

结果包：`/tmp/tyzx-toolbar-acceptance.xcresult`（含上述在线等待超时）、`/tmp/tyzx-toolbar-final-verification.xcresult`（三项复验通过）、`/tmp/tyzx-toolbar-iphone27-final.xcresult`、`/tmp/tyzx-toolbar-iphone27-verified.xcresult` 与 `/tmp/tyzx-toolbar-ipad-verified.xcresult`。当前 scheme 共九项 UI 测试。

最新截图：`Screenshots/upstream-article-toolbar.png`、`upstream-article-find.png`、`upstream-ipad-share-popover.png`；已更新离线彩蛋及英文跨语言截图。当前仅模拟器验证，没有新增真机验收或生产评论提交。


## 账号、标签页与评论（2026-11-09）

顶部加入词条标签页和账号按钮；账号菜单显示当前站点经 API 确认的用户名，读取站点配置的真实头像，未设置时使用系统图标。注册、登录、退出使用应用内持久化 WebKit 中的原站表单，保留隐私政策、QQ 验证和服务器权限。新窗口政策页单独打开，关闭后返回原注册流程。

此前静态 API 正文含有评论插件的加载占位，但没有运行其远端 JavaScript，因此会一直显示 Loading comments。现将该占位替换为“查看评论”入口，打开保留网站脚本、表单和事件的真实评论区域。账号与评论共用网站会话，并同步给原生 API。普通词条正文仍不启用远端脚本；无评论区域继续显示关闭提示。

维护者已亲自在 iPhone 18 Pro / iOS 27 模拟器完成真实登录。随后目视确认原生账号菜单显示实际头像，评论面板识别同一账号，显示实际头像、输入框和“发表评论”按钮。没有提交生产测试评论，也未创建测试账号；真实注册后的 QQ 验证、验证码、评论发布/审核/删除和头像上传未完成端到端测试。登录状态保留在该模拟器；仓库仅收录匿名测试截图。

账号缓存按站点及经确认的用户 ID 隔离。未确认的 Cookie 会话使用指纹命名空间；保存用户 ID 和不可逆指纹映射，以便同一持久会话离线重启后读取自己的正文。另一个账号的正文不会作为回退；仅可回退已知匿名缓存。切换会话时清除内存身份，阻止旧请求覆盖新会话正文。密码、QQ 验证码和原始 Cookie 值不写入应用日志或项目文件。

标签页可新建、切换和关闭，内存中保留阅读器及滚动状态；重启恢复词条列表与导航历史。切换原生首页/搜索标签后仍能恢复词条，词条内部链接继续使用当前导航栈。关闭标签会从所有导航栈移除其阅读器。

本轮已通过：

- 13 项天一数据层测试：9 项原有用例与 4 项账号元数据用例，覆盖 Cookie 域名边界、头像配置和 JSON 转义、非本站/默认头像拒绝，以及缓存身份隔离。
- iPad mini / iPadOS 26.5 的完整 12 项 UI 测试：阅读/收藏/重启、六语言、跨语言、设置切换、彩蛋、离线缓存、横竖屏、底栏查找、评论以及新增的注册入口、标签页和正文评论入口。
- 新增注册入口用例检查实际登录字段、注册隐私确认及另窗政策返回，不代替用户勾选隐私同意；未宣称真实新账号创建通过。
- 匿名评论用例检查加载占位消失，以及服务器实际返回的“您未被允许发表评论。”；账号登录成功不改变服务端对匿名评论的限制。
- Debug 模拟器构建与无签名 iPhoneOS Release 构建。

结果包：`/tmp/tyzx-account-features2.xcresult`、`/tmp/tyzx-account-full-regression.xcresult`；数据测试日志 `/tmp/tyzx-account-data-tests.log`。新增匿名截图：`article-tabs.png`、`website-login.png`、`website-registration-privacy.png`、`live-comments-from-article.png`。六个 README 已同步账号、标签页、评论和缓存说明；104 个界面键的六语言集合一致且非空。

之前记录的未实现账号入口已由本节更新；原生编辑、账号删除、真机、旧系统运行时和 App Store 发布仍未完成。

最终缓存修订后，iPhone 17 Pro / iOS 26.5 完整 scheme 执行 12 项用例，11 项通过，1 项 iPad 专用布局跳过，零失败；结果包 `/tmp/tyzx-account-final-iphone.xcresult`。其中离线首页/彩蛋、收藏重启、标签页和正文评论入口均通过。最终 Release 构建亦通过。另保留 QQ 链接的系统跳转支持，未代用户操作 QQ 验证。

最终 Debug 安装到 iPhone 17 Pro / iOS 26.5 与维护者已登录的 iPhone 18 Pro / iOS 27 后均脱离测试运行器独立启动，进程持续运行；采用覆盖安装，未卸载或清除网站数据。
