@echo off

title VCcURL Batch

set "tmpvar=%1"

if defined tmpvar (
       set has_args=true
       set "tmpvar=%tmpvar:"=%"
)

for /f "TOKENS=1,2,*" %%a in ('tasklist /fi "WindowTitle eq %tmpvar%*"') do set "vc_pid=%%b"

if not defined has_args (
       set vc_pid=
       echo 
) else echo Voxel Core PID received

set "tmpvar=%2"

if defined tmpvar (
        set "ipc_dir=%2"
)

set "tmpvar="

if not defined ipc_dir (
       set "ipc_dir=%~dp0export\curl\internal\ipc"    
)

set "ipc_dir=%ipc_dir:"=%"

set "req_dir=%ipc_dir%\requests"
set "resp_dir=%ipc_dir%\responses"
set "raw_resp_dir=%ipc_dir%\raw_responses"
set "del_dir=%ipc_dir%\delete"

set "delete_list=%ipc_dir%\delete_list.txt"
set "requests_list=%ipc_dir%\requests_list.txt"
set "curl_output=%ipc_dir%\curl_output.txt"

(call del /s /q "%ipc_dir%") > nul 2>&1

(call mkdir "%ipc_dir%") > nul 2>&1

(call mkdir "%req_dir%") > nul 2>&1
(call mkdir "%resp_dir%") > nul 2>&1
(call mkdir "%raw_resp_dir%") > nul 2>&1
(call mkdir "%del_dir%") > nul 2>&1

:loop

call :vc_life_check

dir "%del_dir%" /b /a-d 1> "%delete_list%" 2>nul

for /f "usebackq tokens=*" %%i in ("%delete_list%") do (
       call :process_del "%del_dir%\%%i" %%i
)

dir "%req_dir%" /b /a-d 1> "%requests_list%" 2>nul

for /f "usebackq tokens=*" %%i in ("%requests_list%") do (
       call :process_req "%req_dir%\%%i" %%i
)

ping 127.0.0.1 -n 1 -w 500 > nul
goto loop

:process_del

echo Processing file delete request with ID %2

set /p file_to_delete=<%1

call del "%ipc_dir%\%file_to_delete:/=\%"

call del %1

exit /b 0

:process_req
echo Processing cURL request with ID %2

set "raw_resp_path=%raw_resp_dir%\%2"
set "resp_path=%resp_dir%\%2"

set /p cURL_cmd=<%1

set "old_dir=%cd%""

cd "%ipc_dir%"

call curl %cURL_cmd% >"%curl_output%"

cd "%old_dir%"

if not exist "%raw_resp_path%" (
       call copy "%curl_output%" "%resp_path%" > nul 2>&1
) else (
       call copy "%raw_resp_path%" "%resp_path%" > nul 2>&1
       call del "%raw_resp_path%"
)

call del "%curl_output%"

call del %1

exit /b 0

:vc_life_check

if defined vc_pid (
       call :is_proc_alive %vc_pid%

       if errorlevel 1 exit
)

exit /b 0

:is_proc_alive

tasklist /fi "pid eq %1" /fo csv 2>nul | find /I ":">nul

if errorlevel 1 (
       exit /b 0
) else (
       exit /b 1 
)