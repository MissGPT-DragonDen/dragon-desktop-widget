$ErrorActionPreference='Stop'
# All six approved assets are required.
foreach($asset in @('full-low-quota.png','bust-low-quota.png','full-tearful.png','bust-tearful.png')){if(!(Test-Path -LiteralPath (Join-Path $PSScriptRoot ('assets/'+$asset)))){throw 'Approved artwork missing; cannot build a complete release.'}}

Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
$files=@('Expression.ps1','I18n.ps1','README.en.md','Dragon.ps1','State.ps1','Quota.ps1','Placard.ps1','Startup.ps1','DisableAutoStart.ps1','Start.vbs','Start.cmd','Diagnostic.cmd','Restore.cmd','DisableAutoStart.cmd','assets/smug-full.png','assets/smug-halfbody-placard.png','assets/full-low-quota.png','assets/bust-low-quota.png','assets/full-tearful.png','assets/bust-tearful.png','README.md','PRIVACY.md','LICENSE','NOTICE.md','ASSET_RIGHTS.md','assets/LICENSE.txt','CHANGELOG.md','.gitignore','Build.ps1')
$manifest=@{version='1.1.1';codeLicense='0BSD';assetLicense='CC0-1.0 (our rights only)';files=@($files|ForEach-Object { $p=Join-Path $PSScriptRoot $_; if(!(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing public file: $_"};@{path=$_;bytes=(Get-Item -LiteralPath $p).Length;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLowerInvariant()} })}
$manifest|ConvertTo-Json -Depth 6|Set-Content -LiteralPath (Join-Path $PSScriptRoot 'MANIFEST.json') -Encoding UTF8
$target=Join-Path (Split-Path -Parent $PSScriptRoot) 'white-dragon-widget-v1.1.1-windows.zip'
$stream=[IO.File]::Open($target,[IO.FileMode]::Create);$zip=New-Object IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Create)
try{foreach($name in ($files+@('MANIFEST.json'))){[IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Join-Path $PSScriptRoot $name),"white-dragon-widget/$name",[IO.Compression.CompressionLevel]::Optimal)|Out-Null}}finally{$zip.Dispose();$stream.Dispose()}
Get-FileHash -LiteralPath $target -Algorithm SHA256
