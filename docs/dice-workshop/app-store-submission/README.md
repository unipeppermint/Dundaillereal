# Rollweave: Slot Atelier · App Store 首次提交填写指引

核对日期：2026-09-22。适用对象：当前 iPhone 英文版，版本 1.0，离线骰子桌游及规则工坊。

这是一份提交准备材料，未登录开发者账号、未修改签名配置、未上传构建或提交审核。字段名称可能随账号和地区变化，以实际页面为准。标记“待提供”的内容不能原样提交。

## 1. 提交前先补齐

| 项目 | 当前情况 | 要做的事 |
| --- | --- | --- |
| 隐私政策公开地址 | 2026-09-22 请求返回 HTTP 200，页面包含 Rollweave 隐私政策及正确邮箱 | 打包前在真机确认网页显示；网络检查已完成 |
| 应用内隐私入口 | 已添加 Settings → Privacy Policy，以 SFSafariViewController 打开给定网址 | Release 无签名构建通过；仍需在最终签名包中点击检查 |
| 隐私清单 | 当前文件清单未发现 PrivacyInfo.xcprivacy；源码使用 UserDefaults | 对照 Required Reason API 清单补声明并确认打包进正式构建；用 Xcode 隐私报告及上传验证核对 |
| Support URL | 尚未提供公开支持页 | 准备含 Rollweave: Slot Atelier 完整名称、支持邮箱、基本帮助的网页并发布；不能把邮箱直接填入 URL 字段 |
| 商店截图 | 现有主要截图为 1206×2622 或 750×1334 | 从最终英文版本补拍 6.9 英寸槽位可接受的截图，建议 1320×2868 |
| 真实身份信息 | 未提供 | 填写版权主体、审核联系人姓名和电话；不要从邮箱域名推断公司名称 |
| 上架地区及 DSA | 未确定 | 确定实际发行地区，完成触发的地区合规信息 |
| 构建号 | 当前源码为 1.0 (1)，未核对后台 | 如该构建号已上传，后续按实际情况递增；提交最终通过测试的包 |

苹果要求应用内和 App Store Connect 都提供隐私政策入口。[审核指南](https://developer.apple.com/app-store/review/guidelines/)

Required Reason API 声明与 App Privacy 的“不收集数据”是两回事；只在本地存偏好也需要检查 API 使用理由。不要填写不适用的理由代码。[API 理由文档](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)

## 2. 创建应用记录：My Apps → + → New App

| 字段 | 建议填入 | 说明 |
| --- | --- | --- |
| Platforms | iOS | 当前为 iPhone 应用 |
| Name | Rollweave: Slot Atelier | 已确认的完整名称，共 23 字符；当前桌面显示名为简称 Rollweave |
| Primary Language | English (U.S.) | 当前应用仅声明 en；中文文档不代表支持中文界面 |
| Bundle ID | com.cvcl.Dundaillereal | 必须选与正式包相同的已注册 ID，不要新换一个 ID |
| SKU | rollweave-ios-001 | 新记录的内部编号建议；已有记录继续使用原值 |
| User Access | 按实际团队权限选择 | 与用户是否需要登录无关 |

Apple ID 由后台自动生成。应用名、副标题最多 30 字符。SKU 和 Bundle ID 存在创建或上传后的修改限制，应在创建前确认。[应用信息](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)

## 3. General → App Information

| 字段 | 填写建议 |
| --- | --- |
| Name | Rollweave: Slot Atelier |
| Subtitle | Create & Play Dice Games |
| Primary Category | Games |
| Games Subcategories | Board；第二子类别可选 Family |
| Secondary Category | 可留空 |
| Content Rights | 必须核对插画、音效、字体和代码来源；有第三方内容则按实际情况选 Yes 并确认拥有许可；全部自制且不访问第三方内容时才选 No |
| License Agreement | 使用 Apple 标准 EULA；没有实际需要可不填自定义协议 |
| Made for Kids | 不选；适合家庭不等于专门加入儿童类别 |
| Age Rating | 按下一节逐项回答，由系统计算 |
| Copyright | 在版本页面填写：2026 [实际权利人姓名或法人名称]；提交前替换方括号内容 |

完整应用名称已确认为 Rollweave: Slot Atelier，商店 Name 和正式提交材料使用此名称。Rollweave 可作为正文及 iPhone 桌面显示的简称；当前 CFBundleDisplayName 为 Rollweave，无需因此修改 Bundle ID、签名或工程名称。隐私政策可注明“Rollweave: Slot Atelier（以下简称 Rollweave）”；已发布政策网页由其发布方更新，本次未改动远程页面。

## 4. 年龄分级问卷

以下是根据当前实现作出的建议，不是预先指定分级结果。以最终构建中实际出现的内容回答；不要为了获得低分级而改变事实。

| 项目 | 建议答案 | 原因 |
| --- | --- | --- |
| Parental Controls | No | 没有专门的家长控制 |
| Age Assurance | No | 没有年龄验证 |
| Unrestricted Web Access | No | 无任意网页浏览功能；固定政策链接不等于无限制浏览器 |
| User-Generated Content | No，按当前功能判断 | 仅本地创作和用户主动分享文件，无应用内广泛传播或公共作品流；以后增加社区需重新评估 |
| Social Media | No | 无信息流 |
| Messaging and Chat | No | 无应用内聊天；系统分享不是聊天功能 |
| Advertising | No | 当前无广告 |
| Profanity or Crude Humor | None | 无内置粗俗内容 |
| Horror / Fear Themes | None | 无恐怖内容 |
| Alcohol, Tobacco, Drug Use or References | None | 无相关内容 |
| Medical or Treatment Information | None | 无医疗内容 |
| Health or Wellness Topics | No / None，以控件为准 | 无健康建议 |
| Mature or Suggestive Themes | None | 无相关主题 |
| Sexual Content or Nudity | None | 无相关内容 |
| Graphic Sexual Content and Nudity | None / No，以控件为准 | 无相关内容 |
| Cartoon or Fantasy Violence | None | 无战斗或伤害 |
| Realistic Violence | None | 无相关内容 |
| Prolonged Graphic or Sadistic Realistic Violence | None / No，以控件为准 | 无相关内容 |
| Guns or Other Weapons | None | 无武器 |
| Gambling | No | 没有真钱下注、兑换或奖品支付 |
| Simulated Gambling | None，需核对最终玩法 | 目前仅计分，没有用资金或虚拟筹码下注；Bank or Bust 是累计积分后选择收手 |
| Contests | 建议 Frequent | 多人比较成绩和胜负是主要玩法；苹果定义涵盖为排名或个人目标开展的竞争，并非只有现金赛事 |
| Loot Boxes | No | 无购买随机物品的容器 |
| Age Categories and Override | Not Applicable | 不主动加入 Kids，不强制覆盖更高分级，除非实际年龄限制另有要求 |
| Age Suitability URL（如出现） | 可留空 | 没有独立的年龄适宜性说明页 |

普通投骰不自动等于模拟赌博；反过来，“没有真钱”也不能作为所有赌博类问题都选 No 的依据。请保留纯积分机制，不在描述中虚构下注。最终分级可能因地区和系统版本不同，应记录后台计算结果。[年龄分级定义](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions)

## 5. App Privacy

### 5.1 隐私网址

Privacy Policy URL：

```text
https://doc-hosting.flycricket.io/privacy-policy-for-rollweave/1ff1cb08-c5be-407e-9bd7-a1b48c112b81/privacy
```

Privacy Choices URL 为可选，没有独立管理页面时可留空。

### 5.2 数据申报建议

根据当前源码，没有登录、开发者后端、广告 SDK、遥测 SDK 或主动上传本地对局数据的实现。可按当前事实准备选择：

```text
No, we do not collect data from this app.
```

这是有条件的申报建议：提交前应对最终包及后续新增的政策网页打开方式、第三方组件复核。

- 仅在设备处理的玩家昵称、规则、成绩和设置，不属于苹果标签定义下的离设备收集。
- 用户选择系统分享不等于开发者取得这些内容。
- 支持邮件仍应在隐私政策说明。若后续增加应用内反馈表单或自动上传日志，只有满足苹果全部 optional disclosure 条件才可不在标签披露；否则按实际声明 Email Address / Customer Support 等数据、用途和关联情况。
- 若增加内嵌网页，需核对网页产生的数据收集，不能只检查原生代码。
- 当前没有跨应用跟踪，不因“可能以后加广告”而申报跟踪或弹 ATT。

填写后完成后台的保存／发布步骤，确认不是未发布草稿。[App Privacy 定义与例外](https://developer.apple.com/app-store/app-privacy-details/)

## 6. iOS App 1.0 → Version Information

主要使用 English (U.S.) 本地化。下面已直接列出全部可复制文案，填写时无需打开其他文件；[英文文案纯文本备份](metadata-en.txt)仅供备用。代码块内只包含对应字段的填写内容。

| 字段 | 填写内容或处理 |
| --- | --- |
| Promotional Text | 复制下方 6.2，可选 |
| Description | 必填，复制下方 6.3 的完整英文描述 |
| Keywords | 必填，复制下方 6.4 的逗号分隔行 |
| Support URL | [待提供可公开访问的支持网页] |
| Marketing URL | 可留空 |
| Version | 1.0，与提交构建一致 |
| Copyright | 2026 [实际权利人姓名或法人名称] |
| What's New | 首次版本不需要填写；后续更新才需要 |
| App Clip / iMessage Extension | 当前没有，不配置 |
| Routing App Coverage File | 当前不是导航应用，不适用 |

文案限制：Promotional Text 170 字符；Description 4000 字符；Keywords 100 字节。审核 Notes 上限 4000 字节。支持网址要能让用户找到真实联系方式，不要填占位域名或 mailto 地址。隐私页只有在确实也承担支持用途且可访问时才考虑复用，当前仍建议独立支持页。[版本信息字段](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)

### 6.1 应用名称与副标题

23 / 30 字符。

```text
Rollweave: Slot Atelier
```

#### 副标题（Subtitle）

24 / 30 字符。

```text
Create & Play Dice Games
```

### 6.2 推广文本（Promotional Text，可选）

144 / 170 字符。

```text
Turn a few dice into your next game night. Play three tabletop games, customize their rules, and pass one iPhone around with up to four players.
```

### 6.3 应用描述（Description，必填）

1482 / 4000 字符。

```text
Make a little room for game night.

Rollweave: Slot Atelier brings dice games and a rule workshop to your iPhone. Play solo or take turns with up to four players on the same phone. Choose a game, roll the dice, and let the app handle turns and scoring.

THREE WAYS TO PLAY

Right on Track
Combine your dice to match target stops. Decide where to use each roll and when to spend a limited reroll.

Lucky Pairs
Keep the dice you like and reroll the rest. Build matching pairs to add bonuses to your score.

Bank or Bust
Build your round's points, then decide whether to bank them or roll again. A bust ends the round with zero points.

MAKE THE RULES YOUR OWN

Start from a game template and adjust its supported settings, including rounds, dice, scoring, and rerolls. Check your rules, playtest your changes, and save your own version.

KEEP YOUR GAMES TOGETHER

Save favorite games, view completed game scores, and resume an unfinished game. Export a .dicework file for a friend to import into Rollweave, or share an image explaining your rules.

MADE FOR THE SAME TABLE

Play offline without an account. Multiplayer means taking turns on one iPhone; no online room or remote connection is required. Game sharing uses the services you choose from the system share sheet.

Enjoy illustrated game boards, animated dice, and optional sound and haptic feedback. Games, scores, and preferences are stored on your device. No ads or in-app purchases.

Support: paigeh@kirkmanlogistics.pics
```

### 6.4 关键词（Keywords，必填）

86 / 100 字节。

```text
dice,board,tabletop,offline,local,multiplayer,rules,creator,score,turns,pairs,strategy
```

### 6.5 网址、版本与版权

隐私政策 URL（填写在 App Privacy 对应字段）：

```text
https://doc-hosting.flycricket.io/privacy-policy-for-rollweave/1ff1cb08-c5be-407e-9bd7-a1b48c112b81/privacy
```

- **Support URL：待提供。** 必须是公开支持网页，不能填写邮箱地址。
- **Marketing URL：** 可留空。
- **Version：** `1.0`，与最终提交包保持一致。
- **Copyright：** `2026 [实际权利人姓名或法人名称]`，必须替换占位内容；不是应用名称或联系邮箱。
- **What’s New：** 当前是首次版本，不需要填写。

## 7. 截图与视频

建议准备 6 张最终英文界面截图：

| 顺序 | 画面 | 可选英文短标题 |
| --- | --- | --- |
| 1 | Games 首页与三种玩法 | A Little Tabletop Adventure |
| 2 | Right on Track 实际对局 | Make Every Roll Count |
| 3 | Rule Workshop 参数编辑 | Make the Rules Your Own |
| 4 | Lucky Pairs 对局 | Keep a Pair. Try Your Luck. |
| 5 | Bank or Bust 对局 | Roll Again or Bank Your Points |
| 6 | 作品详情、分享或成绩记录 | Save, Share, Play Again |

上传真实应用画面，可加准确说明和排版。不要提交四屏概念图或已作废的 HTML 原型作为应用实际截图，也不要宣称远程多人。

当前官方 iPhone 6.9 英寸槽位接受的竖图包括 1260×2736、1290×2796、1320×2868。建议统一 1320×2868；若使用 6.5 英寸替代槽位，遵循后台相应规格。每种支持的槽位可上传 1–10 张 JPG/PNG，不带透明通道。当前工程仅面向 iPhone，不需要为未支持的平台伪造截图。现有 1206×2622 截图不能直接代替最大必需槽位。

App Preview 视频可不上传，首版无需为提交额外制作。App Icon 由正式包提供；项目图片已确认 1024×1024，但仍应检查最终资源编译和透明通道。[截图规格](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

## 8. Build 与加密出口合规

| 项目 | 当前值／操作 |
| --- | --- |
| Bundle ID | com.cvcl.Dundaillereal |
| Version / Build | 源码当前 1.0 / 1，后台是否上传未知 |
| 最低系统 | App Target iOS 16.0 |
| 设备 | iPhone |
| Build 选择 | 等上传和处理完成，选择最终验证包，不选旧的测试包 |
| IDFA 问题（如出现） | 当前不使用广告标识符 |
| Game Center | 当前未实现，不启用排行榜或成就配置 |

当前未发现自有加密算法，也未发现 ITSAppUsesNonExemptEncryption 设置。应对最终包完成加密问卷；无非豁免加密时通常可声明 ITSAppUsesNonExemptEncryption = NO。该值表示“无非豁免加密”，不能把它理解成所有“是否使用加密”问题都选 No。若只有系统加密功能，按该功能对应选项回答；未来新增加密库需重新判断。[出口合规概览](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance)、[系统加密与豁免说明](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations)

用 Xcode Archive 的 Validate App 和上传处理结果检查正式包。此文档没有执行 Archive 或证明当前包已可提交。

## 9. App Review Information

| 字段 | 填写内容 |
| --- | --- |
| Sign-in required | 不勾选 |
| Username / Password | 留空，无账号系统 |
| First Name | [审核联系人真实名] |
| Last Name | [审核联系人真实姓] |
| Phone Number | [可联系的号码，含 + 和国家／地区代码] |
| Email | paigeh@kirkmanlogistics.pics |
| Notes | 复制本节下方完整英文审核备注 |
| Attachment | 可选：简短操作录像或测试 .dicework 文件；不要上传隐私资料 |

邮箱必须有人接收审核沟通。备注按当前实际英文按钮组织，包含开局、规则改编和导入的路径，不写“保证过审”“市场唯一”等无法证实的说法。提交前用最终包按备注走一遍，尤其是 Save Game 后的页面跳转。

### 9.1 审核备注（Notes，可直接复制）

2169 / 4000 字节，仅向审核团队显示。

```text
Rollweave: Slot Atelier (Rollweave) is an offline dice tabletop app with three built-in games and a template-based rule workshop. No account, sign-in, subscription, in-app purchase, or special hardware is required. It supports 1-4 players taking turns on the same iPhone, not remote multiplayer.

The main workflow is to play a game, customize its rules, playtest the result, and save or export that game. The app manages turns, validates supported rule settings, and explains scoring.

Suggested review steps:

1. Open Games and select Right on Track. Tap Start Game, choose the number of players, and tap Begin. Roll the dice, select dice and an available target stop, then tap Confirm Stop. Continue through the turn summary to the next turn.

2. In Workshop, tap Create from Right on Track. Change a scoring or reroll setting and tap Playtest Rules. Playtests use the edited rules without replacing a saved regular game. Return to the editor and tap Save Game to keep the custom game.

3. Open the saved game from Workshop. Tap Share Game to export a .dicework file through the iOS share sheet. Save it to Files, then return to Workshop and choose Import a .dicework File. Select the file, review the preview, and tap Import Game. Sharing a rules image is also available from game details.

4. Try Lucky Pairs and Bank or Bust from Games. Lucky Pairs supports keeping selected dice and rerolling the others. Bank or Bust lets the player bank accumulated round points or risk another roll.

5. For a regular game, make a move and leave the app. Reopen it and use Resume Game on Games to continue. Completed regular games are shown in Collection. Rule playtests are not added to game history.

All gameplay is available offline. Game rules, player names, progress, and scores are stored locally. Files are shared only when the user selects a system sharing destination.

Scores are game points only. There are no wagers, purchased chips, cash prizes, cash-out features, loot boxes, or gambling services.

Privacy policy:
https://doc-hosting.flycricket.io/privacy-policy-for-rollweave/1ff1cb08-c5be-407e-9bd7-a1b48c112b81/privacy

Contact: paigeh@kirkmanlogistics.pics
```

[审核备注纯文本备份](review-notes-en.txt)。

## 10. Pricing and Availability

| 项目 | 建议 |
| --- | --- |
| Price | Free，与当前所有核心功能免费的实现一致 |
| Tax Category | 当前可保留 App Store software；按实际业务核对 |
| Distribution | 公开 App Store 分发，不选择企业私有 Custom App |
| Pre-Order | 首版不启用 |
| Countries or Regions | 待你确定；不要未经核对直接选择全部地区 |
| iPhone Apps on Apple Silicon Mac | 建议在未进行 Mac 验证前关闭可用性 |
| Apple Vision Pro availability（如出现） | 未适配验证前不主动开放 |
| Volume distribution / educational discount | 按实际发行需要选择；免费应用无需宣传折扣 |
| Last-Compatible Version | 首次版本无历史包，保持默认即可 |

当前未实现 IAP、订阅和付费解锁，无需创建内购商品、订阅组、服务器通知地址或订阅审核资料。将来收费时再按实际实现配置。

定价必须在提交前完成；税务类别按实际产品而非营销名称确定。[定价](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price)、[税务类别](https://developer.apple.com/help/app-store-connect/manage-app-information/set-a-tax-category)、[可用性](https://developer.apple.com/help/app-store-connect/reference/pricing-and-availability/app-pricing-and-availability)

## 11. 地区与账号层面的条件信息

- 欧盟：按实际经营身份完成 DSA Trader 声明，免费或个人开发者身份并不自动等于 Non-trader。Trader 需要核验联系信息；个人可能需要地址或邮政信箱、电话、邮箱，相关信息会公开。不要为了隐藏地址而选择不符合事实的身份。[DSA 指引](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/)
- 中国大陆：这是 Games 类应用，需核对游戏审批及相关备案要求；无适用资质时不要假设单机免费即可发行，也不要改成工具分类绕过要求。
- 韩国、越南等：若后台针对游戏、组织账号或当地发行显示登记和资质字段，按对应要求提供真实材料；无法满足时先不开放相应地区。
- 协议、税务、银行信息：在 Business 检查账号实际待办，由账号持有人处理。不要将虚构身份或支付信息写入字段。
- Medical Device 等声明：当前无医疗功能或分类，不适用。

地区字段以账号中显示的要求及苹果当前地区指引为准。[应用及地区信息](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)

## 12. App Accessibility（可选申报）

目前代码包含 Dynamic Type、VoiceOver 描述和减少动态效果处理，但“有代码”不等于所有主要流程达到标签标准。实际验证后再声明 VoiceOver、Larger Text、Reduced Motion 等支持。未逐项验证的 Dark Interface、Voice Control、Sufficient Contrast 等不要直接勾选；Accessibility URL 没有独立页面时可留空。

应覆盖开局、投骰、选择站点、计分、编辑与导入等完整功能，而非只检查首页。[可访问性标签](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels)

## 13. 发布方式与正式提交

建议选择 Manually release this version，审核通过后自己确认上线时间。首次版本不需要更新分阶段发布。若选择自动或指定时间发布，确认时区和实际发布日期。

填写顺序：

1. 确认账号协议、应用记录及发行地区。
2. 完成应用内政策入口、隐私清单及最终包验证。
3. 上传构建并等待处理，处理加密问卷或 Missing Compliance。
4. 填 App Information、年龄分级、App Privacy，完成必要发布操作。
5. 填版本文案、截图、支持 URL、版权、审核联系人及备注。
6. 选择最终 Build、价格和发布方式。
7. 点击 Add for Review，将版本加入提交草稿。
8. 到提交草稿／App Review 页面点击 Submit for Review；只点 Add for Review 不算已经送审。
9. 确认状态进入 Waiting for Review，并关注审核消息。

[苹果正式提交步骤](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)

## 14. 最终逐项核对

- [ ] Rollweave: Slot Atelier 商店名称与已确认名称一致且后台可用，版本和 Bundle ID 与包一致。
- [ ] 所有 [待提供] 与方括号占位内容已替换。
- [ ] 支持网页、政策网页公开可访问，邮箱正确。
- [ ] 应用内能打开政策；隐私清单已包含在最终包。
- [ ] App Privacy 与最终代码、网页行为、第三方依赖相符。
- [ ] 年龄问卷按事实填写，特别复核 Contests 与 Simulated Gambling。
- [ ] 图片和音效权利已核对，截图来自最终英文应用。
- [ ] 6.9 或适用的最大必需截图槽位完整，图标通过校验。
- [ ] 断网、重启恢复、三个玩法、1–4 人、编辑、导入导出均验证。
- [ ] 文案不包含尚未实现的联机、云同步、中文支持、订阅或 AI 功能。
- [ ] 审核联系人真实有效，电话号码含国家／地区代码。
- [ ] 地区、DSA、定价、版权、合规问卷完成。
- [ ] 已点击 Submit for Review，后台显示实际送审状态。

## 15. 仍需你提供／决定

1. 版权归属的个人姓名或公司法定名称。
2. 审核联系人的姓名和联系电话。
3. Support URL（支持网页发布后的地址）。
4. 发行国家／地区及真实 DSA 身份。
5. 如后台已有应用记录，将 Name 与已确认名称 Rollweave: Slot Atelier 对齐，无需重新决定名称。
6. 确认首版免费及手动发布，或给出实际偏好。

本指引依据当前源码和苹果官方文档整理，不等于已完成账号内检查或得到审核保证。

## 隐私入口补充记录（2026-09-22）

- 已添加 Settings → Privacy Policy，支持辅助功能标签和联网提示；关闭系统浏览器即可返回设置。
- 已将设置中的“无在线服务”说明调整为“核心游戏离线可用”，避免与打开政策网页混淆。
- 真机目标 Release 构建成功（CODE_SIGNING_ALLOWED=NO），未执行签名归档、上传或真机 UI 点击验证。
- 政策网址 HTTP 200，响应中包含政策标题、Rollweave 和 paigeh@kirkmanlogistics.pics。
- 托管网页源码包含 Google Analytics 初始化脚本；这是网页托管方的行为，不是应用中加入分析 SDK。提交 App Privacy 前仍需核对该网页实际收集及适用披露，不能只按原生离线代码判断。
- 未更改 Bundle ID、签名团队、版本号或发布配置。
