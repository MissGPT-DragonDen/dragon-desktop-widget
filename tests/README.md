# Tests / 测试

Run each in a fresh Windows PowerShell 5.1 process from the project root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/expression.Tests.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests/manual-preview.Tests.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/manual-ui.Tests.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/preview-refresh.Tests.ps1
```

The first two are pure/no-network checks. WPF tests create isolated, GUID-named temporary fixture folders, copy approved assets, replace only their fixture quota provider with explicit synthetic values, and drive their own settings dialogs. They neither query an account nor modify installed settings/startup. Windows/trays close in finally; temporary QA PNG/settings evidence stays in that folder for inspection. Do not use synthetic provider files as a real installation.

前两项为无网络纯测试；窗口测试只操作自己在临时目录建立的副本，使用明确的模拟官方来源。不会消耗账号额度、写入实际自启动或覆盖用户配置。退出会清理自己窗口和托盘；临时测试证据保留以便检查。

About v1.1.2 focused UI checks (same isolated synthetic fixture):

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File tests/about.Tests.ps1
```
