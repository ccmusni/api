@echo off

cd ..\..
rd JeonSoftAPI /s /Q
xcopy rmi_api JeonSoftAPI /s /i /Exclude:rmi_api\exclude.txt

cd rmi_api\setup
echo *****Start compiling executable installer
call iscc "Install API.iss"

cd ..\..
rd JeonSoftAPI /s /Q

pause