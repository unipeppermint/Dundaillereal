# Firebase 推送

客户端通过 Swift Package Manager 引入 FirebaseCore 和 FirebaseMessaging 11.15.0，以兼容应用最低 iOS 14.0（Firebase 12 要求 iOS 15）。推送逻辑位于 `Dundaillereal/Config/FirebasePushManager.swift`，使用系统 UserNotifications 和 APNs，关闭 Firebase AppDelegate swizzling 并显式转发回调。

## 补充配置

1. 当前 `GoogleService-Info.plist` 的 Bundle ID 为 `com.benll.lyjmkn`。按项目约定，由维护者在正式打包前手动将项目 Bundle ID 与其保持一致；客户端不因当前暂时不一致而跳过初始化。
2. `GoogleService-Info.plist` 已放进 `Dundaillereal/Config/`，通过 Xcode 同步目录纳入应用资源。不要重复添加同名文件。
3. 在 Firebase Console → 项目设置 → Cloud Messaging 中配置对应 Apple 开发者团队的 APNs Authentication Key、Key ID 和 Team ID。APNs 私钥不应加入客户端工程。
4. 使用原有开发者团队签名，确认 Apple Developer 的 App ID 已启用 Push Notifications，签名描述文件包含此能力。工程已添加 Push Notifications、Background Modes / Remote notifications 和推送 entitlements；没有修改 Bundle ID、签名团队或签名方式。

配置文件缺失或无法解析时，会记录诊断日志并跳过 Firebase 初始化。Bundle ID 的一致性在正式打包前处理；忽略当前不一致不代表 Firebase/APNs 可以跨 Bundle ID 正常投递。

项目仅适配正式推送环境。Debug 和 Release 共用 `Config/PushNotifications.entitlements`，其中 `aps-environment` 固定为 `production`。Firebase 通过 `setAPNSToken(_:type: .prod)` 绑定生产 APNs Token，不设置开发/沙盒环境分支，也不向日志输出 Token。

Archive 使用现有的 Release 配置。分发签名的 provisioning profile 必须支持生产推送；最终应以导出 App 的签名权限为准，不能仅凭源码配置判断。导出后可以运行 `sh scripts/verify-production-push.sh /完整路径/应用.ipa` 核对生产推送权限、签名和 Firebase Bundle ID 一致性。该检查不会修改签名或上传应用。

## 当前行为

- 启动后请求通知授权，并注册 APNs；拒绝显示通知的权限不会影响应用原有页面。
- APNs 注册成功后设置 Firebase 的 APNs Token，再获取 FCM Token；后续自动监听 Token 变化。
- 前台通知展示横幅、通知中心列表、声音和角标；后台普通通知由系统展示。
- 通知点击支持运行中和冷启动，保留最后一次点击的 payload，并在主线程发布应用内事件。当前点击后进入正常启动流程，没有约定的推送链接跳转规则。
- 静默通知转发 payload 后返回 `.noData`，没有额外的后台拉取任务。系统不保证静默通知投递。

## 应用内接入点

```swift
// 当前进程获取的 Token；未完成 Firebase/APNs 注册时可能为 nil。
let token = FirebasePushManager.shared.fcmToken

// 冷启动时事件可能早于页面监听器创建，可读取保留的点击 payload。
let payload = FirebasePushManager.shared.lastOpenedNotification
```

可以在主线程监听以下 NotificationCenter 事件：

| 事件 | userInfo |
| --- | --- |
| `FirebasePushManager.tokenDidChange` | `token`: FCM Token 字符串 |
| `FirebasePushManager.notificationReceived` | 原始推送 payload |
| `FirebasePushManager.notificationOpened` | 用户点击的原始推送 payload |

Token 保存在内存中，每次启动和更新时由 Firebase 获取，不把历史 Token 当成永久标识。目前没有提供业务服务端 Token 注册接口，因此没有自动上传 Token，也没有向 WebView 注入 Token。后续服务端应监听 Token 事件并完成账号绑定、更新与退出登录解绑。

## 正式包验证

1. 完成 Bundle ID、APNs 生产环境密钥和分发签名配置后，通过 TestFlight 或正式分发包安装，并允许通知。
2. 从应用内 `FirebasePushManager.shared.fcmToken` 或 `tokenDidChange` 回调获取 Token，用于服务端绑定或 Firebase Console 定向验证。客户端不向日志输出 Token。
3. 分别验证前台展示、后台接收后点击，以及应用未运行时点击通知冷启动。
4. 未完成最终分发签名和 APNs 配置前，Release 编译成功不等于已验证生产推送送达。

参考：[Firebase Apple 项目设置](https://firebase.google.com/docs/ios/setup)、[FCM Apple 客户端](https://firebase.google.com/docs/cloud-messaging/ios/get-started)、[接收消息](https://firebase.google.com/docs/cloud-messaging/ios/receive-messages)。
