@echo off
echo [Info] Copying files to %SystemDrive%
xcopy bin "%SystemDrive%\ProgramData\Administrator Toolkit" /f /e /i /k /q
echo [Info] Applying permissions...
cacls "%SystemDrive%\ProgramData\Administrator Toolkit" /e /p Everyone:f
echo [Info] Creating shortcut...
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%UserProfile%\Desktop\Administrator Toolkit.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%SystemDrive%\ProgramData\Administrator Toolkit" >> CreateShortcut.vbs
echo oLink.IconLocation = "%SystemDrive%\ProgramData\Administrator Toolkit\icon.ico" >> CreateShortcut.vbs
echo oLink.TargetPath = "%SystemDrive%\ProgramData\Administrator Toolkit\win.bat" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs > NUL
echo [Info] Cleaning up...
del CreateShortcut.vbs
echo [Done] Installation complete at %SystemDrive%\ProgramData\Administrator Toolkit
@pause
