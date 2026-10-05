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
. "$qaRoot\fixture\Dragon.ps1" -SettingsPath "$qaRoot\settings.json" -StartupDirectory "$qaRoot\isolated-startup"
$script:state.AutoRefresh=$false;$script:state.Size=300;$script:state.Sizes.full=300;$script:state.Sizes.bust=300;$script:window.Show();$script:count=0
function Check($Ok,$Message){if(!$Ok){throw $Message};$script:count++;Write-Output "PASS: $Message"}
function Pump {$script:window.UpdateLayout();$script:window.Dispatcher.Invoke([Action]{},[Windows.Threading.DispatcherPriority]::ApplicationIdle)}
function SaveThroughDialog([string]$Value,[bool]$Clear=$false,[bool]$Invalid=$false){
 $script:driveValue=$Value;$script:driveClear=$Clear;$script:driveInvalid=$Invalid;$script:driveError=$null
 $script:driver=New-Object Windows.Threading.DispatcherTimer;$script:driver.Interval=[TimeSpan]::FromMilliseconds(40)
 $script:driver.Add_Tick({
  $d=@($script:window.OwnedWindows)[0];if(!$d){return};$script:driver.Stop()
  try{
   $inputs=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.TextBox]});$inputs[1].Text=$script:driveValue
   $checks=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.CheckBox]});$checks[1].IsChecked=$script:driveClear
   $save=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.Button]})[0];$save.RaiseEvent((New-Object Windows.RoutedEventArgs([Windows.Controls.Button]::ClickEvent)))
   if($script:driveInvalid){
    if(!$d.IsVisible){throw 'Invalid input unexpectedly saved'}
    $errors=@($d.Content.Children|Where-Object {$_ -is [Windows.Controls.TextBlock] -and $_.Foreground -eq [Windows.Media.Brushes]::Firebrick})
    if(!$errors[0].Text){throw 'Missing inline validation error'};$d.Close()
   }elseif($d.IsVisible){throw 'Valid input did not close/save'}
  }catch{$script:driveError=$_;$d.Close()}
 })
 $script:driver.Start();Open-Settings;$script:driver.Stop();if($script:driveError){throw $script:driveError};Pump
}
function Capture($Visual,$Path){
 $Visual.UpdateLayout();$b=New-Object Windows.Media.Imaging.RenderTargetBitmap([int][Math]::Ceiling($Visual.ActualWidth),[int][Math]::Ceiling($Visual.ActualHeight),96,96,[Windows.Media.PixelFormats]::Pbgra32);$b.Render($Visual)
 $e=New-Object Windows.Media.Imaging.PngBitmapEncoder;$e.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($b));$f=[IO.File]::Create($Path);try{$e.Save($f)}finally{$f.Dispose()}
}
try {
 foreach($lang in @('zh','en')){foreach($slot in @('full','bust')){
  $script:state.Appearance=$slot;$script:state.Edge='right';Set-DragonLanguage $lang
  $script:state.Usage=@{Source='official-codex';Percent=85;ReadAt=[DateTimeOffset]::UtcNow.ToString('o');WindowMinutes=10080;ResetAt=[DateTimeOffset]::UtcNow.AddDays(7).ToUnixTimeSeconds()};Restore-OfficialUsage
  foreach($n in @(0,19,20,49,50,100)){
   SaveThroughDialog "$n";Update-QuotaBadge;Pump;$mood=if($n -lt 20){'tearful'}elseif($n -lt 50){'panic'}else{'smug'}
   $text=if($slot -eq 'bust'){(Find 'PlacardPercent').Text}else{$script:fullQuotaVisual.FindName('FullPercent').Text}
   $heading=if($slot -eq 'bust'){(Find 'PlacardHeading').Text}else{$script:fullQuotaVisual.FindName('FullHeading').Text}
   $reset=if($slot -eq 'bust'){(Find 'PlacardReset').Text}else{$script:fullQuotaVisual.FindName('FullReset').Text}
   Check ($text -eq "$n%" -and $script:renderedExpression -eq $mood) "Actual dialog $lang/$slot input $n shows correct number and $mood"
   Check ($heading -eq (T '手动预览') -and $reset -eq (T '无真实重置时间')) 'Both surfaces explicitly identify preview and omit real reset claims'
   Check ($script:state.Usage.Percent -eq 85 -and $script:state.LastQuotaExpression -eq 'smug') 'Preview never overwrites official reading or official accepted mood'
   $reload=Convert-DragonState $script:state;Check ($reload.UsageMode -eq 'manual-preview' -and $reload.ManualUsage.Percent -eq $n -and $reload.Usage.Percent -eq 85) 'Preview and official sources normalize independently'
   if($n -eq 20){Capture $script:surface (Join-Path $qaRoot "preview-$lang-$slot-20.png");if($slot -eq 'full'){Capture $script:fullQuotaVisual (Join-Path $qaRoot "bubble-$lang-20.png")}}
  }
  SaveThroughDialog '';Check ($script:state.UsageMode -eq 'official' -and $script:state.Usage.Percent -eq 85) 'Clearing prefilled input restores official mode'
 }}
 foreach($fragment in @('剩余 50%','Remaining 20%','Usage Remaining 19%','使用情况 剩余 100%','49.5%','0')){
  SaveThroughDialog $fragment;Check ($script:state.UsageMode -eq 'manual-preview') "Legal fragment accepted: $fragment"
 }
 $before=$script:state|ConvertTo-Json -Depth 8
 foreach($bad in @('-1','101','20abc','NaN','Remaining 1% extra','20,5')){
  SaveThroughDialog $bad $false $true;Check (($script:state|ConvertTo-Json -Depth 8) -eq $before) "Invalid input leaves saved state and visible preview intact: $bad"
 }
 SaveThroughDialog 'garbage' $true;Check ($script:state.UsageMode -eq 'official' -and $null -eq $script:state.ManualUsage) 'Explicit clear takes precedence over invalid field and restores official mode'
 $script:state.AutoRefresh=$true;Start-QuotaRefresh;SaveThroughDialog '20';$script:quotaTimer.Start()
 $until=[DateTime]::UtcNow.AddSeconds(3);while($script:quotaWorker -and [DateTime]::UtcNow -lt $until){Pump;Start-Sleep -Milliseconds 20};$script:quotaTimer.Stop();Update-QuotaBadge
 Check ($null -eq $script:quotaWorker -and $script:state.UsageMode -eq 'manual-preview' -and $script:state.ManualUsage.Percent -eq 20 -and $script:renderedExpression -eq 'panic') 'Already-running synthetic refresh completes without replacing preview'
 Start-QuotaRefresh;Check ($null -eq $script:quotaWorker -and !$refreshItem.IsEnabled) 'Preview suppresses new queries and disables official refresh command'
 $official=Convert-DragonState $script:state;Check ($official.AutoRefresh -and $official.RefreshMinutes -eq 5) 'Original refresh preference stays saved during preview'
 Restore-OfficialUsage;Check ($script:state.UsageMode -eq 'official' -and $refreshItem.IsEnabled) 'Explicit menu restoration returns to official source and refresh availability'
 $legacy=Convert-DragonState @{Usage=(Read-ManualUsage '20')};Check ($legacy.UsageMode -eq 'manual-preview' -and $legacy.ManualUsage.Percent -eq 20 -and $null -eq $legacy.Usage) 'Legacy manual reading migrates into separate preview'
 $saved=Get-Content -LiteralPath $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json;Check ($saved.UsageMode -eq 'official' -and $saved.Usage.Source -eq 'official-codex') 'Actual Save-State persistence keeps only correct active mode/source'
}finally{$script:quotaTimer.Stop();$script:window.Close()}
Write-Output "Passed $count actual-dialog/manual-preview checks; synthetic official provider only, no account/startup/install writes."
