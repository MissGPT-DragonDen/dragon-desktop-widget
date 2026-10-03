$ErrorActionPreference='Stop'
. "$PSScriptRoot\I18n.ps1"
. "$PSScriptRoot\Startup.ps1"
$status=Set-DragonStartup $false (Join-Path $PSScriptRoot 'Dragon.ps1')
Write-Output '当前用户公开版白毛龙娘自启动已关闭；未修改服务或注册表。 / Public widget login startup disabled for this user; no services or registry changes.'
