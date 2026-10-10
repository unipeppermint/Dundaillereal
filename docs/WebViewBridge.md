# WebView 与 iOS 交互

## 当前 iosapp 接口

每次主页面开始加载时注入 `window.iosapp.postMessage(action, params)`，实现位于 `Config/IOSAppBridge.swift`。当前只接受 `openWindow`，支持对象或 JSON 对象字符串：

```javascript
window.iosapp?.postMessage("openWindow", { url: "https://example.com" });
window.iosapp?.postMessage("openWindow", JSON.stringify({ url: "https://example.com" }));
```

`purchased`、`addtocart`、`addtowishlist` 和 `completeregistration` 已移除，调用会被忽略，不产生 Meta 事件。原有外链、启动地址选择及缓存回退不受本次修改影响。网页来源限制另行整改。

## Meta 安装与激活衡量

使用 Meta 18.0.3 的 FacebookCore。`AppDelegate` 只保存启动参数，不初始化 Meta；仅在 App 活跃且 ATT 明确为 `.authorized` 时，才初始化 SDK、开启 IDFA 采集并调用安装/激活衡量。未选择、拒绝、受限及未知权限状态均不初始化 SDK、不调用激活，不缓存等待授权的网页事件。

`MetaActivationGate` 对连续的授权回调去重。App 失去活跃状态或检测到撤回授权时关闭广告标识符采集。SDK 始终使用 `.explicitOnly` 刷新，只有当前仍为授权且活跃时才显式激活及刷新。自动事件、SKAdNetwork 上报及 AEM 自动设置关闭。恢复授权后仅触发当前激活。iOS 14–16 同步旧版广告追踪设置，iOS 17 及以上由 SDK 读取 ATT。

首次 SDK 初始化前清除旧版 SDK 的待发事件和会话缓存，避免升级后重放已移除的购买等事件。文件名依据锁定的 SDK 18.0.3 实现，仅删除 App Library 中的 `com-facebook-sdk-AppEventsPersistedEvents.json` 和 `com-facebook-sdk-AppEventsTimeSpent.json`，不删除游戏库；清理失败则不初始化 SDK。更新 SDK 时须重新检查这些缓存路径。

通知权限流程仍由 `TrackingAuthorizationCoordinator` 独立继续；拒绝 ATT 不阻止通知授权、原生游戏或网页功能。本次没有更改 Firebase、远程网页的自身脚本或服务器功能。

## 验证与边界

- `sh scripts/test-meta-consent.sh`：验证授权/前台门控、撤回与重新授权、去重、失败关闭、旧队列清理及配置约束。
- `sh scripts/test-iosapp-bridge.sh`：通过 JavaScriptCore 执行注入脚本，验证四种业务事件被拒绝，外链接口仍正常。
- `sh scripts/test-web-bridge.sh`：验证旧外链接口兼容性。

以上测试不向 Meta 发送真实事件。SDK 内部请求可能异步完成，已经发出的网络请求无法通过本地授权门控撤回。发布前仍需用真机抓包和 Meta Events Manager 验证首次拒绝、首次授权、后台撤回授权及升级安装，并核对 Meta 后台的自动事件配置。SDK 回调被调用不等于服务器已确认接收。

## 原有外链接口

页面可通过以下两个等价的方法调用 iOS，在系统默认浏览器中打开网页：

```javascript
window.webkit.messageHandlers.openSafari.postMessage("https://example.com");
window.webkit.messageHandlers.open.postMessage({ url: "https://example.com" });
```

参数支持 URL 字符串，或包含字符串字段 `url`、`href`、`link`、`target` 的对象。对象按上述顺序使用第一个有效链接。

支持 HTTP/HTTPS 链接、`//example.com/path` 和 `example.com/path`；省略协议时补全 HTTPS。忽略空值、无效参数、相对路径、带账号密码的 URL 和其他协议。

这两个方法与参考文件一致，仅提供 JS 调用 iOS 的打开链接动作，没有 JS 返回值或回调。`openSafari` 是兼容名称，实际使用 `UIApplication.shared.open`，浏览器由系统默认设置决定。已有的普通网页导航及 `target="_blank"` 链接继续在应用内 WebView 打开。
