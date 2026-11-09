# 阅读底栏来源

移植上游 `wikimedia/wikipedia-ios` 的 `Wikipedia/Code/ArticleToolbarController.swift`（`update()` 的 iOS 26 与旧系统排列）及 `IconBarButtonItem.swift` 的 UIButton/customView 构造方式；原文件保留在本仓库。上游基线为 `0b9980f19f5307f82d072298c3624e568bc1c6be`，沿用根目录 MIT 许可证与 Wikimedia 作者声明。

`TianyiWiki/Assets.xcassets/` 下 `toc`、`language`、`save`、`save-filled`、`find-in-page`、`font-size` 六个 imageset 逐字节复制自 `Wikipedia/Images.xcassets/`，没有重新绘制。更多图标沿用上游的 SF Symbol ellipsis/light。

天一适配为 `TianyiArticleToolbar.swift`：保留 UIToolbar、按钮顺序、灵活空白与系统分组，替换依赖 Wikipedia 数据模型的动作、主题接口和菜单文案。评论与分享放入更多菜单；未接入的编辑/监视列表功能不生成空按钮。词条内查找使用本地 WebKit 的原生查找导航器。
