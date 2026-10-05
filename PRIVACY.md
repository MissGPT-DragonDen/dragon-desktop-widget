# 安全与隐私

本项目是非官方社区作品，不由 OpenAI 提供或背书。

- 不读取聊天、浏览历史、屏幕或其他应用窗口内容；不监控回答结束。不收集遥测、不请求购买或增加额度。
- 不读取认证文件、环境里的账号密钥或浏览器 cookies，不复制 tokens，不创建登录授权。只向自己启动的官方 Codex app-server 发出初始化及只读额度方法；其既有登录和正常服务通信由官方客户端负责。
- 本地保存窗口位置、角色选择/尺寸、台词、刷新设置、导入图片路径和最近额度读数/来源/时间。位于当前用户 `%LOCALAPPDATA%/WhiteDragonWidgetPublic`；这些是私人数据，**不要上传该目录、配置或诊断输出**。首次写入可能保留旧配置备份；导入图片仅复制到该本地目录。
- 关闭自动刷新可停止周期请求。退出会停止计时器，取消待处理读取、终止自己启动的临时客户端并清理托盘/单实例锁。不会终止用户自行启动的其他客户端。
- 开机启动实际上是当前用户登录后的启动文件夹入口，默认不创建；仅主动勾选后写入。关闭开关或运行 `DisableAutoStart.cmd` 仅删除本程序拥有的入口，不改注册表、服务或全局策略。
- 启动器的 `ExecutionPolicy Bypass` 仅作用于本次 PowerShell 进程，不修改永久策略。脚本未签名；请检查源码，不要绕过组织设备限制。
- 本项目没有权限隔离沙箱；以当前用户权限运行 PowerShell/WPF。发布包不含任何现成凭据、认证文件、个人读数或聊天数据。
- 本地诊断可能显示错误/路径，请在分享前自行去除个人信息。公开版本已删除开发用截图和状态快照入口。


# Privacy and security — English

This is an unofficial community project with no OpenAI affiliation or endorsement.

- No chat, browser-history, screen or other-app reading; no answer-completion monitoring, telemetry, purchases or credit changes.
- No authentication-file, cookie, environment-secret or token reading/copying and no new login authorization. Only initialization and documented read-only usage methods are sent to the temporary official client. That client owns its existing authentication and normal service communication.
- Position, appearance/size, custom lines, language, refresh preferences, imported-image paths and the last usage reading/source/time stay locally in `%LOCALAPPDATA%/WhiteDragonWidgetPublic`. They are private: do not upload this directory, settings or diagnostics. An upgrade backup may be retained; imported images are copied locally. Private v8 uses a separate profile and is not overwritten.
- Disable auto-refresh to stop periodic requests. Exit stops timers, cancels pending reads, terminates only the client this widget started, and cleans up its tray and instance lock. Other user-started clients are not terminated.
- Sign-in startup is off by default and only explicitly enabled for the current user. The toggle or `DisableAutoStart.cmd` removes only this public widget's owned entry, without registry, service or global-policy changes.
- Launcher execution-policy bypass affects only that PowerShell process, not permanent policy. Scripts are unsigned. Inspect the source and respect managed-device restrictions.
- The PowerShell/WPF application runs with ordinary current-user permissions; it is not a sandbox. No existing credentials, account readings or chat data ship in the release.
- Review diagnostics before sharing: OS errors may include personal paths and use your OS language. Developer screenshot/state-dump entry points are removed from the public version. Language selection adds no remote service or permissions.


## 手动预览 / Manual preview

手动预览仅保存输入的百分比、来源与记录时间；不读取账户或屏幕。预览与官方缓存分离，暂停新官方查询；已在途请求仍可完成但不改变预览显示。退出预览恢复用户原刷新设置。预览不是实际额度，不生成重置时间。

Manual preview stores only the entered percentage, source and record time, separately from official snapshots. It reads no account or screen data. New official queries pause; an in-flight request may finish without replacing the preview. Leaving preview resumes the original refresh preferences. Preview is not actual usage and has no fabricated reset.
