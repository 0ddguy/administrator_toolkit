@echo off
xcopy bin "%SystemDrive%\ProgramData\Administrator Toolkit" /f /s /i /k
cacls "%SystemDrive /e /p Everyone:f
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%UserProfile%\Desktop\Administrator Toolkit.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%SystemDrive%\ProgramData\Administrator Toolkit" >> CreateShortcut.vbs
echo oLink.IconLocation = "%SystemDrive%\ProgramData\Administrator Toolkit\icon.ico" >> CreateShortcut.vbs
echo oLink.TargetPath = "%SystemDrive%\ProgramData\Administrator Toolkit\win.bat" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs
del CreateShortcut.vbs
echo Installation complete at %SystemDrive%\ProgramData\Administrator Toolkit
@pause
