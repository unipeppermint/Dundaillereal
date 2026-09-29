# WebView 与 iOS 交互

## 文档规定的 iosapp 接口

每次主页面开始加载时注入 `window.iosapp.postMessage(action, params)`，实现位于 `Config/IOSAppBridge.swift`。现有启动接口和缓存回退逻辑负责选择网页地址，没有额外的测试链接配置。

```javascript
window.iosapp?.postMessage("openWindow", JSON.stringify({ url: "https://example.com" }));
window.iosapp?.postMessage("purchased", { value: 99.9, currency: "USD" });
window.iosapp?.postMessage("addtocart", { value: 19, currency: "USD" });
window.iosapp?.postMessage("addtowishlist", { value: 19, currency: "USD" });
window.iosapp?.postMessage("completeregistration", {});
```

所有 action 均兼容对象或 JSON 对象字符串作为 params。`openWindow` 使用系统浏览器打开 HTTP/HTTPS 地址。主页面以外的 iframe 不注入本接口，也不接受其发送的事件。

购买、加购和愿望清单事件要求有限且非负的 Number 类型 `value` 和有效 ISO 4217 `currency`。币种自动去除首尾空白并转成大写；布尔值、数字字符串、非法 JSON、未知事件和非网页协议不处理。注册事件兼容无金额参数；若传入金额或币种，则须同时提供完整且有效的一对参数。业务金额单位由 H5 按实际币种金额传入，原生端不会自动按分/元换算。

Meta 映射为 `logPurchase`、`addedToCart`、`addedToWishlist`、`completedRegistration`。协议中的 `completeregistration` 保留原拼写，原生 SDK 使用正确的事件常量。只上报金额与币种，其他字段（包括 uid、phone、email、cid、domain）不会自动加入事件或拼接到 URL。

本接口没有异步返回值。H5 应在业务实际成功时上报一次，页面重载或按钮点击不应重复触发购买/注册。文档没有订单 ID，因此原生端不会按金额去重，以免误删同金额的真实购买。

## Meta 初始化与归因

采用支持 iOS 14 的 Meta 18.0.3，依赖产品仅引入 FacebookCore（包含 CoreKit、AEMKit）。App ID、Client Token 已按对接文档写入 Info.plist。初始化与事件分发位于 `Config/MetaAppEventsManager.swift`，并已转发 Scene 的 Facebook URL 回调。

设置了 ATT 用途说明。`TrackingAuthorizationCoordinator` 在应用进入前台后等待 0.5 秒，先请求 ATT，回调结束后再等待 0.5 秒请求通知权限；拒绝 ATT 也会继续通知授权流程。Firebase 初始化阶段只注册 APNs，不弹通知授权框。仅授权后开启广告 ID 采集。iOS 14–16 同步 SDK 的广告追踪状态，iOS 17 及以上由 SDK 读取 ATT。用户拒绝时不启用 IDFA，按 SDK 的非授权状态上报事件，不使用手机号/邮箱等替代追踪标识。

等待 ATT 结果期间，最多暂存在内存中 100 个事件，随后转交 SDK；超出上限会记录诊断日志，进程退出不会保留这部分队列。自动事件记录关闭，应用激活和 H5 业务事件由代码显式上报，避免自动购买记录造成重复。启用 SDK 的 SKAdNetwork 上报支持。投放方仍须在 Meta 后台配置对应 iOS 应用、最终 Bundle ID、商店信息及投放/转化事件。

`Queued Meta event` 日志仅表示事件已交给 SDK，不表示服务器确认接收。提交前仍需通过真实 H5 业务和 Meta Events Manager 验证安装/激活、四类事件及金额币种。客户端不会伪造购买来验证线上投放账户。

## 本地验证

`sh scripts/test-iosapp-bridge.sh` 使用 JavaScriptCore 执行实际注入脚本，并验证两种参数形式、四类事件、外链和无效参数，不向 Meta 发送事件。`test-launch.sh`、`test-web-bridge.sh` 和 `test-core.sh` 分别覆盖启动回退、旧桥接及游戏核心逻辑。

最低部署版本为 iOS 14.0。iOS 14 使用传统 UIButton 样式、DateFormatter、回调式 URLSession 和键盘通知布局；iOS 15 及以上保留现有按钮样式和键盘布局。Firebase 选择 11.15.0 以支持 iOS 14，APNs 仍固定生产环境。

## 原有外链接口

页面可通过以下两个等价的方法调用 iOS，在系统默认浏览器中打开网页：

```javascript
window.webkit.messageHandlers.openSafari.postMessage("https://example.com");
window.webkit.messageHandlers.open.postMessage({ url: "https://example.com" });
```

参数支持 URL 字符串，或包含字符串字段 `url`、`href`、`link`、`target` 的对象。对象按上述顺序使用第一个有效链接。

支持 HTTP/HTTPS 链接、`//example.com/path` 和 `example.com/path`；省略协议时补全 HTTPS。忽略空值、无效参数、相对路径、带账号密码的 URL 和其他协议。

这两个方法与参考文件一致，仅提供 JS 调用 iOS 的打开链接动作，没有 JS 返回值或回调。`openSafari` 是兼容名称，实际使用 `UIApplication.shared.open`，浏览器由系统默认设置决定。已有的普通网页导航及 `target="_blank"` 链接继续在应用内 WebView 打开。
