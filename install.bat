@echo off
xcopy bin %SystemDrive%\"Administrator Toolkit" /f /s /i /k
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%UserProfile%\Desktop\Administrator Toolkit.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%SystemDrive%\Administrator Toolkit" >> CreateShortcut.vbs
echo oLink.IconLocation = "%SystemDrive%\Administrator Toolkit\icon.ico" >> CreateShortcut.vbs
echo oLink.TargetPath = "%SystemDrive%\Administrator Toolkit\win.bat" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs
del CreateShortcut.vbs
@pause
