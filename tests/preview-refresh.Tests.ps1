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
. "$qaRoot\fixture\Dragon.ps1" -SettingsPath "$qaRoot\failure-settings.json" -StartupDirectory "$qaRoot\isolated-startup"
$script:state.AutoRefresh=$false;$script:state.Appearance='bust';$script:window.Show()
$script:state.Usage=@{Source='official-codex';Percent=85;ReadAt=[DateTimeOffset]::UtcNow.ToString('o');WindowMinutes=10080;ResetAt=[DateTimeOffset]::UtcNow.AddDays(7).ToUnixTimeSeconds()}
function Show-Bubble([string]$Text){$script:detailsText=$Text}
try{
 Save-DragonSettingsInput 'QA' $false '20' $false
 $script:quotaWorker=[PowerShell]::Create();$script:quotaWorker.AddScript("throw 'synthetic failure'")|Out-Null;$script:quotaPending=$script:quotaWorker.BeginInvoke()
 $script:quotaTimer.Start();$until=[DateTime]::UtcNow.AddSeconds(3)
 while($script:quotaWorker -and [DateTime]::UtcNow -lt $until){$script:window.Dispatcher.Invoke([Action]{},[Windows.Threading.DispatcherPriority]::ApplicationIdle);Start-Sleep -Milliseconds 20}
 $script:quotaTimer.Stop();Update-QuotaBadge
 if(!$script:quotaFailed -or (Find 'PlacardPercent').Text -ne '20%' -or $script:renderedExpression -ne 'panic'){throw 'Failed in-flight result altered preview'}
 'PASS: Failed in-flight synthetic refresh cannot replace preview number or mood'
 Show-QuotaDetails
 if($script:detailsText -match '约\d|~\d|85%|Codex account/rateLimits/read'){throw 'Official detail leaked into preview'}
 'PASS: Preview details exclude official countdown and official-source assertions'
 Set-DragonLanguage 'en';Update-QuotaBadge;Show-QuotaDetails
 if($script:detailsText -notmatch 'Manual preview: 20%' -or $script:detailsText -notmatch 'No actual reset time'){throw 'English detail not marked preview'}
 'PASS: Live language switch preserves explicit manual source and no-reset detail'
 Restore-OfficialUsage
 if((Find 'PlacardPercent').Text -notmatch '85%' -or (Find 'PlacardStatus').Text -notmatch 'Old reading'){throw 'Official failure state not restored'}
 'PASS: Returning to official mode restores held real-source fixture and its failure marker'
 $script:quotaFailed=$false;$script:state.LastQuotaExpression='panic';Save-DragonSettingsInput 'QA' $false '20' $false;Restore-OfficialUsage
 $persisted=Get-Content -LiteralPath $SettingsPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($persisted.LastQuotaExpression -ne 'smug'){throw 'Restored accepted official expression was not persisted'}
 'PASS: Restored official accepted expression is updated before persistence'
}finally{$script:quotaTimer.Stop();$script:window.Close()}
