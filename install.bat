@echo off
 
if [%1]==[] goto ERR

if ["%1"]==["/all"] goto ALLUSERS

if ["%1"]==["/local"] goto LOCAL


:LOCAL
echo [Info] Copying files to %LOCALAPPDATA%
xcopy bin "%LOCALAPPDATA%\Administrator Toolkit" /f /e /i /k /q
echo [Info] Creating shortcut...
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%USERPROFILE%\Desktop\Administrator Toolkit.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%LOCALAPPDATA%\Administrator Toolkit" >> CreateShortcut.vbs
echo oLink.IconLocation = "%LOCALAPPDATA%\Administrator Toolkit\icon.ico" >> CreateShortcut.vbs
echo oLink.TargetPath = "%LOCALAPPDATA%\Administrator Toolkit\win.bat" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs > NUL
echo [Info] Cleaning up...
del CreateShortcut.vbs
echo [Done] Installation complete at %LOCALAPPDATA%\Administrator Toolkit
EXIT 0

:ALLUSERS
echo [Info] Copying files to %SYSTEMDRIVE%\ProgramData
xcopy bin "%SYSTEMDRIVE%\ProgramData\Administrator Toolkit" /f /e /i /k /q
echo [Info] Applying permissions...
icacls "%SYSTEMDRIVE%\ProgramData\Administrator Toolkit" /e /p Everyone:f
echo [Info] Creating shortcut...
echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%PUBLIC%\Desktop\Administrator Toolkit.lnk" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%SYSTEMDRIVE%\ProgramData\Administrator Toolkit" >> CreateShortcut.vbs
echo oLink.IconLocation = "%SYSTEMDRIVE%\ProgramData\Administrator Toolkit\icon.ico" >> CreateShortcut.vbs
echo oLink.TargetPath = "%SYSTEMDRIVE%\ProgramData\Administrator Toolkit\win.bat" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs
cscript CreateShortcut.vbs > NUL
echo [Info] Cleaning up...
del CreateShortcut.vbs
echo [Done] Installation complete at %SYSTEMDRIVE%\ProgramData\Administrator Toolkit
EXIT 0

:ERR
echo [Err] Invalid option supply /local or /all
EXIT 1

