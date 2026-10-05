# Pure expression selection. No network, credentials, screen reading or timers.
function Resolve-DragonExpression($Usage,[string]$Previous='smug',[bool]$ReadFailed=$false,[double]$RefreshMinutes=5,$Now=[DateTimeOffset]::UtcNow){
    if($Previous -notin @('smug','panic','tearful')){$Previous='smug'}
    $held=@{Mood=$Previous;Accepted=$false;Reason='unavailable'}
    if((Get-DragonField $Usage 'Source') -eq 'manual-preview'){
        $value=Get-DragonField $Usage 'Percent'
        if($null -ne $value -and [Type]::GetTypeCode($value.GetType()).ToString() -in @('Byte','SByte','Int16','UInt16','Int32','UInt32','Int64','UInt64','Single','Double','Decimal')){
            $percent=[double]$value
            if(![double]::IsNaN($percent) -and ![double]::IsInfinity($percent) -and $percent -ge 0 -and $percent -le 100){return @{Mood=$(if($percent -lt 20){'tearful'}elseif($percent -lt 50){'panic'}else{'smug'});Accepted=$false;Reason='manual-preview'}}
        }
        return $held
    }
    if($ReadFailed){$held.Reason='read-failed';return $held}
    if($null -eq $Usage -or (Get-DragonField $Usage 'Source') -ne 'official-codex'){return $held}
    try{
        $value=Get-DragonField $Usage 'Percent'
        if($null -eq $value -or [Type]::GetTypeCode($value.GetType()).ToString() -notin @('Byte','SByte','Int16','UInt16','Int32','UInt32','Int64','UInt64','Single','Double','Decimal')){return $held}
        $percent=[double]$value
        if([double]::IsNaN($percent) -or [double]::IsInfinity($percent) -or $percent -lt 0 -or $percent -gt 100){return $held}
        if((Get-DragonField $Usage 'WindowMinutes') -ne 10080){return $held}
        $read=[DateTimeOffset]::Parse((Get-DragonField $Usage 'ReadAt'))
        $reset=[DateTimeOffset]::FromUnixTimeSeconds((Get-DragonField $Usage 'ResetAt'))
        if($read -gt $Now.AddMinutes(1)){return $held}
        if(($Now-$read).TotalMinutes -gt ($RefreshMinutes+1) -or $reset -le $Now){$held.Reason='stale';return $held}
        return @{Mood=$(if($percent -lt 20){'tearful'}elseif($percent -lt 50){'panic'}else{'smug'});Accepted=$true;Reason='official-weekly'}
    }catch{return $held}
}
function Get-DragonExpressionFacing([string]$Edge){if($Edge -eq 'right'){return -1};return 1}
function Resolve-DragonExpressionImage([string]$Mood,[string]$NormalPath,[string]$LowPath,[bool]$NormalIsBuiltIn,[bool]$LowIsCustom,[bool]$LowAvailable){
    # Never replace unrelated custom artwork with our character automatically.
    if($Mood -in @('panic','tearful') -and $LowAvailable -and ($NormalIsBuiltIn -or $LowIsCustom)){return $LowPath}
    return $NormalPath
}
function Test-DragonBuiltInImage([string]$Path,[string]$BuiltInPath){
    if([string]::Equals($Path,$BuiltInPath,[StringComparison]::OrdinalIgnoreCase)){return $true}
    if(!(Test-DragonImagePath $Path) -or !(Test-Path -LiteralPath $BuiltInPath -PathType Leaf)){return $false}
    # Only the selected local image and the known bundled image are read.
    try{return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $BuiltInPath -Algorithm SHA256).Hash}catch{return $false}
}
