# 验证记录

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
