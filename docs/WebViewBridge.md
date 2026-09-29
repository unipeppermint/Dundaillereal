# WebView 与 iOS 交互

页面可通过以下两个等价的方法调用 iOS，在系统默认浏览器中打开网页：

```javascript
window.webkit.messageHandlers.openSafari.postMessage("https://example.com");
window.webkit.messageHandlers.open.postMessage({ url: "https://example.com" });
```

参数支持 URL 字符串，或包含字符串字段 `url`、`href`、`link`、`target` 的对象。对象按上述顺序使用第一个有效链接。

支持 HTTP/HTTPS 链接、`//example.com/path` 和 `example.com/path`；省略协议时补全 HTTPS。忽略空值、无效参数、相对路径、带账号密码的 URL 和其他协议。

这两个方法与参考文件一致，仅提供 JS 调用 iOS 的打开链接动作，没有 JS 返回值或回调。`openSafari` 是兼容名称，实际使用 `UIApplication.shared.open`，浏览器由系统默认设置决定。已有的普通网页导航及 `target="_blank"` 链接继续在应用内 WebView 打开。
