Set-StrictMode -Version Latest
function New-DragonState {
    return @{ Version=6; Language='zh'; LastQuotaExpression='smug'; LowImages=@{full='';bust=''}; TearfulImages=@{full='';bust=''}; ExpressionPlacards=@{panic=@{X=.4634;Y=.7004;Width=.4128;Height=.1731};tearful=@{X=.4400;Y=.5680;Width=.3620;Height=.1580}}; Placard=@{X=.4634;Y=.7004;Width=.4128;Height=.1731}; RefreshMinutes=5; AutoRefresh=$true; Appearance='full'; Images=@{full='';bust=''}; Sizes=@{full=180;bust=220}; Layouts=@{full='Bottom';bust='Center'}; Size=180; X=0.90; Y=0.75; Edge='right'; Topmost=$true; Mode='sequence'; Lines=@((T '呵，就这？'),(T '累了就休息一下吧。'),(T '我的用量数据还没有可靠来源。')); Image=''; Usage=$null }
}
function Get-DragonField($Object,[string]$Name) {
    if($null -eq $Object){return $null}
    if($Object -is [Collections.IDictionary]){if($Object.Contains($Name)){return $Object[$Name]};return $null}
    $property=$Object.PSObject.Properties[$Name];if($null -ne $property){return $property.Value};return $null
}
function Limit-Number($Value, [double]$Default, [double]$Min, [double]$Max) {
    try { $n=[double]$Value; if ([double]::IsNaN($n) -or [double]::IsInfinity($n)) {return $Default}; return [Math]::Min($Max,[Math]::Max($Min,$n)) } catch { return $Default }
}
function Convert-DragonState($Raw) {
    $s=New-DragonState
    if ($null -eq $Raw) { return $s }
    if($Raw.Contains('LastQuotaExpression') -and $Raw.LastQuotaExpression -in @('smug','panic','tearful')){$s.LastQuotaExpression=$Raw.LastQuotaExpression}
    $low=Get-DragonField $Raw 'LowImages';foreach($slot in @('full','bust')){$path=Get-DragonField $low $slot;if($path -is [string]){$s.LowImages[$slot]=$path}}
    $tears=Get-DragonField $Raw 'TearfulImages';foreach($slot in @('full','bust')){$path=Get-DragonField $tears $slot;if($path -is [string]){$s.TearfulImages[$slot]=$path}}
    $frames=Get-DragonField $Raw 'ExpressionPlacards'
    foreach($mood in @('panic','tearful')){
        $rawFrame=Get-DragonField $frames $mood
        if($null -ne $rawFrame){$s.ExpressionPlacards[$mood]=$null}
        if($null -ne $rawFrame){
            $frame=@{};$valid=$true
            foreach($key in @('X','Y','Width','Height')){$v=Get-DragonField $rawFrame $key;if($null -eq $v -or $v -is [bool]){$valid=$false;break};try{$v=[double]$v;if([double]::IsNaN($v) -or [double]::IsInfinity($v) -or $v -lt 0 -or $v -gt 1){$valid=$false;break};$frame[$key]=$v}catch{$valid=$false;break}}
            if($valid -and $frame.Width -gt 0 -and $frame.Height -gt 0 -and $frame.X+$frame.Width -le 1 -and $frame.Y+$frame.Height -le 1){$s.ExpressionPlacards[$mood]=$frame}
        }
    }
    if($Raw.Contains('Language') -and $Raw.Language -in @('zh','en')){$s.Language=$Raw.Language}
    foreach ($key in @('Size','X','Y')) { if ($Raw.Contains($key)) { $limits=@{Size=@(80,320);X=@(0,1);Y=@(0,1)}; $s[$key]=Limit-Number $Raw[$key] $s[$key] $limits[$key][0] $limits[$key][1] } }
    if ($Raw.Contains('Edge') -and $Raw.Edge -in @('left','right','free')) { $s.Edge=$Raw.Edge }
    if ($Raw.Contains('Topmost') -and $Raw.Topmost -is [bool]) {$s.Topmost=$Raw.Topmost}
    if ($Raw.Contains('Mode') -and $Raw.Mode -eq 'random') {$s.Mode='random'}
    if ($Raw.Contains('Appearance') -and $Raw.Appearance -in @('full','bust')) {$s.Appearance=$Raw.Appearance}
    $rawPlacard=Get-DragonField $Raw 'Placard'
    foreach($key in @('X','Y','Width','Height')){$value=Get-DragonField $rawPlacard $key;if($null -ne $value){$minimum=if($key -in @('Width','Height')){.10}else{0};$s.Placard[$key]=Limit-Number $value $s.Placard[$key] $minimum 1}}
    $s.Placard.Width=[Math]::Min($s.Placard.Width,1-$s.Placard.X);$s.Placard.Height=[Math]::Min($s.Placard.Height,1-$s.Placard.Y)
    $rawImages=Get-DragonField $Raw 'Images';$rawSizes=Get-DragonField $Raw 'Sizes';$rawLayouts=Get-DragonField $Raw 'Layouts'
    foreach($slot in @('full','bust')){
        $image=Get-DragonField $rawImages $slot;if($image -is [string]){$s.Images[$slot]=$image}
        $size=Get-DragonField $rawSizes $slot;if($null -ne $size){$s.Sizes[$slot]=Limit-Number $size $s.Sizes[$slot] 80 320}
        $layout=Get-DragonField $rawLayouts $slot;if($layout -in @('Bottom','Center','Top')){$s.Layouts[$slot]=$layout}
    }
    # Migrate the old single image only to the full-body slot, without touching an explicit new slot map.
    if($null -eq $rawImages -and $Raw.Contains('Image') -and $Raw.Image -is [string]){$s.Images.full=$Raw.Image}
    if($null -eq $rawSizes){$s.Sizes[$s.Appearance]=$s.Size}
    $s.Size=$s.Sizes[$s.Appearance];$s.Image=$s.Images[$s.Appearance]
    if ($Raw.Contains('Lines')) { $lines=@($Raw.Lines | Where-Object {$_ -is [string]} | ForEach-Object {$_.Trim()} | Where-Object {$_} | Select-Object -First 30 | ForEach-Object {$_.Substring(0,[Math]::Min(160,$_.Length))}); if ($lines.Count) {$s.Lines=$lines} }
    if($Raw.Contains('RefreshMinutes')){$s.RefreshMinutes=Limit-Number $Raw.RefreshMinutes 5 1 60}
    if($Raw.Contains('AutoRefresh') -and $Raw.AutoRefresh -is [bool]){$s.AutoRefresh=$Raw.AutoRefresh}
    if ($Raw.Contains('Usage') -and $null -ne $Raw.Usage) {
        $u=$Raw.Usage
        try { $cachedPercent=Get-DragonField $u 'Percent';if($null -eq $cachedPercent -or $cachedPercent -is [bool]){throw 'Missing or invalid cached percentage'};$percent=[double]$cachedPercent; $time=[DateTimeOffset]::Parse($u.ReadAt); if (!([double]::IsNaN($percent) -or [double]::IsInfinity($percent)) -and $percent -ge 0 -and $percent -le 100 -and $u.Source -in @('manual','manual-paste','official-codex') -and $time -le [DateTimeOffset]::UtcNow.AddMinutes(1)) { $s.Usage=@{Percent=$percent;ReadAt=$time.ToString('o');Source=$u.Source;Metric=(T '界面显示的剩余百分比（具体额度范围未验证）')} };if($u.Source -eq 'official-codex' -and $null -ne $s.Usage){if($u.WindowMinutes -ne 10080 -or [long]$u.ResetAt -le 0){$s.Usage=$null}else{[DateTimeOffset]::FromUnixTimeSeconds([long]$u.ResetAt)|Out-Null;$s.Usage.ResetAt=[long]$u.ResetAt;$s.Usage.WindowMinutes=10080;$s.Usage.Metric='Codex/Work shared weekly quota'}} } catch {$s.Usage=$null}
    }
    return $s
}
function Get-DragonPosition($State, [double]$Left, [double]$Top, [double]$Width, [double]$Height) {
    $maxX=[Math]::Max(0,$Width-$State.Size);$maxY=[Math]::Max(0,$Height-$State.Size)
    $x=if ($State.Edge -eq 'left'){0}elseif($State.Edge -eq 'right'){$maxX}else{$State.X*$maxX}
    return @{Left=$Left+$x;Top=$Top+$State.Y*$maxY}
}
function Get-DragonUsage($State, $Now=[DateTimeOffset]::UtcNow) {
    if ($null -eq $State.Usage) { return (T '每周限额不可用（尚无有效官方读数）。请检查官方客户端登录并刷新。') }
    $u=$State.Usage;$time=[DateTimeOffset]::Parse($u.ReadAt)
    if($u.Source -eq 'official-codex'){
        $reset=[DateTimeOffset]::FromUnixTimeSeconds($u.ResetAt)
        $stale=if(($Now-$time).TotalMinutes -gt ([double]$State.RefreshMinutes+1) -or $reset -le $Now){(T '旧值 / 待刷新')}else{(T '官方周期读取')}
        return (T "每周限额剩余：$($u.Percent)%`n重置：$($reset.ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss zzz'))`n来源：官方 Codex account/rateLimits/read`n更新时间：$($time.ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss')) · $stale`n范围：Codex / Work 共享周限额；不含普通聊天，不是 credits。")
    }

    $age=if (($Now-$time).TotalMinutes -ge 30){(T '已过期（超过30分钟）')}else{(T '手动记录，非实时')}
    $source=if($u.Source -eq 'manual-paste'){(T '手动粘贴文字')}else{(T '手动录入')}
    return (T "剩余：$($u.Percent)%`n来源：$source · $age`n记录时间：$($time.ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss zzz'))`n额度范围未验证；余额 / 今日消耗：不可用。")
}
function Get-DragonLine($State, [int]$Index) {
    $i=if($State.Mode -eq 'random'){Get-Random -Minimum 0 -Maximum $State.Lines.Count}else{$Index % $State.Lines.Count}
    $line=$State.Lines[$i];if($line -in @('呵，就这？','累了就休息一下吧。','我的用量数据还没有可靠来源。')){return (T $line)};return $line
}
function Test-DragonImagePath([string]$Path) {
    # Exclude URL, UNC and mapped network drives; image decoding must never fetch remote data.
    if ($Path -notmatch '^[A-Za-z]:\\' -or $Path.StartsWith('\\') -or [IO.Path]::GetExtension($Path).ToLower() -notin @('.png','.jpg','.jpeg')) {return $false}
    try { $drive=New-Object IO.DriveInfo([IO.Path]::GetPathRoot($Path)); return $drive.DriveType -in @([IO.DriveType]::Fixed,[IO.DriveType]::Removable) -and [IO.File]::Exists($Path) } catch {return $false}
}
function Read-ManualUsage([string]$Text) {
    $text=$Text.Trim()
    if(!$text){return $null}
    if($text.Length -gt 100){throw (T '只粘贴剩余百分比片段，不要粘贴账户或聊天内容。')}
    $source='manual'
    if($text -match '^(?:(?:使用情况|Usage)\s*)?(?:剩余|Remaining)\s*([0-9]{1,3}(?:\.[0-9]{1,2})?)\s*[%％]$'){$value=$Matches[1];$source='manual-paste'}
    elseif($text -match '^([0-9]{1,3}(?:\.[0-9]{1,2})?)\s*[%％]?$'){$value=$Matches[1]}
    else {throw (T '请输入0–100，或仅粘贴“剩余 50%”这样的单一片段。')}
    $percent=[double]::Parse($value,[Globalization.CultureInfo]::InvariantCulture)
    if($percent -gt 100){throw (T '剩余百分比必须在0–100之间。')}
    return @{Percent=$percent;ReadAt=[DateTimeOffset]::UtcNow.ToString('o');Source=$source}
}
