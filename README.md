# 白毛龙娘桌面挂件 / White Dragon Desktop Widget

An unofficial community Windows desktop companion by MissGPT-DragonDen. Not affiliated with or endorsed by OpenAI. Our code and documentation use 0BSD; our rights in the two listed project-generated artworks are contributed under CC0-1.0. No attribution is required for our contributions.

这是**非官方社区作品**，独立 Windows 桌面程序，不需要打开 ChatGPT 网页，与 ChatGPT 原生宠物项目分开。当前公开准备版本 **1.0.0 public**：基于已验收 v8，新增双语 UI、独立公开版配置及发布清理；不是未经修改的原版。

[English documentation](README.en.md)

## 启动

将 Windows ZIP 完整解压到固定目录，双击 `Start.vbs`；VBS 不可用时用 `Start.cmd`。需要 Windows 桌面、Windows PowerShell 5.1、WPF/.NET Framework；不需要 Python、npm 或管理员权限。脚本没有数字签名；如组织策略禁止脚本，不要修改安全策略来强行运行。`Diagnostic.cmd` 为自选可见控制台排障入口。

右键或长按角色打开菜单，拖动靠边、按压反馈、双形象切换、分别导入本地 PNG/JPEG、缩放和台词配置可用。全身使用朝屏幕中间的短三角气泡，半身在黑牌显示用量。窗口不占任务栏；托盘提供显示/隐藏/退出，找不到时双击 `Restore.cmd`。相同配置的重复启动会恢复已有实例。菜单“语言 / Language”可切换中文和 English，默认中文，选择会保存。自定义台词不被强行翻译。

**登录 Windows 后自启动默认关闭**，只有用户主动勾选才向当前用户启动文件夹写入本程序的 VBS。关闭菜单开关或运行 `DisableAutoStart.cmd` 可撤销。移动目录后应关闭再开启以更新路径；不自动追踪新位置。公开版使用独立的 `%LOCALAPPDATA%/WhiteDragonWidgetPublic` 设置目录和 `WhiteDragonWidgetPublic.user-startup.vbs` 启动项，不覆盖私人v8的设置或导入图。公开版升级保留自己已有的配置；既有自启动不会因解压新版而强制关闭。

## 用量功能的条件与口径

**没有安装、没有登录或版本不兼容的官方 Codex 客户端时，自动用量不可用。** 挂件不附带客户端，不替你安装或发起登录。角色显示功能仍可使用。仅发现 PATH 上的 `codex.exe` 或官方 Windows Codex 安装目录中的客户端；客户端布局变化可能使发现失败。

通过官方 Codex `app-server --stdio` 的文档化 `account/rateLimits/read`，复用该客户端自己的既有登录，读取 `codex` 桶唯一的 10080 分钟周窗口。剩余百分比为 `100-usedPercent`，重置时间使用官方 `resetsAt` 秒级时间戳，显示为用户本地时区。这里是 Codex/Work 共享周额度，**不是所有普通 ChatGPT 对话的通用余额，也不是 API 组织用量或 credits 金额**。具体套餐支持、共享范围和服务返回以 OpenAI 当前规则为准；若登录账号或窗口不同，应对照自己的官方使用情况界面。

默认每 5 分钟刷新，可选 1/5/15/60 分钟、关闭或手动刷新。25 秒有界读取在后台运行。失败保留旧值并标明旧值/更新时间；字段缺失、模糊或过期不编造数值，不在重置时推断 100%。手动来源只是明确标记的备选，不等同实时数据。

挂件不打开认证文件，不复制凭据、不使用私有 HTTP 接口。官方客户端在自身内部使用既有认证，查询可能触发其正常服务请求；它不是完全离线额度查询。详见 [安全与隐私](PRIVACY.md)。

## 发行与权利

自有代码/文档使用 [0BSD](LICENSE)，不要求署名；列明的两张美术在可授权权利范围内使用 [CC0](ASSET_RIGHTS.md)。可自由用、改、分发和商用我们的贡献。见 [版本记录](CHANGELOG.md) 和 [非官方/第三方说明](NOTICE.md)。不再许可第三方商标、系统字体或参考素材。公开包不包含参考图、个人配置、额度读数、日志或客户端二进制。`MANIFEST.json` 记录各公开文件 SHA256，`Build.ps1` 仅打包明确列出的文件。

## 兼容性与验证范围

沿用 v8 的 Windows WPF 验证：双形象、托盘/单实例、真实官方读取、错误保留、取消退出及左右贴边已验证；当前屏幕 150% 缩放和短三角常见尺寸已检查。跨屏、其他 DPI、真实重启/登录尚未实测。公开整理还对双语言菜单/托盘/气泡/黑牌、语言保存、英文百分比及重置文本做了聚焦窗口检查，未重新查询额度或重跑全部历史UI测试。

官方来源：[Codex App Server](https://developers.openai.com/codex/app-server/)、[Using Codex with your ChatGPT plan](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan)。接口与客户端未来变化可能影响兼容性。
