@echo off

title VCcURL Master

call :parse_vc_argument %1 %2

call :parse_vc_argument %3 %4

if not "%res_dir%"=="" (
	set "vc_cmd=--res "%res_dir%" "
)

if not "%usr_dir%"=="" (
	set "vc_cmd=%vc_cmd%--dir "%usr_dir%""
	set "ipc_dir=%usr_dir%\export\curl\internal\ipc"
) else (
	set "ipc_dir=%~dp0export\curl\internal\ipc"
)
set "vc_title=Voxel Core + cURL: %random%%random%%random%"

title %vc_title%

start /min cmd /c ""%~dp0vccurl_replier.bat" "%vc_title%" "%ipc_dir%""

call "%~dp0voxelcore.exe" %vc_cmd%"

:parse_vc_argument

if not "%1"=="" (
	if "%1"=="--dir" (
		set "usr_dir=%2"
	) else (
		if "%1"=="--res" (
			set "res_dir=%2"
		)
	)
)

exit /b 0