$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\I18n.ps1"
. "$PSScriptRoot\..\State.ps1"
. "$PSScriptRoot\..\Expression.ps1"
. "$PSScriptRoot\..\Placard.ps1"
$count=0
function Check($Ok,$Text){if(!$Ok){throw $Text};$script:count++;Write-Output "PASS: $Text"}
foreach($n in @(0,19,20,49,50,100)){
 $state=New-DragonState;$state.UsageMode='manual-preview';$state.ManualUsage=Read-ManualUsage "$n";$state=Convert-DragonState $state
 $display=Get-DragonDisplayUsage $state;$mood=if($n -lt 20){'tearful'}elseif($n -lt 50){'panic'}else{'smug'};$choice=Resolve-DragonExpression $display 'smug' $true
 Check ($display.Source -eq 'manual-preview' -and $display.Percent -eq $n) 'Explicit preview data has separate source and exact percentage'
 Check ($choice.Mood -eq $mood -and !$choice.Accepted -and $choice.Reason -eq 'manual-preview') 'Preview selects tier without accepting an official mood'
 Check ((Get-DragonResetLabel $display) -eq (T '无真实重置时间')) 'Preview never invents real reset'
}
foreach($bad in @('-1','101','NaN','Infinity','20abc','20,5','Remaining 20% extra')){
 $threw=$false;try{Read-ManualUsage $bad|Out-Null}catch{$threw=$true};Check $threw 'Invalid entry rejected'
}
foreach($bad in @($true,'20',[double]::NaN,[double]::PositiveInfinity,-1,101)){
 $state=Convert-DragonState @{UsageMode='manual-preview';ManualUsage=@{Source='manual';Percent=$bad;ReadAt=[DateTimeOffset]::UtcNow.ToString('o')}}
 Check ($state.UsageMode -eq 'official' -and $null -eq $state.ManualUsage) 'Malformed persisted preview cannot activate'
}
$legacy=Convert-DragonState @{Usage=(Read-ManualUsage '剩余 20%')}
Check ($legacy.UsageMode -eq 'manual-preview' -and $legacy.ManualUsage.Source -eq 'manual-paste' -and $null -eq $legacy.Usage) 'Legacy pasted reading migrates without impersonating official source'
Check ($null -eq (Read-ManualUsage '')) 'Empty input is a clear signal'
$state=New-DragonState;$state.UsageMode='manual-preview';$state.ManualUsage=Read-ManualUsage '20';$map=@{};$raw=$state|ConvertTo-Json -Depth 8|ConvertFrom-Json;foreach($p in $raw.PSObject.Properties){$map[$p.Name]=$p.Value};$restored=Convert-DragonState $map
Check ($restored.UsageMode -eq 'manual-preview' -and $restored.ManualUsage.Percent -eq 20) 'JSON round trip preserves preview source and mode'
Write-Output "Passed $count pure preview checks; no account, UI or startup access."
