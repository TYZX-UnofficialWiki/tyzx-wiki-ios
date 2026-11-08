# 品牌图片

`tyzxbannerwd.png` 是维护者在本次开发中提供的原始透明 PNG。用于天一维基应用图标及首页字标；本仓库不据此声明拥有校名、书法作品或商标权。公开分发及上架前由维护者确认相关权利。

`Assets.xcassets/AppIcon.appiconset/AppIcon.png` 为 1024×1024、无透明通道的白底图标，完整保留原图比例及两行文字。横向字标在小图标尺寸下可读性有限，这是按要求保留完整原图的结果。

重建命令（仓库根目录）：

```sh
swift TianyiWiki/Scripts/GenerateIcon.swift \
  TianyiWiki/Branding/tyzxbannerwd.png \
  TianyiWiki/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

使用本机 Core Graphics 对原图进行缩放和白底合成，没有使用生成式重绘结果。
