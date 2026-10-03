# Documented official client only. Never open auth files, HTTP endpoints, or conversations.
function Find-OfficialCodex {
    $command=Get-Command codex.exe -ErrorAction SilentlyContinue
    if($command){return $command.Source}
    $root=Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if(Test-Path -LiteralPath $root){$found=Get-ChildItem -LiteralPath $root -Filter codex.exe -Recurse -File|Sort-Object LastWriteTime -Descending|Select-Object -First 1;if($found){return $found.FullName}}
    return $null
}
function Get-QuotaField($Object,[string]$Name){
    if($null -eq $Object){return $null}
    if($Object -is [Collections.IDictionary]){return $Object[$Name]}
    $property=$Object.PSObject.Properties[$Name];if($null -ne $property){return $property.Value};return $null
}
function Test-QuotaNumber($Value){
    if($null -eq $Value){return $false}
    return [Type]::GetTypeCode($Value.GetType()).ToString() -in @('Byte','SByte','Int16','UInt16','Int32','UInt32','Int64','UInt64','Single','Double','Decimal')
}
function Convert-OfficialWeekly($Result) {
    $bucket=Get-QuotaField (Get-QuotaField $Result 'rateLimitsByLimitId') 'codex'
    if($null -eq $bucket){$bucket=Get-QuotaField $Result 'rateLimits'}
    if((Get-QuotaField $bucket 'limitId') -ne 'codex'){throw 'No documented Codex bucket'}
    $windows=@(@((Get-QuotaField $bucket 'primary'),(Get-QuotaField $bucket 'secondary'))|Where-Object {$null -ne $_ -and (Get-QuotaField $_ 'windowDurationMins') -eq 10080})
    if($windows.Count -ne 1){throw 'Weekly quota unavailable or ambiguous'}
    $w=$windows[0];$usedValue=Get-QuotaField $w 'usedPercent';$resetValue=Get-QuotaField $w 'resetsAt'
    if(!(Test-QuotaNumber $usedValue) -or !(Test-QuotaNumber $resetValue)){throw 'Missing or nonnumeric official weekly fields'}
    $used=[double]$usedValue;$reset=[long]$resetValue
    if([double]$resetValue -ne [Math]::Truncate([double]$resetValue)){throw 'Reset timestamp must be whole Unix seconds'}
    [DateTimeOffset]::FromUnixTimeSeconds($reset)|Out-Null
    if([double]::IsNaN($used) -or [double]::IsInfinity($used) -or $used -lt 0 -or $used -gt 100 -or $reset -le [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()){throw 'Invalid or expired weekly reading'}
    return @{Percent=100-$used;UsedPercent=$used;ResetAt=$reset;ReadAt=[DateTimeOffset]::UtcNow.ToString('o');Source='official-codex';Metric='Codex/Work shared weekly quota';WindowMinutes=10080}
}
function Read-OfficialWeekly([Threading.CancellationToken]$Cancellation=[Threading.CancellationToken]::None) {
    $exe=Find-OfficialCodex;if(!$exe){throw 'Official Codex client not installed'}
    $info=New-Object Diagnostics.ProcessStartInfo;$info.FileName=$exe;$info.Arguments='app-server --stdio -c analytics.enabled=false';$info.UseShellExecute=$false;$info.CreateNoWindow=$true;$info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
    $client=New-Object Diagnostics.Process;$client.StartInfo=$info
    $started=$false
    try {
        $Cancellation.ThrowIfCancellationRequested()
        $started=$client.Start();if(!$started){throw 'Official client could not start'}
        # Drain stderr concurrently; discard it so logs cannot block or leak account data.
        $discard=$client.StandardError.ReadToEndAsync()
        $client.StandardInput.WriteLine('{"id":1,"method":"initialize","params":{"clientInfo":{"name":"white_dragon_weekly_widget","version":"1.0.0"}}}')
        $deadline=[DateTime]::UtcNow.AddSeconds(25)
        $stage=1
        while([DateTime]::UtcNow -lt $deadline){
            $line=$client.StandardOutput.ReadLineAsync()
            $remaining=[Math]::Max(1,[int]($deadline-[DateTime]::UtcNow).TotalMilliseconds)
            if(!$line.Wait($remaining,$Cancellation)){throw 'Official quota read timed out'}
            if($null -eq $line.Result){throw 'Official client exited'}
            $reply=$line.Result|ConvertFrom-Json
            if($null -eq $reply.PSObject.Properties['id'] -or $reply.id -ne $stage){continue}
            if($null -ne $reply.PSObject.Properties['error']){throw 'Official client rejected quota request (login or service unavailable)'}
            if($stage -eq 1){$client.StandardInput.WriteLine('{"method":"initialized"}');$client.StandardInput.WriteLine('{"id":2,"method":"account/rateLimits/read"}');$stage=2}
            else{return Convert-OfficialWeekly $reply.result}
        }
        throw 'Official quota read timed out'
    }finally{if($started -and !$client.HasExited){$client.Kill();$client.WaitForExit(3000)|Out-Null};$client.Dispose()}
}
