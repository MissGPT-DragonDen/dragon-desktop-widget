Option Explicit
Dim shell, fs, folder, command
Set shell = CreateObject("WScript.Shell")
Set fs = CreateObject("Scripting.FileSystemObject")
folder = fs.GetParentFolderName(WScript.ScriptFullName)
command = "powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File " & Chr(34) & folder & "\Dragon.ps1" & Chr(34)
shell.Run command, 0, False
