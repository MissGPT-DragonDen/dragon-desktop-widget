$script:dragonStartupName='WhiteDragonWidgetPublic.user-startup.vbs'
$script:dragonStartupMarker="' WhiteDragonWidgetPublic owned user startup v1"
function Get-DragonStartupDirectory([string]$Override=''){
    if($Override){return [IO.Path]::GetFullPath($Override)}
    return [Environment]::GetFolderPath('Startup')
}
function New-DragonStartupContent([string]$ProgramPath){
    $target=[IO.Path]::GetFullPath($ProgramPath).Replace('"','""')
    $message=(T '白毛龙娘挂件目录已移动或删除。请从新目录启动，然后将登录后启动关闭再开启，以更新路径。也可运行 DisableAutoStart.cmd 关闭此启动项。').Replace('"','""')
    $title=(T '白毛龙娘挂件').Replace('"','""')
    return @"
$script:dragonStartupMarker
Option Explicit
Dim target, fs, shell, engine, command
target = "$target"
Set fs = CreateObject("Scripting.FileSystemObject")
If Not fs.FileExists(target) Then
  MsgBox "$message", 48, "$title"
  WScript.Quit 0
End If
Set shell = CreateObject("WScript.Shell")
engine = shell.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
command = Chr(34) & engine & Chr(34) & " -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File " & Chr(34) & target & Chr(34)
shell.Run command, 0, False
"@
}
function Get-DragonStartupStatus([string]$ProgramPath,[string]$Directory=''){
    $path=Join-Path (Get-DragonStartupDirectory $Directory) $script:dragonStartupName
    if(!(Test-Path -LiteralPath $path)){return @{Enabled=$false;Owned=$false;Stale=$false;Path=$path}}
    $content=[IO.File]::ReadAllText($path)
    $owned=$content.StartsWith($script:dragonStartupMarker)
    $expected='target = "'+[IO.Path]::GetFullPath($ProgramPath).Replace('"','""')+'"'
    return @{Enabled=$owned;Owned=$owned;Stale=($owned -and $content.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -lt 0);Path=$path}
}
function Set-DragonStartup([bool]$Enabled,[string]$ProgramPath,[string]$Directory=''){
    $status=Get-DragonStartupStatus $ProgramPath $Directory
    if((Test-Path -LiteralPath $status.Path) -and !$status.Owned){throw (T 'Startup filename is occupied by an unrelated file; nothing changed')}
    if($Enabled){
        if(!(Test-Path -LiteralPath $ProgramPath)){throw (T 'Widget source path no longer exists')}
        $folder=Split-Path -Parent $status.Path;[IO.Directory]::CreateDirectory($folder)|Out-Null
        $temporary=$status.Path+'.tmp';[IO.File]::WriteAllText($temporary,(New-DragonStartupContent $ProgramPath),[Text.Encoding]::Unicode)
        Move-Item -LiteralPath $temporary -Destination $status.Path -Force
    }elseif($status.Owned){Remove-Item -LiteralPath $status.Path}
    return Get-DragonStartupStatus $ProgramPath $Directory
}
function Get-DragonInstanceName([string]$SettingsPath){
    $normalized=[IO.Path]::GetFullPath($SettingsPath).ToUpperInvariant()
    $sha=[Security.Cryptography.SHA256]::Create()
    try{$hash=[BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized))).Replace('-','')}finally{$sha.Dispose()}
    return 'Local\WhiteDragonWidget-'+$hash.Substring(0,24)
}
