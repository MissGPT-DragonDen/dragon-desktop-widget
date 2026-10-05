$ErrorActionPreference='Stop'
$qaRoot=Join-Path ([IO.Path]::GetTempPath()) ('WhiteDragonPreviewQA-'+[Guid]::NewGuid().ToString('N'))
$fixture=Join-Path $qaRoot 'fixture';[IO.Directory]::CreateDirectory($fixture)|Out-Null
$source=Split-Path -Parent $PSScriptRoot
Get-ChildItem -LiteralPath $source -Filter '*.ps1' | ForEach-Object {Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $fixture $_.Name)}
Copy-Item -LiteralPath (Join-Path $source 'assets') -Destination $fixture -Recurse
$main=Join-Path $fixture 'Dragon.ps1';$code=[IO.File]::ReadAllText($main);$code=$code.Substring(0,$code.IndexOf('# A modal ShowDialog'))
[IO.File]::WriteAllText($main,$code,(New-Object Text.UTF8Encoding $true))
# Explicit synthetic provider: the real Quota.ps1 is never queried by this fixture.
$provider="function Read-OfficialWeekly { param(`$Cancellation) Start-Sleep -Milliseconds 300;return @{Source='official-codex';Percent=85;WindowMinutes=10080;ResetAt=[DateTimeOffset]::UtcNow.AddDays(7).ToUnixTimeSeconds();ReadAt=[DateTimeOffset]::UtcNow.ToString('o')} }"
[IO.File]::WriteAllText((Join-Path $fixture 'Quota.ps1'),$provider,(New-Object Text.UTF8Encoding $true))
. "$qaRoot\fixture\Dragon.ps1" -SettingsPath "$qaRoot\isolated-settings.json" -StartupDirectory "$qaRoot\isolated-startup"
$script:state.AutoRefresh=$false;$script:window.Show();$script:count=0
function Check($Ok,$Message){if(!$Ok){throw $Message};$script:count++;Write-Output "PASS: $Message"}
function DriveDialog([string]$Kind,[string]$Value='',[bool]$UseButton=$true){
 $script:driveKind=$Kind;$script:driveValue=$Value;$script:driveButton=$UseButton;$script:driveError=$null
 $script:driver=New-Object Windows.Threading.DispatcherTimer;$script:driver.Interval=[TimeSpan]::FromMilliseconds(40)
 $script:driver.Add_Tick({
  $d=@($script:window.OwnedWindows)[0];if(!$d){return};$script:driver.Stop()
  try{
   if($script:driveKind -eq 'about'){
    $blocks=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.TextBlock]})
    Check ($blocks[0].Text -eq ((T '版本')+' 1.1.2')) 'About displays exact release version'
    Check ($blocks[1].Text -eq (T 'Reigiena × MissGPT 联合制作')) 'About credit is exact and localized'
    $d.UpdateLayout()
    if(!(Test-Path -LiteralPath (Join-Path $qaRoot "about-$script:uiLanguage.png"))){
     $v=$d;$b=New-Object Windows.Media.Imaging.RenderTargetBitmap([int][Math]::Ceiling($v.ActualWidth),[int][Math]::Ceiling($v.ActualHeight),96,96,[Windows.Media.PixelFormats]::Pbgra32);$b.Render($v)
     $e=New-Object Windows.Media.Imaging.PngBitmapEncoder;$e.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($b));$f=[IO.File]::Create((Join-Path $qaRoot "about-$script:uiLanguage.png"));try{$e.Save($f)}finally{$f.Dispose()}
    }
   }else{
    $inputs=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.TextBox]});$inputs[1].Text=$script:driveValue
   }
   if($script:driveButton){$button=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.Button]})[0];$button.RaiseEvent((New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent)))}else{$d.Close()}
  }catch{$script:driveError=$_;$d.Close()}
 })
 $script:driver.Start()
 if($Kind -eq 'about'){$item=@($script:menu.Items|Where-Object {$_ -is [Windows.Controls.MenuItem] -and $_.Header -eq (T '关于 / About')})[0];$item.RaiseEvent((New-Object Windows.RoutedEventArgs([Windows.Controls.MenuItem]::ClickEvent)))}else{Open-Settings}
 $script:driver.Stop();if($script:driveError){throw $script:driveError};$script:window.UpdateLayout()
}
try{
 Check (@($script:window.OwnedWindows).Count -eq 0) 'No About window opens at startup'
 foreach($lang in @('zh','en')){Set-DragonLanguage $lang
  foreach($slot in @('full','bust')){
   $script:state.Appearance=$slot;Apply-State
   foreach($n in @(20,50)){
    DriveDialog 'settings' "$n"
    $mood=if($n -eq 20){'panic'}else{'smug'}
    $text=if($slot -eq 'bust'){(Find 'PlacardPercent').Text}else{$script:fullQuotaVisual.FindName('FullPercent').Text}
    Check ($text -eq "$n%" -and $script:renderedExpression -eq $mood -and $script:state.UsageMode -eq 'manual-preview') "Actual $lang/$slot preview $n preserves v1.1.1 fix and tier"
   }
  }
  $before=$script:state|ConvertTo-Json -Depth 8;$bitmap=$script:character.Source;$fileTime=(Get-Item -LiteralPath $SettingsPath).LastWriteTimeUtc
  foreach($button in @($true,$false,$true)){
   DriveDialog 'about' '' $button
   Check (($script:state|ConvertTo-Json -Depth 8) -eq $before -and (Get-Item -LiteralPath $SettingsPath).LastWriteTimeUtc -eq $fileTime) 'Repeated About/close changes no saved state'
   Check ($script:window.IsVisible -and $script:window.IsEnabled -and $script:character.Source -eq $bitmap -and @($script:window.OwnedWindows).Count -eq 0) 'Main window, art and owner recover after both button and window close'
  }
 }
 DriveDialog 'settings' '';Check ($script:state.UsageMode -eq 'official' -and $null -eq $script:state.ManualUsage) 'Clearing preview still restores official mode'
 Check ($null -eq $script:quotaWorker) 'Focused checks made no account refresh request'
}finally{if($script:driver){$script:driver.Stop()};$script:window.Close()}
Write-Output "Passed $count focused About/preview checks; no account requests, real startup or user configuration writes."
