# 1.1.2 — 关于署名 / About credits

## 中文

- 新增低调的“关于 / About”菜单入口；仅点击后显示版本与一行联合制作署名。
- 主界面无新增水印、开屏提示或自动弹窗。保留v1.1.1手动预览修复、现有许可及所有功能。

## English

- Add a discreet About menu showing the version and a single co-creation credit only when opened.
- No new watermark, startup notice or automatic dialog. Preserve v1.1.1 manual-preview behavior, licenses and all existing features.

# 1.1.1 — 手动预览修复 / Manual preview fix

## 中文

- 修复手动输入保存成功但角色仍显示暂不可用的问题；两种形象立即显示明确标记的预览百分比并测试三档表情。
- 手动预览与官方缓存分别保存，暂停新查询；在途刷新成功或失败不会覆盖预览。
- 清空输入、清除预览或恢复官方菜单可退出预览，恢复原刷新设置；不生成预览重置时间。
- 保留v1.1.0发布文档的六张美术说明和双语更新日志；不修改已安装版本或用户设置。

## English

- Fix saved manual percentages showing unavailable on character surfaces; both appearances immediately show an explicit preview and its expression tier.
- Persist preview separately from official snapshots, pause new queries, and prevent in-flight success/failure from replacing preview.
- Clear input/preview or restore official mode to resume previous refresh preferences; preview never invents a reset time.
- Preserve the published v1.1.0 six-asset description and bilingual changelog. No installed-copy/settings changes.

# 1.1.0 — 三档表情 / Three expression tiers

## 中文

- 全身与半身各内置三张已确认美术：周剩余≥50%屑笑、20%–<50%慌张、<20%流泪。
- 流泪半身抬高黑牌独立标定；无效、过期、失败或手动数据保留上次有效表情。
- 保留原设置、正常图片身份、朝内布局和正向可读文字。
- 通过55项逻辑、61项WPF回归及75项真实美术WPF检查；验证未读取真实额度或注册自启动。

## English

- Two appearances each include approved smug (≥50%), panic (20–<50%) and tearful (<20%) art.
- Independent raised tearful placard calibration; invalid/stale/failed/manual readings hold the last accepted expression.
- Original settings, normal image identity, inward facing and readable text are preserved.
- Passed 55 logic, 61 WPF regression and 75 real-art WPF checks; verification made no live usage reads or startup registrations.

# 1.0.0 public — 基于已验收 v8

- 中文/English菜单、气泡、重置时间、设置、托盘及项目错误提示；语言选择保存，默认中文。系统自带对话框/异常跟随系统语言。
- 独立公开版配置和自启动身份，不覆盖用户私人v8；保留其已验收双形象、布局、短三角及用量功能。
- 中英使用/隐私/素材权利/非官方说明；代码文档0BSD，列明美术可授权权利CC0。
- 公开清理删除开发快照入口，排除私人数据与参考材料。没有新权限、远程服务或新真实额度查询。

# 1.0.0 public — English

Derived from accepted v8; not an unchanged copy. Adds persistent Chinese/English menus, bubbles, reset text, settings, tray and project-generated errors (native OS dialogs/errors follow the OS language). A separate public settings/startup identity leaves private v8 untouched. Accepted character layouts, short triangles and documented official usage behavior remain.

Documentation is bilingual. Code/docs are 0BSD; only our rights in the two listed artwork contributions are CC0. Cleanup removes developer state-dump entry points and excludes private/reference materials. No new permissions, remote service or actual quota query was introduced.

## Inherited / 继承功能

Independent transparent WPF desktop character, full/half-body slots and local imports, dragging/snapping, press feedback, saved scale/position/dialogue; official shared weekly usage/reset with refresh/source/stale/error handling; off-taskbar tray restore/exit and reversible current-user sign-in startup, off by default. / 独立透明角色、双图槽位和本地导入、拖动吸边、按压反馈、设置保存、官方共享周用量/重置与旧值提示、托盘恢复和可逆自启动（默认关闭）。
