# 正式产品内容检查

本轮修复面向用户的占位感与不一致内容，不对素材是否能被判定为 AI 生成作保证。保留真实素材来源及授权记录。

## 修改

- 移除幸运与冒险玩法中无可配置内容的特殊奖励卡；补充正确计分摘要。
- 各玩法使用对应封面，限制封面标题为两行并允许缩小，降低长名称遮挡。
- 非到站玩法不再显示无意义的精准次数。
- 人数、时间、离线与玩家标记统一用系统图标；空状态与投骰提示采用明确操作说明。
- 规则试玩保留为编辑器功能，明确提示本局不保存成绩。版本从应用配置读取。
- 校正两张插图中的骰面点数，移除空白路牌，保持已有配色与构图。

## 素材

使用内置 imagegen 编辑，非 CLI。最终保存路径与完整提示词：

### LuckyArt

[最终素材](../../Dundaillereal/Assets.xcassets/LuckyArt.imageset/LuckyArt.png)

Edit the supplied gouache illustration precisely. Keep all layout, clover, landscape, paper texture, colors and empty top unchanged. Correct ONLY the ivory die pips: top face exactly three pips, front/left visible face exactly one centered pip, right visible face exactly two diagonal pips. Standard coherent cube geometry, clean circular dark recessed dots. No text or extra objects.

### RiskArt

[最终素材](../../Dundaillereal/Assets.xcassets/RiskArt.imageset/RiskArt.png)

Edit the supplied gouache illustration precisely. Keep the layout, forest landscape, paper texture, palette, empty upper area and ivory die shape unchanged. Correct die pips: top exactly four arranged in a square, left/front visible face exactly one centered pip, right visible face exactly two diagonal pips. No repeated face values. Remove the blank wooden arrow sign completely and naturally fill that area with the existing forest and hillside. No text, no new objects.


## 验证与边界

- iPhone 17 Pro 原有三项 UI 流程通过；iPhone SE 新增两种非到站玩法展示专项通过，共 4 项、0 失败。
- Release 未签名归档成功；检查包内容不含 docs、原型、提示词或测试文件，Release 主程序未发现测试启动参数。
- [见好就收详情](assets/product-polish/template-detail-见好就收.png)、[规则编辑](assets/product-polish/template-editor-见好就收.png)、[留点好运详情](assets/product-polish/template-detail-留点好运.png)、[规则编辑](assets/product-polish/template-editor-留点好运.png)。
- 没有发现面向用户的 Demo/Beta/敬请期待入口。正常输入框 placeholder 与规则试玩属于实际功能，保留。
- 图像仍为 AI 辅助制作；本次修正可核实的视觉错误，不承诺绕过识别或保证审核结果。素材来源和音频授权保留。
- 上轮发现的隐私清单、隐私政策和真机发布验证仍需独立完成。

最后补齐展开说明内边距后，SE 两种玩法专项再次通过，最终 Release 未签名归档再次成功。
