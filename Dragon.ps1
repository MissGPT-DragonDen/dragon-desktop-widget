param([string]$SettingsPath='', [switch]$Restore, [string]$StartupDirectory='' )
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Windows.Forms
if(-not ('DragonDesktopIdentity' -as [type])){
    Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public static class DragonDesktopIdentity { [DllImport("shell32.dll", CharSet=CharSet.Unicode)] public static extern int SetCurrentProcessExplicitAppUserModelID(string id); [DllImport("user32.dll",SetLastError=true)] public static extern bool SetWindowPos(System.IntPtr h,System.IntPtr after,int x,int y,int cx,int cy,uint flags); }'
}
[DragonDesktopIdentity]::SetCurrentProcessExplicitAppUserModelID('WhiteDragonWidget.Public')|Out-Null
. "$PSScriptRoot\I18n.ps1"
. "$PSScriptRoot\State.ps1"
. "$PSScriptRoot\Quota.ps1"
. "$PSScriptRoot\Placard.ps1"
. "$PSScriptRoot\Startup.ps1"
if (!$SettingsPath) {$SettingsPath=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WhiteDragonWidgetPublic\settings.json'}
$script:restoreSignal=Join-Path (Split-Path -Parent $SettingsPath) 'restore.request'
if($Restore){[IO.Directory]::CreateDirectory((Split-Path -Parent $SettingsPath))|Out-Null;[IO.File]::WriteAllText($script:restoreSignal,'restore');exit 0}
# Session-local, current-user single instance keyed by settings location, not install folder.
$script:instanceMutex=$null;$script:instanceHeld=$false
& {
    $script:instanceMutex=New-Object Threading.Mutex($false,(Get-DragonInstanceName $SettingsPath))
    try{$script:instanceHeld=$script:instanceMutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$script:instanceHeld=$true}
    if(!$script:instanceHeld){[IO.Directory]::CreateDirectory((Split-Path -Parent $SettingsPath))|Out-Null;[IO.File]::WriteAllText($script:restoreSignal,'restore');$script:instanceMutex.Dispose();exit 0}
}
$script:state=New-DragonState
try { if(Test-Path -LiteralPath $SettingsPath){$raw=Get-Content -LiteralPath $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json;$map=@{};foreach($p in $raw.PSObject.Properties){$map[$p.Name]=$p.Value};$script:state=Convert-DragonState $map} } catch {}
$script:uiLanguage=$script:state.Language
function Get-BundledDragonImage([string]$Slot){$name=if($Slot -eq 'bust'){'smug-halfbody-placard.png'}else{'smug-full.png'};return Join-Path $PSScriptRoot ('assets\'+$name)}
foreach($slot in @('full','bust')){if(!$script:state.Images[$slot]){$bundled=Get-BundledDragonImage $slot;if(Test-Path -LiteralPath $bundled){$script:state.Images[$slot]=$bundled}}}
$script:lineIndex=0;$script:dragged=$false;$script:held=$false;$script:pressed=$false
function Save-State {
    if((Test-Path -LiteralPath $SettingsPath) -and !(Test-Path -LiteralPath ($SettingsPath+'.pre-v4.bak'))){
        try{Copy-Item -LiteralPath $SettingsPath -Destination ($SettingsPath+'.pre-v4.bak') -ErrorAction Stop}catch{Show-Bubble (T '升级配置备份失败；当前配置未覆盖。');return}
    }
    try { $directory=Split-Path -Parent $SettingsPath; if(!(Test-Path -LiteralPath $directory)){[IO.Directory]::CreateDirectory($directory)|Out-Null};$temporary=$SettingsPath+'.tmp';$script:state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $temporary -Encoding UTF8;Move-Item -LiteralPath $temporary -Destination $SettingsPath -Force } catch { Show-Bubble (T '设置保存失败；退出后可能丢失本次更改。') }
}
[xml]$xaml=(T @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="PetWindow" Title="白毛龙娘挂件 · 开发候选" Width="180" Height="180" WindowStyle="None" AllowsTransparency="True" Background="Transparent" ResizeMode="NoResize" ShowInTaskbar="False" Topmost="True">
 <Grid x:Name="Surface" Background="Transparent">
  <Grid x:Name="Art" RenderTransformOrigin="0.5,0.7">
   <Grid.RenderTransform><TransformGroup><ScaleTransform x:Name="Facing" ScaleX="1"/><ScaleTransform x:Name="Squash"/></TransformGroup></Grid.RenderTransform>
   <Image x:Name="Character" Stretch="Uniform" IsHitTestVisible="False"/>
   <Border x:Name="Placeholder" CornerRadius="54" Margin="18" Background="#FFF8FF" BorderBrush="#A993CA" BorderThickness="3" RenderTransformOrigin="0.5,0.5"><Border.RenderTransform><ScaleTransform x:Name="PlaceholderFacing"/></Border.RenderTransform><StackPanel VerticalAlignment="Center"><TextBlock x:Name="PlaceholderTitle" Text="全身Q版" FontSize="20" Foreground="#6A518B" HorizontalAlignment="Center"/><TextBlock Text="¬‿¬" FontSize="35" Foreground="#6A518B" HorizontalAlignment="Center"/><TextBlock Text="开发占位 · 非成品" FontSize="11" Foreground="#856D46" HorizontalAlignment="Center"/></StackPanel></Border>
  </Grid>
  <Canvas x:Name="PlacardCanvas" Visibility="Collapsed">
   <Border x:Name="QuotaPlacard" Background="#9914131A" BorderBrush="Transparent" BorderThickness="0" CornerRadius="2" Cursor="Hand">
    <Viewbox Stretch="Uniform"><StackPanel Width="240" Margin="4,1" TextElement.FontFamily="Segoe UI, Microsoft YaHei UI"><TextBlock Text="每周限额" Foreground="#DDD4E7" FontSize="16" HorizontalAlignment="Center"/><TextBlock x:Name="PlacardPercent" Text="待读取" Foreground="White" FontSize="36" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="PlacardReset" Foreground="#D5CFDF" FontSize="18" TextAlignment="Center"/><TextBlock x:Name="PlacardStatus" Foreground="#B2A5CA" FontSize="11" TextAlignment="Center"/></StackPanel></Viewbox>
   </Border>
  </Canvas>
  <Border x:Name="QuotaBadgeBorder" VerticalAlignment="Bottom" HorizontalAlignment="Center" Background="#EFFFFFFF" CornerRadius="6" Padding="5,2" IsHitTestVisible="False"><TextBlock x:Name="QuotaBadge" Text="周限额：待读取" FontSize="12" Foreground="#493363"/></Border>
 </Grid>
</Window>
'@)
$reader=New-Object Xml.XmlNodeReader $xaml;$script:window=[Windows.Markup.XamlReader]::Load($reader)
function Find($name){return $script:window.FindName($name)}
$script:surface=Find 'Surface';$script:character=Find 'Character';$script:placeholder=Find 'Placeholder';$script:facing=Find 'Facing';$script:squash=Find 'Squash'
$script:menu=New-Object Windows.Controls.ContextMenu
$script:appearanceItems=@{};$script:layoutItems=@{}
$script:window.ContextMenu=$script:menu
$script:bubble=New-Object Windows.Controls.Primitives.Popup
$script:bubble.PlacementTarget=$script:surface;$script:bubble.Placement='Top';$script:bubble.AllowsTransparency=$true;$script:bubble.StaysOpen=$false
$bubbleBorder=New-Object Windows.Controls.Border;$bubbleBorder.Background=[Windows.Media.Brushes]::White;$bubbleBorder.CornerRadius=14;$bubbleBorder.BorderThickness=1;$bubbleBorder.BorderBrush=[Windows.Media.Brushes]::Thistle;$bubbleBorder.Padding=14
$script:bubbleText=New-Object Windows.Controls.TextBlock;$script:bubbleText.MaxWidth=300;$script:bubbleText.TextWrapping='Wrap';$script:bubbleText.Foreground=[Windows.Media.Brushes]::DarkSlateBlue;$bubbleBorder.Child=$script:bubbleText;$script:bubble.Child=$bubbleBorder
$script:bubbleTimer=New-Object Windows.Threading.DispatcherTimer;$script:bubbleTimer.Interval=[TimeSpan]::FromSeconds(9);$script:bubbleTimer.Add_Tick({$script:bubble.IsOpen=$false;$script:bubbleTimer.Stop()})
[xml]$quotaBubbleXaml=(T @'
<Canvas xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" x:Name="FullQuotaSurface" Background="Transparent">
 <Border x:Name="BubbleBody" Background="#FFF9F5FF" BorderBrush="#B69BD6" BorderThickness="1.5" CornerRadius="18" Padding="12,8">
  <Viewbox Stretch="Uniform"><StackPanel Width="220" TextElement.FontFamily="Segoe UI, Microsoft YaHei UI"><TextBlock Text="每周限额" Foreground="#796189" FontSize="14"/><TextBlock x:Name="FullPercent" Foreground="#50386D" FontSize="34" FontWeight="SemiBold"/><TextBlock x:Name="FullReset" Foreground="#735E85" FontSize="13"/><TextBlock x:Name="FullStatus" Foreground="#987CA6" FontSize="11"/></StackPanel></Viewbox>
 </Border>
 <Path x:Name="BubbleTail" Data="M0,0 L14,0 L0,10 Z" Fill="#FFF9F5FF" Stroke="#B69BD6" StrokeThickness="1"/>
</Canvas>
'@)
$script:fullQuotaVisual=[Windows.Markup.XamlReader]::Load((New-Object Xml.XmlNodeReader $quotaBubbleXaml))
$script:fullQuotaPopup=New-Object Windows.Controls.Primitives.Popup;$script:fullQuotaPopup.Child=$script:fullQuotaVisual;$script:fullQuotaPopup.AllowsTransparency=$true;$script:fullQuotaPopup.StaysOpen=$true;$script:fullQuotaPopup.Placement='AbsolutePoint'
$script:fullQuotaVisual.FindName('FullReset').TextWrapping='Wrap'
$script:fullQuotaVisual.Add_MouseLeftButtonUp({Show-QuotaDetails})
$script:window.Add_Closed({$script:fullQuotaPopup.IsOpen=$false})
$script:window.Add_LocationChanged({if($null -ne (Get-Command Update-FullQuotaBubble -ErrorAction SilentlyContinue)){Update-FullQuotaBubble}})
$script:window.Add_StateChanged({if($null -ne (Get-Command Update-FullQuotaBubble -ErrorAction SilentlyContinue)){Update-FullQuotaBubble}})
function Show-Bubble([string]$Text){$script:bubbleText.Text=$Text;$script:bubble.IsOpen=$true;$script:bubbleTimer.Stop();$script:bubbleTimer.Start()}
function Set-DragonLanguage([string]$Language){
    if($Language -notin @('zh','en')){return}
    $script:state.Language=$Language;$script:uiLanguage=$Language
    Refresh-UiNode $script:surface;Refresh-UiNode $script:menu;Refresh-UiNode $script:fullQuotaVisual
    $script:trayShow.Text=T '显示 / 恢复';$script:trayHide.Text=T '隐藏';$script:trayExit.Text=T '退出'
    $script:tray.Text=T '白毛龙娘挂件 · 双击恢复';$script:window.Title=T '白毛龙娘挂件 · 开发候选'
    foreach($item in $intervalMenu.Items){$item.Header="$($item.Tag)$(T ' 分钟')"}
    foreach($item in $languageMenu.Items){$item.IsChecked=$item.Tag -eq $Language}
    Apply-State;Update-StartupMenu|Out-Null;Save-State
}
function Show-DragonWindow {$script:window.WindowState='Normal';$script:window.Show();$script:window.Activate()|Out-Null;Update-QuotaBadge}
function Hide-DragonWindow {$script:bubble.IsOpen=$false;$script:menu.IsOpen=$false;$script:fullQuotaPopup.IsOpen=$false;$script:window.Hide()}
function Get-WorkArea { return [Windows.SystemParameters]::WorkArea }
function Apply-State {
    $active=$script:state.Appearance
    $script:state.Image=$script:state.Images[$active];$script:state.Size=$script:state.Sizes[$active]
    $script:window.Width=$script:state.Size;$script:window.Height=$script:state.Size;$script:window.Topmost=$script:state.Topmost
    $a=Get-WorkArea;$p=Get-DragonPosition $script:state $a.Left $a.Top $a.Width $a.Height;$script:window.Left=$p.Left;$script:window.Top=$p.Top
    $script:facing.ScaleX=if($script:state.Edge -eq 'right'){-1}else{1}
    (Find 'PlaceholderFacing').ScaleX=$script:facing.ScaleX
    (Find 'PlaceholderTitle').Text=if($active -eq 'full'){(T '全身Q版')}else{(T '半身像')}
    $script:character.VerticalAlignment=$script:state.Layouts[$active]
    $script:character.HorizontalAlignment='Center';$script:character.Stretch='Uniform'
    foreach($key in $script:appearanceItems.Keys){$script:appearanceItems[$key].IsChecked=$key -eq $active}
    foreach($key in $script:layoutItems.Keys){$script:layoutItems[$key].IsChecked=$key -eq $script:state.Layouts[$active]}
    $script:character.Source=$null;$script:placeholder.Visibility='Visible'
    if($script:state.Image){
      try{if(!(Test-DragonImagePath $script:state.Image)){throw (T '只支持本地图片')};if((Get-Item -LiteralPath $script:state.Image).Length -gt 10MB){throw (T '图片过大')};$bitmap=New-Object Windows.Media.Imaging.BitmapImage;$bitmap.BeginInit();$bitmap.CacheOption='OnLoad';$bitmap.CreateOptions='IgnoreImageCache';$bitmap.UriSource=New-Object Uri($script:state.Image);$bitmap.EndInit();$bitmap.Freeze();if($bitmap.PixelWidth -gt 4096 -or $bitmap.PixelHeight -gt 4096){throw (T '图片过大')};$script:character.Source=$bitmap;$script:placeholder.Visibility='Collapsed'}catch{Show-Bubble (T '当前形象图片不可用，显示开发占位；另一槽位保留。')}
    }
    Update-Placard
    Update-FullQuotaBubble
}
function Remember-Position([bool]$Snap=$true){
    $a=Get-WorkArea;$mx=[Math]::Max(0,$a.Width-$script:state.Size);$my=[Math]::Max(0,$a.Height-$script:state.Size)
    $x=[Math]::Max(0,[Math]::Min($mx,$script:window.Left-$a.Left));$y=[Math]::Max(0,[Math]::Min($my,$script:window.Top-$a.Top));$script:state.Edge='free'
    if($Snap -and $x -le 48){$x=0;$script:state.Edge='left'}elseif($Snap -and $mx-$x -le 48){$x=$mx;$script:state.Edge='right'}
    $script:state.X=if($mx){$x/$mx}else{0};$script:state.Y=if($my){$y/$my}else{0};Apply-State;Save-State
}
function Add-Menu([string]$Header,[scriptblock]$Handler){$item=New-Object Windows.Controls.MenuItem;$item.Header=$Header;$item.Add_Click($Handler);$script:menu.Items.Add($item)|Out-Null}
function Speak { Show-Bubble (Get-DragonLine $script:state $script:lineIndex);$script:lineIndex++ }
function Set-DragonAppearance([string]$Slot){
    if($Slot -notin @('full','bust')){return}
    $script:state.Appearance=$Slot;Apply-State;Save-State
}
function Change-DragonSize([int]$Delta){
    $slot=$script:state.Appearance;$script:state.Sizes[$slot]=[Math]::Max(80,[Math]::Min(320,$script:state.Sizes[$slot]+$Delta));Apply-State;Save-State
}
function Import-LocalCharacter([string]$Path,[string]$Slot=''){
    try{
      if(!$Slot){$Slot=$script:state.Appearance};if($Slot -notin @('full','bust')){throw (T '未知角色槽位。')}
      if(!(Test-DragonImagePath $Path)){throw (T '只允许本机磁盘上的 PNG / JPEG，不支持网络位置。')}
      $info=Get-Item -LiteralPath $Path;if($info.Length -gt 10MB){throw (T '图片不得超过10 MiB。')}
      # Decode before copying or replacing settings, so invalid input keeps the previous image.
      $bitmap=New-Object Windows.Media.Imaging.BitmapImage;$bitmap.BeginInit();$bitmap.CacheOption='OnLoad';$bitmap.CreateOptions='IgnoreImageCache';$bitmap.UriSource=New-Object Uri($info.FullName);$bitmap.EndInit();$bitmap.Freeze()
      if($bitmap.PixelWidth -gt 4096 -or $bitmap.PixelHeight -gt 4096){throw (T '图片不得超过4096×4096。')}
      $assetDirectory=Join-Path (Split-Path -Parent $SettingsPath) 'assets';[IO.Directory]::CreateDirectory($assetDirectory)|Out-Null
      $asset=Join-Path $assetDirectory ('character-'+$Slot+$info.Extension.ToLower())
      if(![string]::Equals($info.FullName,$asset,[StringComparison]::OrdinalIgnoreCase)){
        $temporary=$asset+'.tmp';Copy-Item -LiteralPath $info.FullName -Destination $temporary -Force;Move-Item -LiteralPath $temporary -Destination $asset -Force
      }
      $script:state.Images[$Slot]=$asset;Apply-State;Save-State;return $true
    }catch{Show-Bubble ((T '图片导入失败：')+$_.Exception.Message);return $false}
}
Add-Menu (T '说一句') {Speak}
Add-Menu (T 'ChatGPT 用量状态') {Show-QuotaDetails}
Add-Menu (T '设置台词 / 手动用量') {Open-Settings}
function Select-LocalCharacter([string]$Slot=''){
    $dialog=New-Object Microsoft.Win32.OpenFileDialog;$dialog.Filter=(T '角色图片|*.png;*.jpg;*.jpeg');if($dialog.ShowDialog($script:window)){
      Import-LocalCharacter $dialog.FileName $Slot|Out-Null
    }
}
Add-Menu (T '导入当前形象 PNG / JPEG') {Select-LocalCharacter}
Add-Menu (T '恢复当前内置形象') {$slot=$script:state.Appearance;$script:state.Images[$slot]=Get-BundledDragonImage $slot;Apply-State;Save-State}
Add-Menu (T '缩小当前形象') {Change-DragonSize -20}
Add-Menu (T '放大当前形象') {Change-DragonSize 20}
Add-Menu (T '回到右下角') {$script:state.X=1;$script:state.Y=.85;$script:state.Edge='right';Apply-State;Save-State}
Add-Menu (T '切换始终置顶') {$script:state.Topmost=!$script:state.Topmost;Apply-State;Save-State}
Add-Menu (T '隐藏到托盘') {Hide-DragonWindow}
$appearanceMenu=New-Object Windows.Controls.MenuItem;$appearanceMenu.Header=(T '角色形象');$script:menu.Items.Add($appearanceMenu)|Out-Null
foreach($slot in @('full','bust')){
    $item=New-Object Windows.Controls.MenuItem;$item.Header=if($slot -eq 'full'){(T '全身Q版')}else{(T '半身像')};$item.IsCheckable=$true;$item.Tag=$slot
    $item.Add_Click({param($sender,$event);Set-DragonAppearance $sender.Tag});$script:appearanceItems[$slot]=$item;$appearanceMenu.Items.Add($item)|Out-Null
}
$slotImportMenu=New-Object Windows.Controls.MenuItem;$slotImportMenu.Header=(T '分别导入角色图');$script:menu.Items.Add($slotImportMenu)|Out-Null
foreach($slot in @('full','bust')){
    $item=New-Object Windows.Controls.MenuItem;$item.Header=if($slot -eq 'full'){(T '导入全身Q版 PNG / JPEG')}else{(T '导入半身像 PNG / JPEG')};$item.Tag=$slot
    $item.Add_Click({param($sender,$event);Select-LocalCharacter $sender.Tag});$slotImportMenu.Items.Add($item)|Out-Null
}
$layoutMenu=New-Object Windows.Controls.MenuItem;$layoutMenu.Header=(T '当前形象布局');$script:menu.Items.Add($layoutMenu)|Out-Null
foreach($layout in @('Bottom','Center','Top')){
    $item=New-Object Windows.Controls.MenuItem;$item.Header=@{Bottom=(T '底部对齐');Center=(T '居中');Top=(T '顶部对齐')}[$layout];$item.Tag=$layout;$item.IsCheckable=$true
    $item.Add_Click({param($sender,$event);$script:state.Layouts[$script:state.Appearance]=$sender.Tag;Apply-State;Save-State});$script:layoutItems[$layout]=$item;$layoutMenu.Items.Add($item)|Out-Null
}
Add-Menu (T '退出') {$script:window.Close()}
function Open-Menu{$script:menu.PlacementTarget=$script:surface;$script:menu.IsOpen=$true}
$script:holdTimer=New-Object Windows.Threading.DispatcherTimer;$script:holdTimer.Interval=[TimeSpan]::FromMilliseconds(550);$script:holdTimer.Add_Tick({$script:holdTimer.Stop();if($script:pressed -and !$script:dragged){$script:held=$true;Open-Menu}})
$script:surface.Add_MouseLeftButtonDown({
    param($sender,$e)
    if($e.OriginalSource -is [Windows.Controls.Button] -or $script:menu.IsOpen){return}
    $script:startPoint=$e.GetPosition($script:window);$script:startLeft=$script:window.Left;$script:startTop=$script:window.Top;$script:dragged=$false;$script:held=$false;$script:pressed=$true;$script:squash.ScaleX=1.08;$script:squash.ScaleY=.90;$script:surface.CaptureMouse()|Out-Null;$script:holdTimer.Start();$e.Handled=$true
})
$script:surface.Add_MouseMove({param($sender,$e)
    if(!$script:pressed){return};$p=$e.GetPosition($script:window);$dx=$p.X-$script:startPoint.X;$dy=$p.Y-$script:startPoint.Y
    if([Math]::Abs($dx)+[Math]::Abs($dy) -gt 5){$script:dragged=$true;$script:holdTimer.Stop();$script:window.Left+=$dx;$script:window.Top+=$dy}
})
function Release-Pet([bool]$Cancelled){
    if(!$script:pressed){return};$script:pressed=$false;$script:holdTimer.Stop();$script:squash.ScaleX=1;$script:squash.ScaleY=1;$script:surface.ReleaseMouseCapture()
    if($script:dragged){Remember-Position}elseif(!$Cancelled -and !$script:held){Speak}
}
$script:surface.Add_MouseLeftButtonUp({Release-Pet $false});$script:surface.Add_LostMouseCapture({Release-Pet $true})
$script:window.Add_KeyDown({param($sender,$e)
    switch($e.Key){'Escape'{$script:bubble.IsOpen=$false;$script:menu.IsOpen=$false};'Left'{$script:window.Left-=12;Remember-Position};'Right'{$script:window.Left+=12;Remember-Position};'Up'{$script:window.Top-=12;Remember-Position};'Down'{$script:window.Top+=12;Remember-Position};'Space'{Speak}}
})
function Open-Settings {
    $dialog=New-Object Windows.Window;$dialog.Title=(T '台词与手动用量 · 无自动读取');$dialog.Width=430;$dialog.Height=520;$dialog.Owner=$script:window;$dialog.WindowStartupLocation='CenterOwner';$dialog.ResizeMode='NoResize'
    $panel=New-Object Windows.Controls.StackPanel;$panel.Margin=18;$dialog.Content=$panel
    function Label($text){$label=New-Object Windows.Controls.TextBlock;$label.Text=$text;$label.TextWrapping='Wrap';$label.Margin='0,7,0,5';$panel.Children.Add($label)|Out-Null}
    Label (T '台词：每行一句，最多30句，每句160字。')
    $lines=New-Object Windows.Controls.TextBox;$lines.AcceptsReturn=$true;$lines.Height=130;$lines.VerticalScrollBarVisibility='Auto';$lines.Text=$script:state.Lines -join "`r`n";$panel.Children.Add($lines)|Out-Null
    $random=New-Object Windows.Controls.CheckBox;$random.Content=(T '随机台词');$random.IsChecked=$script:state.Mode -eq 'random';$random.Margin='0,8,0,8';$panel.Children.Add($random)|Out-Null
    Label (T '手动输入0–100，或主动粘贴“剩余 50%”片段。不是实时查询。留空不更新记录。')
    $percent=New-Object Windows.Controls.TextBox;$percent.MaxLength=100;$panel.Children.Add($percent)|Out-Null
    $clear=New-Object Windows.Controls.CheckBox;$clear.Content=(T '清除手动用量记录');$clear.Margin='0,8,0,8';$panel.Children.Add($clear)|Out-Null
    Label (T '来源与时间始终标注；30分钟后显示过期。未接入自动来源。不读取屏幕、账号或聊天。')
    $errorLabel=New-Object Windows.Controls.TextBlock;$errorLabel.Foreground=[Windows.Media.Brushes]::Firebrick;$panel.Children.Add($errorLabel)|Out-Null
    $save=New-Object Windows.Controls.Button;$save.Content=(T '保存');$save.Margin='0,8,0,0';$save.Padding=8;$panel.Children.Add($save)|Out-Null
    $save.Add_Click({
      $reading=$null
      if($percent.Text.Trim() -and (!$clear.IsChecked)){try{$reading=Read-ManualUsage $percent.Text}catch{$errorLabel.Text=$_.Exception.Message;return}}
      $script:state.Lines=@($lines.Text -split '\r?\n');$script:state.Mode=if($random.IsChecked){'random'}else{'sequence'}
      if($clear.IsChecked){$script:state.Usage=$null}elseif($null -ne $reading){$script:state.Usage=$reading}
      $script:state=Convert-DragonState $script:state;$script:lineIndex=0;Save-State;$dialog.Close()
    });$dialog.ShowDialog()|Out-Null
}
$script:window.Add_Closed({$script:bubbleTimer.Stop();$script:holdTimer.Stop()})
# User-triggered local recovery, independent of taskbar automation or global hotkeys.
$script:restoreTimer=New-Object Windows.Threading.DispatcherTimer;$script:restoreTimer.Interval=[TimeSpan]::FromMilliseconds(500)
$script:restoreTimer.Add_Tick({
    if(Test-Path -LiteralPath $script:restoreSignal){
      Remove-Item -LiteralPath $script:restoreSignal -ErrorAction SilentlyContinue
      Show-DragonWindow
    }
});$script:restoreTimer.Start();$script:window.Add_Closed({$script:restoreTimer.Stop()})
# Background bounded read; keep the desktop dispatcher responsive while official client fetches.
$script:quotaWorker=$null;$script:quotaCancellation=$null;$script:quotaFailed=$false;$script:nextQuotaRead=[DateTime]::UtcNow
function Show-QuotaDetails {
    $message=Get-DragonUsage $script:state
    if($script:quotaFailed){$message=(T '上次官方刷新失败；保留旧读数。')+[Environment]::NewLine+$message}
    $mode=if($script:state.AutoRefresh){(T "每$($script:state.RefreshMinutes)分钟自动刷新")}else{(T '自动刷新已关闭')}
    if($script:quotaWorker){$mode+=(T ' · 正在读取')}
    if($null -ne $script:state.Usage -and $script:state.Usage.Source -eq 'official-codex'){$countdown=(Get-DragonResetLabel $script:state.Usage) -split "`n";$mode+=[Environment]::NewLine+$countdown[-1]}
    Show-Bubble ($message+[Environment]::NewLine+$mode)
}
function Update-Placard {
    (Find 'PlacardPercent').FontSize=if($script:uiLanguage -eq 'en'){26}else{36}
    (Find 'PlacardReset').TextWrapping='Wrap'
    $bust=$script:state.Appearance -eq 'bust'
    (Find 'PlacardCanvas').Visibility=if($bust){'Visible'}else{'Collapsed'}
    (Find 'QuotaBadgeBorder').Visibility='Collapsed'
    if(!$bust){return}
    $source=$script:character.Source;$pw=if($source){$source.PixelWidth}else{1};$ph=if($source){$source.PixelHeight}else{1}
    $rect=Get-DragonPlacardRect $script:state $pw $ph;$panel=Find 'QuotaPlacard'
    [Windows.Controls.Canvas]::SetLeft($panel,$rect.Left);[Windows.Controls.Canvas]::SetTop($panel,$rect.Top);$panel.Width=$rect.Width;$panel.Height=$rect.Height
    $u=$script:state.Usage
    $official=$null -ne $u -and $u.Source -eq 'official-codex'
    (Find 'PlacardPercent').Text=if($official){(T "剩余 $($u.Percent)%")}else{(T '暂不可用')}
    (Find 'PlacardReset').Text=((Get-DragonResetLabel $u) -split "`n")[0]
    (Find 'QuotaPlacard').ToolTip=(Get-DragonResetLabel $u)+(T ' · 点击展开官方来源')
    $old=$official -and ($script:quotaFailed -or ([DateTimeOffset]::UtcNow-[DateTimeOffset]::Parse($u.ReadAt)).TotalMinutes -gt ($script:state.RefreshMinutes+1) -or [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -ge $u.ResetAt)
    (Find 'PlacardStatus').Visibility=if($script:quotaWorker -or $old){'Visible'}else{'Collapsed'}
    (Find 'PlacardStatus').Text=if($script:quotaWorker){(T '刷新中 · 点击查看来源')}elseif($old){(T '旧值 · 点击查看刷新状态')}else{(T '点击查看来源 / 刷新状态')}
}
(Find 'QuotaPlacard').Add_MouseLeftButtonDown({param($sender,$e) $e.Handled=$true})
(Find 'QuotaPlacard').Add_MouseLeftButtonUp({param($sender,$e) $e.Handled=$true;Show-QuotaDetails})
function Open-PlacardLayout {
    $dialog=New-Object Windows.Window;$dialog.Title=(T '半身用量牌位置（相对图片）');$dialog.Width=360;$dialog.Height=310;$dialog.Owner=$script:window;$dialog.WindowStartupLocation='CenterOwner';$dialog.ResizeMode='NoResize'
    $stack=New-Object Windows.Controls.StackPanel;$stack.Margin=16;$dialog.Content=$stack;$sliders=@{}
    foreach($key in @('X','Y','Width','Height')){$label=New-Object Windows.Controls.TextBlock;$label.Text=$key;$stack.Children.Add($label)|Out-Null;$slider=New-Object Windows.Controls.Slider;$slider.Minimum=if($key -in @('Width','Height')){.10}else{0};$slider.Maximum=if($key -in @('X','Y')){.85}else{1};$slider.Value=$script:state.Placard[$key];$sliders[$key]=$slider;$stack.Children.Add($slider)|Out-Null}
    $save=New-Object Windows.Controls.Button;$save.Content=(T '保存牌子布局');$save.Margin='0,12,0,0';$stack.Children.Add($save)|Out-Null
    $save.Add_Click({foreach($key in $sliders.Keys){$script:state.Placard[$key]=$sliders[$key].Value};$script:state.Placard.Width=[Math]::Min($script:state.Placard.Width,1-$script:state.Placard.X);$script:state.Placard.Height=[Math]::Min($script:state.Placard.Height,1-$script:state.Placard.Y);Update-Placard;Save-State;$dialog.Close()})
    $dialog.ShowDialog()|Out-Null
}
function Update-FullQuotaBubble {
    $script:fullQuotaVisual.FindName('FullPercent').FontSize=if($script:uiLanguage -eq 'en'){26}else{34}
    if($null -eq $script:fullQuotaPopup){return}
    $show=$script:state.Appearance -eq 'full' -and $script:window.IsVisible -and $script:window.WindowState -eq 'Normal'
    if(!$show){$script:fullQuotaPopup.IsOpen=$false;return}
    if($null -eq [Windows.PresentationSource]::FromVisual($script:surface)){return}
    $u=$script:state.Usage;$official=$null -ne $u -and $u.Source -eq 'official-codex'
    $script:fullQuotaVisual.FindName('FullPercent').Text=if($official){(T "剩余 $($u.Percent)%")}else{(T '暂不可用')}
    $script:fullQuotaVisual.FindName('FullReset').Text=Get-DragonResetLabel $u
    $old=$official -and ($script:quotaFailed -or ([DateTimeOffset]::UtcNow-[DateTimeOffset]::Parse($u.ReadAt)).TotalMinutes -gt ($script:state.RefreshMinutes+1) -or [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -ge $u.ResetAt)
    $script:fullQuotaVisual.FindName('FullStatus').Text=if($script:quotaWorker){(T '刷新中 · 点击展开')}elseif($old){(T '旧值 · 点击查看状态')}else{(T '点击查看来源 / 更新时间')}
    Position-FullQuotaBubble
    # A resized Popup can retain its preceding measured bounds until WPF renders.
    # Reposition once afterwards so native edge avoidance does not use stale width.
    $script:window.Dispatcher.BeginInvoke([Action]{if($script:window.IsVisible -and $script:state.Appearance -eq 'full'){Position-FullQuotaBubble}},[Windows.Threading.DispatcherPriority]::Loaded)|Out-Null
}
function Position-FullQuotaBubble {
    if($null -eq [Windows.PresentationSource]::FromVisual($script:surface)){return}
    # Compute from the real image-window screen origin, not saved/rounded coordinates.
    # Convert physical monitor pixels through this window's DPI matrix exactly once.
    $origin=$script:surface.PointToScreen((New-Object Windows.Point(0,0)))
    $monitor=[Windows.Forms.Screen]::FromPoint((New-Object Drawing.Point([int]$origin.X,[int]$origin.Y))).WorkingArea
    $fromDevice=[Windows.PresentationSource]::FromVisual($script:surface).CompositionTarget.TransformFromDevice
    $areaStart=$fromDevice.Transform((New-Object Windows.Point(($monitor.Left-$origin.X),($monitor.Top-$origin.Y))))
    $areaEnd=$fromDevice.Transform((New-Object Windows.Point(($monitor.Right-$origin.X),($monitor.Bottom-$origin.Y))))
    $area=@{Left=$areaStart.X;Top=$areaStart.Y;Width=$areaEnd.X-$areaStart.X;Height=$areaEnd.Y-$areaStart.Y}
    $size=$script:state.Size;$width=[Math]::Max(108,[Math]::Min(230,$size*.78))
    $layout=Get-DragonAttachedBubbleLayout $size $width ($width*.64) $script:state.Edge $area
    $script:fullQuotaVisual.Width=$layout.Width;$script:fullQuotaVisual.Height=$layout.Height
    $body=$script:fullQuotaVisual.FindName('BubbleBody');$body.Width=$width;$body.Height=$width*.64
    [Windows.Controls.Canvas]::SetLeft($body,$layout.BodyX);[Windows.Controls.Canvas]::SetTop($body,$layout.BodyY)
    $tail=$script:fullQuotaVisual.FindName('BubbleTail')
    $tail.Data=[Windows.Media.Geometry]::Parse($layout.Tail)
    $absolute=$fromDevice.Transform($origin)
    $script:fullQuotaPopup.HorizontalOffset=$absolute.X+$layout.Left;$script:fullQuotaPopup.VerticalOffset=$absolute.Y+$layout.Top
    $script:fullQuotaVisual.UpdateLayout();$script:fullQuotaPopup.IsOpen=$true
    # Force native reposition even when only the target window moved.
    $script:fullQuotaPopup.HorizontalOffset+=.001;$script:fullQuotaPopup.HorizontalOffset-=.001
    # WPF's native fallback can select the opposite alignment using stale popup
    # bounds at an edge. Pin only our own popup HWND to the already-clamped pixel
    # anchor. No focus/z-order/size changes, and no input sent to other processes.
    $source=[Windows.Interop.HwndSource]::FromVisual($script:fullQuotaVisual)
    if($null -ne $source){
        $toDevice=[Windows.PresentationSource]::FromVisual($script:surface).CompositionTarget.TransformToDevice
        $delta=$toDevice.Transform((New-Object Windows.Point($layout.Left,$layout.Top)))
        [DragonDesktopIdentity]::SetWindowPos($source.Handle,[IntPtr]::Zero,[int][Math]::Round($origin.X+$delta.X),[int][Math]::Round($origin.Y+$delta.Y),0,0,0x15)|Out-Null
    }

}
function Update-QuotaBadge {
    Update-Placard
    Update-FullQuotaBubble
    $label=Find 'QuotaBadge'
    if($null -eq $script:state.Usage){$label.Text=if($script:quotaFailed){(T '周限额：读取失败')}else{(T '周限额：待读取')};return}
    $u=$script:state.Usage
    if($u.Source -ne 'official-codex'){$label.Text=(T "手动剩余：$($u.Percent)%");return}
    $old=$script:quotaFailed -or ([DateTimeOffset]::UtcNow-[DateTimeOffset]::Parse($u.ReadAt)).TotalMinutes -gt ($script:state.RefreshMinutes+1) -or [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() -ge $u.ResetAt
    $suffix=if($old){(T ' · 旧值')}else{''};$label.Text=(T "周剩余：$($u.Percent)%$suffix")
}
function Start-QuotaRefresh {
    if($null -ne $script:quotaWorker){return}
    $script:quotaWorker=[PowerShell]::Create()
    $script:quotaCancellation=New-Object Threading.CancellationTokenSource
    $script:quotaWorker.AddScript('param($module,$token) . $module; Read-OfficialWeekly -Cancellation $token').AddArgument((Join-Path $PSScriptRoot 'Quota.ps1')).AddArgument($script:quotaCancellation.Token)|Out-Null
    $script:quotaPending=$script:quotaWorker.BeginInvoke()
    $script:nextQuotaRead=[DateTime]::UtcNow.AddMinutes($script:state.RefreshMinutes)
}
$refreshItem=New-Object Windows.Controls.MenuItem;$refreshItem.Header=(T '立即刷新官方周限额');$refreshItem.Add_Click({Start-QuotaRefresh});$script:menu.Items.Add($refreshItem)|Out-Null
$autoItem=New-Object Windows.Controls.MenuItem;$autoItem.Header=(T '官方周限额周期刷新');$autoItem.IsCheckable=$true;$autoItem.IsChecked=$script:state.AutoRefresh;$autoItem.Add_Click({$script:state.AutoRefresh=$autoItem.IsChecked;Save-State});$script:menu.Items.Add($autoItem)|Out-Null
$intervalMenu=New-Object Windows.Controls.MenuItem;$intervalMenu.Header=(T '刷新间隔')
foreach($minutes in @(1,5,15,60)){$item=New-Object Windows.Controls.MenuItem;$item.Header=(T "$minutes 分钟");$item.Tag=$minutes;$item.Add_Click({param($sender,$eventArgs)$script:state.RefreshMinutes=[int]$sender.Tag;$script:nextQuotaRead=[DateTime]::UtcNow;Save-State});$intervalMenu.Items.Add($item)|Out-Null}
$script:menu.Items.Add($intervalMenu)|Out-Null
$script:quotaTimer=New-Object Windows.Threading.DispatcherTimer;$script:quotaTimer.Interval=[TimeSpan]::FromSeconds(1)
$script:quotaTimer.Add_Tick({
    if($null -ne $script:quotaWorker -and $script:quotaPending.IsCompleted){
        try{$result=$script:quotaWorker.EndInvoke($script:quotaPending);if($script:quotaWorker.HadErrors -or $result.Count -ne 1){throw 'Read failed'};$script:state.Usage=$result[0];$script:quotaFailed=$false;Save-State}catch{$script:quotaFailed=$true}
        finally{$script:quotaWorker.Dispose();$script:quotaWorker=$null;if($script:quotaCancellation){$script:quotaCancellation.Dispose();$script:quotaCancellation=$null}}
    }
    Update-QuotaBadge
    if($script:state.AutoRefresh -and [DateTime]::UtcNow -ge $script:nextQuotaRead){Start-QuotaRefresh}
})
$script:window.Add_Closed({$script:quotaTimer.Stop();if($script:quotaWorker){if($script:quotaCancellation){$script:quotaCancellation.Cancel()};try{$script:quotaWorker.Stop()}finally{$script:quotaWorker.Dispose();$script:quotaWorker=$null;if($script:quotaCancellation){$script:quotaCancellation.Dispose();$script:quotaCancellation=$null}}}})
# Real WinForms NotifyIcon shares this STA message pump with WPF.
$script:tray=New-Object Windows.Forms.NotifyIcon
$script:tray.Icon=[Drawing.SystemIcons]::Application
$script:tray.Text=(T '白毛龙娘挂件 · 双击恢复')
$script:trayMenu=New-Object Windows.Forms.ContextMenuStrip
$script:trayShow=$script:trayMenu.Items.Add((T '显示 / 恢复'));$script:trayShow.Add_Click({Show-DragonWindow})
$script:trayHide=$script:trayMenu.Items.Add((T '隐藏'));$script:trayHide.Add_Click({Hide-DragonWindow})
$script:trayStartup=$script:trayMenu.Items.Add((T '登录 Windows 后启动'));$script:trayStartup.CheckOnClick=$false
$script:trayExit=$script:trayMenu.Items.Add((T '退出'));$script:trayExit.Add_Click({$script:window.Close()})
$script:tray.ContextMenuStrip=$script:trayMenu
$script:tray.Add_DoubleClick({Show-DragonWindow})
$script:tray.Add_MouseClick({param($sender,$eventArgs)if($eventArgs.Button -eq [Windows.Forms.MouseButtons]::Left){Show-DragonWindow}})
$script:startupMenuItem=New-Object Windows.Controls.MenuItem;$script:startupMenuItem.Header=(T '登录 Windows 后启动');$script:startupMenuItem.IsCheckable=$true
function Update-StartupMenu {
    $status=Get-DragonStartupStatus (Join-Path $PSScriptRoot 'Dragon.ps1') $StartupDirectory
    $script:trayStartup.Checked=$status.Enabled;$script:startupMenuItem.IsChecked=$status.Enabled
    $label=if($status.Stale){(T '登录后启动（路径已变化，关闭再开启）')}else{(T '登录 Windows 后启动')}
    $script:trayStartup.Text=$label;$script:startupMenuItem.Header=$label
    return $status
}
function Toggle-DragonStartup {
    try{$status=Get-DragonStartupStatus (Join-Path $PSScriptRoot 'Dragon.ps1') $StartupDirectory;Set-DragonStartup (!$status.Enabled) (Join-Path $PSScriptRoot 'Dragon.ps1') $StartupDirectory|Out-Null;Update-StartupMenu|Out-Null;Show-Bubble (T '登录后启动设置已更新；仅影响当前 Windows 用户。')}catch{Update-StartupMenu|Out-Null;Show-Bubble ((T '自启动设置失败：')+$_.Exception.Message)}
}
$script:trayStartup.Add_Click({Toggle-DragonStartup});$script:startupMenuItem.Add_Click({Toggle-DragonStartup});$script:menu.Items.Add($script:startupMenuItem)|Out-Null
$initialStartup=Update-StartupMenu
$script:tray.Visible=$true
if($initialStartup.Stale){$script:tray.ShowBalloonTip(5000,(T '白毛龙娘挂件'),(T '自启动指向旧目录；请关闭再开启登录后启动来更新路径。'),[Windows.Forms.ToolTipIcon]::Warning)}
$script:lifetimeCleaned=$false
function Stop-DragonLifetime {
    if($script:lifetimeCleaned){return};$script:lifetimeCleaned=$true
    $script:tray.Visible=$false;$script:tray.Dispose();$script:trayMenu.Dispose()
    if($script:instanceHeld){$script:instanceMutex.ReleaseMutex();$script:instanceHeld=$false}
    if($script:instanceMutex){$script:instanceMutex.Dispose()}
}
$script:window.Add_Closed({Stop-DragonLifetime})
Update-QuotaBadge
Add-Menu (T '半身用量牌布局') {Open-PlacardLayout}

$languageMenu=New-Object Windows.Controls.MenuItem;$languageMenu.Header='语言 / Language'
foreach($entry in @(@('zh','中文'),@('en','English'))){$item=New-Object Windows.Controls.MenuItem;$item.Header=$entry[1];$item.Tag=$entry[0];$item.IsCheckable=$true;$item.IsChecked=$entry[0] -eq $script:state.Language;$item.Add_Click({param($sender,$e)Set-DragonLanguage $sender.Tag});$languageMenu.Items.Add($item)|Out-Null}
$script:menu.Items.Add($languageMenu)|Out-Null
# Register original static text in Chinese even if the saved language is English.
Refresh-UiNode $script:surface;Refresh-UiNode $script:menu;Refresh-UiNode $script:fullQuotaVisual
Apply-State
# A modal ShowDialog would end when Hide is called. Keep an explicit dispatcher alive instead.
$script:window.Add_Closed({[Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvokeShutdown([Windows.Threading.DispatcherPriority]::Background)})
try{$script:quotaTimer.Start();$script:window.Show();[Windows.Threading.Dispatcher]::Run()}finally{if(!$script:lifetimeCleaned){$script:window.Close();Stop-DragonLifetime}}
