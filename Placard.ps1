function Get-DragonPlacardRect($State,[double]$PixelWidth,[double]$PixelHeight){
    if($PixelWidth -le 0 -or $PixelHeight -le 0){$PixelWidth=1;$PixelHeight=1}
    $size=$State.Size;$scale=$size/[Math]::Max($PixelWidth,$PixelHeight);$w=$PixelWidth*$scale;$h=$PixelHeight*$scale
    $left=($size-$w)/2;$top=switch($State.Layouts.bust){'Top'{0};'Bottom'{$size-$h};default{($size-$h)/2}}
    $p=$State.Placard;$x=if($State.Edge -eq 'right'){1-$p.X-$p.Width}else{$p.X}
    return @{Left=$left+$x*$w;Top=$top+$p.Y*$h;Width=$p.Width*$w;Height=$p.Height*$h}
}
function Get-DragonResetLabel($Usage,$Now=[DateTimeOffset]::UtcNow){
    if($null -eq $Usage -or $Usage.Source -ne 'official-codex'){return (T '重置时间：不可用')}
    $reset=[DateTimeOffset]::FromUnixTimeSeconds($Usage.ResetAt)
    if($reset -le $Now){return (T '已到重置时间 · 待读取')}
    $remaining=$reset-$Now
    return (T "重置：$($reset.ToLocalTime().ToString('MM-dd HH:mm'))`n约$([Math]::Floor($remaining.TotalDays))天$($remaining.Hours)小时$($remaining.Minutes)分")
}
function Get-DragonAttachedBubbleLayout([double]$Size,[double]$BodyWidth,[double]$BodyHeight,[string]$Edge,$Area){
    # Approved full-body art: mouth x=.55 of source width, y=.48 of source height.
    # Uniform 1205x1306 image centered in the square surface; keep body beyond hair/horns.
    $mouthX=$Size*(.5+(1205.0/1306)*.05);$mouthY=$Size*.48
    $mirror=$Edge -eq 'right';if($mirror){$mouthX=$Size-$mouthX}
    $bodyX=if($mirror){$Size*.10-$BodyWidth}else{$Size*.90}
    $bodyY=$mouthY-$BodyHeight*.95
    $bodyY=[Math]::Max($Area.Top,[Math]::Min($Area.Top+$Area.Height-$BodyHeight,$bodyY))
    $bodyX=[Math]::Max($Area.Left,[Math]::Min($Area.Left+$Area.Width-$BodyWidth,$bodyX))
    $left=[Math]::Min($mouthX,$bodyX);$top=[Math]::Min($mouthY,$bodyY)
    $right=[Math]::Max($mouthX,$bodyX+$BodyWidth);$bottom=[Math]::Max($mouthY,$bodyY+$BodyHeight)
    $baseX=if($mirror){$bodyX+$BodyWidth-3}else{$bodyX+3}
    $baseY=[Math]::Max($bodyY+18,[Math]::Min($bodyY+$BodyHeight-18,$mouthY-12))
    # Only suggest the mouth direction; never draw a connector to the mouth.
    # Preserve the accepted body position and outer layout bounds.
    $tailLength=[Math]::Max(6,[Math]::Min(12,$Size*.05))
    $tailWidth=[Math]::Max(6,[Math]::Min(12,$Size*.05))
    $tipX=$baseX+$(if($mirror){$tailLength}else{-$tailLength})
    $tipY=$baseY+$tailWidth/2+[Math]::Sign($mouthY-($baseY+$tailWidth/2))*$tailLength*.2
    $culture=[Globalization.CultureInfo]::InvariantCulture
    $tail='M {0},{1} L {2},{3} L {4},{5} Z' -f ($tipX-$left).ToString($culture),($tipY-$top).ToString($culture),($baseX-$left).ToString($culture),($baseY-$top).ToString($culture),($baseX-$left).ToString($culture),($baseY+$tailWidth-$top).ToString($culture)
    return @{Left=$left;Top=$top;Width=$right-$left;Height=$bottom-$top;BodyX=$bodyX-$left;BodyY=$bodyY-$top;Tail=$tail;MouthX=$mouthX;MouthY=$mouthY;TailLength=$tailLength;TailWidth=$tailWidth;TipX=$tipX;TipY=$tipY}
}

function Get-DragonExpressionPlacardRect($State,[double]$Width,[double]$Height,[string]$Mood){
    if($Mood -eq 'smug'){$frame=$State.Placard}else{$frame=Get-DragonField $State.ExpressionPlacards $Mood}
    # A raised/new placard must be calibrated from real pixels before overlaying it.
    if($null -eq $frame){return $null}
    $layout=@{Size=$State.Size;Layouts=$State.Layouts;Edge=$State.Edge;Placard=$frame}
    return Get-DragonPlacardRect $layout $Width $Height
}
