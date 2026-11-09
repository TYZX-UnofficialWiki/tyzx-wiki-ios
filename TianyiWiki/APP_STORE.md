# App Store 发布评估

评估日期：2026-11-08。结论：**可以朝 App Store 发布开发，但当前开发版不具备直接送审条件，不能保证审核通过。** fork、代码许可、开发者资格、内容运营和中国大陆发行是不同事项。

## 代码和产品定位

上游采用 MIT 许可，允许修改与分发，须保留版权及许可。[上游 LICENSE](https://github.com/wikimedia/wikipedia-ios/blob/main/LICENSE.txt) 已保留并随天一应用打包。

软件许可不授予 Wikimedia 商标使用权。天一版使用自己的名称和维护者提供的字标，明确非学校官方、非 Wikimedia 官方；仍须确认校名及书法字标的使用权。正文和照片的署名与授权也应分别核验。[Wikimedia 商标政策](https://foundation.wikimedia.org/wiki/Policy:Trademark_policy)

目前采用独立校园内容、原生搜索、目录、字号与离线正文，具有独立使用场景。判断：这比仅更换名字和图标更有送审依据，但仍需真机完善体验。Apple 4.1、4.2 要求避免仿冒并提供超出网站封装的实用性。[审核指南](https://developer.apple.com/app-store/review/guidelines/)

## 送审前缺口

| 事项 | 当前状态及应完成的工作 |
| --- | --- |
| 内容治理 | 校园维基具有用户投稿内容。按 1.2 补齐有效的内容过滤、举报、处理响应、滥用用户处置和公开联系渠道；特别检查涉及师生个人信息及校园欺凌的内容。仅链接 GitHub 不等于已建立处理机制。 |
| 账号管理 | 已接入应用内网站注册、登录、退出和头像读取，编辑仍非原生。不能用“在网页注册”规避删除账号要求；开放相关流程前，应实现应用内发起删除及服务端处理，说明投稿和历史数据处理方式。 |
| 隐私与支持 | 核验隐私页面真实有效，发布 App 专用说明和支持渠道；按实际服务器日志、网页与媒体行为申报。当前隐私清单只是客户端 API 声明，不能代替隐私政策。 |
| 审核材料 | 使用真实截图、合适内容分级、准确的非官方简介；按需要提供审核账号和说明。不要把面向中学生直接等同于 Apple 的 Kids Category。 |
| 稳定性 | 真机检查离线模式、图片、目录、外链、字号、弱网、iPad，以及兼容网页的登录编辑。推送和远端同步尚未接入。 |

账号创建功能要求允许从应用内发起删除；链接浏览器注册也仍适用。具体数据删除方案需要与站点运营方落实，不能把普通封禁或改名冒充注销。[Apple 账号删除说明](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion)

## 开发者账号

发布需加入 Apple Developer Program。当前官方标准为每年 99 美元，地区币种与价格以注册界面为准。个人注册要求达到当地法定成年年龄，商店销售者显示本人法定姓名。GitHub 组织本身不等于可注册 Apple 组织账号的法律实体；组织账号需满足实体及验证条件，通常包括 D-U-N-S。[计划注册](https://developer.apple.com/programs/enroll/)、[个人资格与销售者名称](https://developer.apple.com/help/account/membership/program-enrollment)

本次没有代付会员费、注册 Apple 账号、创建商店条目或提交审核。

## 中国大陆与其他地区

若面向中国大陆提供服务，应核实并办理适用的 APP 备案，不能根据网站域名或 GitHub 仓库认定已经具备 APP 备案。备案主体、网络资源及服务内容应与真实情况一致。[工信部 APP 备案通知](https://www.miit.gov.cn/jgsj/xgj/wjfb/art/2023/art_dd783a581c9644a4aee10afa582811db.html)

Apple 要求适用的备案信息与工信部备案及商店元数据相符；新闻、网络出版等特定内容可能另有材料要求。普通校园知识条目是否涉及特定许可，需要根据实际运营与主管部门要求确定，不能凭“维基”名称判断。[Apple 中国大陆发行材料说明](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)

建议先完成上述产品与运营缺口，再通过 TestFlight 做实际验收，最后按符合要求的地区申请发行。选择其他地区不自动豁免面向大陆提供服务时适用的规定。

## Bad Apple!! 彩蛋的额外核验

客户端为该词条保留应用内音频播放及本机缓存的动画帧能力，首次联网下载到设备缓存，不把音乐或动画帧直接打包进 IPA。音乐和影绘素材的分发权不由本仓库 MIT 代码许可或词条正文许可自动授予。本次未取得这些素材的 App Store 分发授权证明；发布前应确认实际使用方式和相应权利，并按审核规则提供说明。功能测试通过不代表版权审核已经完成。[Apple 知识产权要求（5.2）](https://developer.apple.com/app-store/review/guidelines/#intellectual-property)
