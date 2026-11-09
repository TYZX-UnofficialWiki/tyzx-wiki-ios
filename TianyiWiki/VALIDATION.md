# 验证记录

最新 iPad 专项验收：2026-11-09，见文末。以下保留此前版本记录。

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
