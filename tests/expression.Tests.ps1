$ErrorActionPreference='Stop'
. "$PSScriptRoot\..\I18n.ps1"
. "$PSScriptRoot\..\State.ps1"
. "$PSScriptRoot\..\Expression.ps1"
$count=0
function Check($Condition,$Message){if(!$Condition){throw $Message};$script:count++;Write-Output "PASS: $Message"}
$now=[DateTimeOffset]::UtcNow
function Fixture($Percent){return @{Source='official-codex';Percent=$Percent;WindowMinutes=10080;ResetAt=$now.AddDays(7).ToUnixTimeSeconds();ReadAt=$now.ToString('o')}}
foreach($case in @(@(0,'tearful'),@(19.9,'tearful'),@(20,'panic'),@(49.9,'panic'),@(50,'smug'),@(50.1,'smug'),@(100,'smug'))){
 $r=Resolve-DragonExpression (Fixture $case[0]) 'smug' $false 5 $now
 Check ($r.Accepted -and $r.Mood -eq $case[1]) "Boundary $($case[0]) => $($case[1])"
}
foreach($previous in @('smug','panic','tearful')){
 Check ((Resolve-DragonExpression $null $previous $false 5 $now).Mood -eq $previous) 'Unknown preserves last successful expression'
 $r=Resolve-DragonExpression (Fixture 0) $previous $true 5 $now
 Check (!$r.Accepted -and $r.Mood -eq $previous) 'Read failure never creates a low trigger'
 $stale=Fixture 0;$stale.ReadAt=$now.AddMinutes(-7).ToString('o')
 $r=Resolve-DragonExpression $stale $previous $false 5 $now
 Check (!$r.Accepted -and $r.Mood -eq $previous -and $r.Reason -eq 'stale') 'Stale reading preserves previous expression'
 $expired=Fixture 0;$expired.ResetAt=$now.AddSeconds(-1).ToUnixTimeSeconds()
 Check (!(Resolve-DragonExpression $expired $previous $false 5 $now).Accepted) 'Expired reset does not retrigger'
 $manual=Fixture 0;$manual.Source='manual'
 Check (!(Resolve-DragonExpression $manual $previous $false 5 $now).Accepted) 'Manual entry is not a real quota trigger'
}
foreach($bad in @($null,$true,'0',-1,101,[double]::NaN,[double]::PositiveInfinity)){
 Check (!(Resolve-DragonExpression (Fixture $bad) 'smug' $false 5 $now).Accepted) 'Malformed percentage rejected'
}
foreach($slot in @('full','bust')){
 foreach($edge in @('left','right')){
  Check ((Get-DragonExpressionFacing $edge) -eq $(if($edge -eq 'right'){-1}else{1})) "$slot $edge stays inward; text layer is untouched"
  Check ((Resolve-DragonExpressionImage 'panic' "$slot-normal" "$slot-low" $true $false $true) -eq "$slot-low") "$slot built-in switches to paired low image"
  Check ((Resolve-DragonExpressionImage 'smug' "$slot-normal" "$slot-low" $true $false $true) -eq "$slot-normal") "$slot returns to its normal slot"
 }
}
Check ((Resolve-DragonExpressionImage 'panic' 'custom-normal' 'built-in-low' $false $false $true) -eq 'custom-normal') 'Unrelated custom normal is not replaced'
Check ((Resolve-DragonExpressionImage 'panic' 'custom-normal' 'custom-low' $false $true $true) -eq 'custom-low') 'Explicit custom low pair is respected'
Check ((Resolve-DragonExpressionImage 'panic' 'normal' 'missing-low' $true $false $false) -eq 'normal') 'Missing artwork falls back to current normal'
$state=Convert-DragonState @{Language='en';LastQuotaExpression='panic';LowImages=@{full='chosen-low';bust=''};Images=@{full='chosen-normal';bust='other-normal'}}
Check ($state.LastQuotaExpression -eq 'panic' -and $state.LowImages.full -eq 'chosen-low' -and $state.Images.full -eq 'chosen-normal' -and $state.Language -eq 'en') 'Normalization preserves custom pairs, language and last mood'
Check ((Convert-DragonState @{LastQuotaExpression='garbage'}).LastQuotaExpression -eq 'smug') 'Corrupt mood defaults safely'
. "$PSScriptRoot\..\Placard.ps1"
$state=New-DragonState;$state.Size=220;$state.ExpressionPlacards.tearful=@{X=.2;Y=.3;Width=.55;Height=.2}
$state.ExpressionPlacards.panic=@{X=.4;Y=.7;Width=.4;Height=.15}
foreach($edge in @('left','right')){
 $state.Edge=$edge;$a=Get-DragonExpressionPlacardRect $state 1284 1225 'tearful';$b=Get-DragonExpressionPlacardRect $state 1284 1225 'panic'
 Check ($a.Top -lt $b.Top) 'Raised tearful board has independent coordinates'
 Check ((Resolve-DragonExpressionImage 'tearful' 'normal' 'tears' $true $false $true) -eq 'tears') 'Tearful tier can select its own paired image'
}
$state.ExpressionPlacards.tearful=$null
Check ($null -eq (Get-DragonExpressionPlacardRect $state 1284 1225 'tearful')) 'Uncalibrated new board is never guessed from old frame'
Check ((Convert-DragonState @{LastQuotaExpression='tearful';TearfulImages=@{bust='chosen-tears'}}).LastQuotaExpression -eq 'tearful') 'Third tier survives settings normalization'
foreach($badFrame in @(@{X=.8;Y=.3;Width=.5;Height=.2},@{X=.1;Y=.1;Width=0;Height=.2},@{X=[double]::NaN;Y=.1;Width=.5;Height=.2})){
 Check ($null -eq (Convert-DragonState @{ExpressionPlacards=@{tearful=$badFrame}}).ExpressionPlacards.tearful) 'Unsafe or empty board frame rejected'
}
Write-Output "Passed $count no-network expression checks."
