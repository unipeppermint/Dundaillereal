# 视觉升级 · 2026-09-21

本轮沿用奶油白、墨蓝、珊瑚橙与鼠尾草绿，加入四张原创插画；素材使用内置 image_gen 生成，最终文件已复制到 Asset Catalog，应用不依赖生成目录或网络。

## 页面变化

- 游戏桌：完整插画主卡、两张并排玩法小卡、纸质边框和投影、创作入口。
- 对局：山谷底图与动态弯曲路线分层，圆形站点、当前玩家卡片、象牙色骰子与点数凹印感、投骰托盘；真实点数始终由引擎绘制。
- 工坊：带图标的纸质参数模块、说明卡与校验区，保留键盘跟随、大字体与原有有效性校验。
- 详情：使用封面卡片组织作品信息；规则内容使用独立纸卡，分享规则图片也加入作品插画。
- 收藏柜：统一卡片、空状态与视觉层级。

没有把原型截图作为可点击页面，也没有修改规则引擎、数据格式、Bundle ID 或签名配置。插画中的装饰骰子只用于《留点好运》封面，不参与任何实际对局。

## 最终资源与生成提示词

工具：内置 `image_gen`，没有使用 API/CLI fallback。提示词如下（生成后原图直接复制，不裁改源文件）：

### StationArt.imageset/StationArt.png

Use case: illustration-story. Create a premium original hand-painted gouache illustration for an iOS paper boardgame app called Dice Workshop. Landscape 3:2 composition. A charming tiny coral-orange vintage train crosses a stone viaduct in a lush sage-green valley, a small navy-roofed rural station, rolling misty mountains, meandering turquoise stream, clusters of pine trees and shrubs. Warm ivory paper background #F7F3E9, ink navy #20354A accents, muted sage, coral #ED785E. Tactile paper grain, delicate ink details, sophisticated printed European/Japanese boardgame box art, cozy natural daylight. Rich detailed miniature scenery, not flat geometric vector. Full bleed artwork with softly fading ivory sky at top 20 percent. No text, no lettering, no numbers, no dice, no UI, no borders. This is a reusable landscape illustration, not an app screenshot.

### BoardArt.imageset/BoardArt.png

Use case: illustration-story. A portrait 2:3 gouache illustration background for a cozy paper boardgame, no UI. A winding open pale cream meadow in the center taking 65% of the canvas, framed by tiny sage-green trees, pine forests, distant muted blue mountains at the very top, a turquoise stream along the left edge and a small navy-roofed rural railway station at bottom right with a tiny coral train. The center meadow must stay light and quiet, with no paths, rails, numbers or symbols: real interactive route and station circles will be overlaid later. Hand-painted premium printed boardgame illustration, delicate ink detail, warm ivory textured paper #F7F3E9, navy #20354A, sage, restrained coral #ED785E. No text, no labels, no dice, no borders. A real scenic asset, not a screenshot.

### LuckyArt.imageset/LuckyArt.png

Use case: illustration-story. Square premium gouache boardgame cover illustration: a lush cluster of four-leaf clovers beside a small cream canvas pouch on an old ivory picnic cloth, two beautiful ivory six-sided dice in foreground showing accurately five black pips on the top of one and three black pips on the top of the other, delicate small coral wildflowers, distant quiet sage hills. Cozy tactile printed paper, fine ink details, warm ivory #F7F3E9 background, muted sage greens, ink navy shadows, restrained coral-orange. Main objects centered in lower two thirds, pale quiet upper quarter for later UI heading. Sophisticated hand-painted storybook, not vector, no casino, no text, no letters, no numbers, no UI, no border.

### RiskArt.imageset/RiskArt.png

Use case: illustration-story. Square premium hand-painted gouache boardgame illustration. A small coral-orange hiking backpack beside an unlettered wooden trail sign at a fork in a mountain footpath, one path leading toward a cozy navy-roofed cabin, the other toward distant misty peaks. Sage green pines and golden grasses, a peaceful turquoise valley, warm ivory paper #F7F3E9, dark ink navy, restrained coral. Tactile printed paper texture, delicate ink drawing details, cozy adventurous mood. Main backpack foreground lower right, top quarter soft cream sky left quiet for UI titles. No people, no text or letters, no numbers, no dice, no UI, no border. Cohesive premium illustrated tabletop game cover, not flat vector.

以上路径均相对于 `Dundaillereal/Assets.xcassets/`。

## 本轮验证

- Xcode 26.6、iOS 26.5：Debug 模拟器构建通过。
- iPhone 17 Pro：正式开局→重启恢复→六轮结算，以及改编→保存→试玩→作品库，两条 UI 流程通过，0 失败。
- iPhone SE 第 3 代：同样两条 UI 流程通过，0 失败。
- 最大辅助功能字号：首页标题与封面信息已截图检查，可完整换行；该检查不等于全应用旁白验证。
- 检查并修正了骰子圆角绘制；主操作固定于安全区底部。第一次编辑测试因输入框滚到导航栏边缘未获得焦点，调整测试定位后重跑通过。
- 新图片合计约 12 MB（原始 PNG）；已收入资产编译，无运行时下载。
- 真机/iOS 16 运行时未在本轮覆盖。规则引擎与存档格式未改变。

## 实际运行截图

- [游戏桌](assets/visual-v2/visual-home.png)
- [动态棋盘与骰子](assets/visual-v2/visual-board.png)
- [规则工坊](assets/visual-v2/visual-editor.png)
- [玩法详情](assets/visual-v2/visual-detail.png)

截图来自真实 UIKit 模拟器运行，不是生成的 UI 概念图。
