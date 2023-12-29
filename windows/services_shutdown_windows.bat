@echo off
setlocal EnableDelayedExpansion
rem ### Script version ###
set scriptVersion=1.0.3
rem ######################

set currentFolder=%cd%

set /a "isLicenseServerStarted=1"
set /a "isControllerStarted=1"
set /a "isResourceOnDemandStarted=1"
set /a "isCacheServiceStarted=1"
set /a "isDgeStarted=1"
set /a "isActiveSpoolerStarted=1"
set /a "isXFStarted=1"
set /a "isSinclairStarted=1"
set /a "isSinclairIndexStarted=1"
set /a "isAimStarted=1"
set /a "isInputAgentStarted=1"
set /a "isJobProcessorStarted=1"

set sinclairPath=C:\DocPath\Sinclair Pack 6\Sinclair
set sinclairIndexPath=C:\DocPath\Sinclair Pack 6\SinclairIndex
set licenseServerPath=C:\DocPath\DocPath License\DocPath License Server\Bin

set licenseServerJREPath=
set sinclairJREPath=
set sinclairIndexJREPath=


echo [Services Startup Script - v"%scriptVersion%"]

echo Stopping services...

	if !isAimStarted! EQU 1 (
		call :stopAIM
	)
	if !isControllerStarted! EQU 1 (
		call :stopController
	)
	if !isActiveSpoolerStarted! EQU 1 (
		call :stopActiveSpooler
	)
    if !isResourceOnDemandStarted! EQU 1 (
		call :stopResourceOnDemand
	)
	if !isCacheServiceStarted! EQU 1 (
		call :stopCacheService
	)
	if !isDgeStarted! EQU 1 (
		call :stopDge
	)
	if !isXFStarted! EQU 1 (
		call :stopXF
	)
	if !isSinclairStarted! EQU 1 (
		call :stopSinclair
	)	
	if !isSinclairIndexStarted! EQU 1 (
		call :stopSinclairIndex
	)
	if !isInputAgentStarted! EQU 1 (
		call :stopInputAgent
	)
	if !isLicenseServerStarted! EQU 1 (
		call :stopLicenseServer
	)
	if !isJobProcessorStarted! EQU 1 (
		call :stopJobProcessor
	)

cd %currentFolder%
exit /B 0



:stopResourceOnDemand

	echo Stopping Resources on Demand...
	for /f %%c in ('curl localhost:1782/DpRoD/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:1782/DpRoD/Shutdown -s -o nul
	)
    
	echo Resources on Demand is stopped.
	set /a "isResourceOnDemandStarted=0"
goto :eof


:stopCacheService

	echo Stopping Cache Service...
	for /f %%c in ('curl localhost:1781/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:1781/Shutdown -s -o nul
	)
   
	echo Cache Service is stopped.
	set /a "isCacheServiceStarted=0"
	
goto :eof


:stopDge

	echo Stopping DGE...
	for /f %%c in ('curl localhost:8084/dge/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:8084/dge/Shutdown -s -o nul
	)

	echo DGE is stopped.
	set /a "isDgeStarted=0"
	
goto :eof


:stopActiveSpooler

	echo Stopping ActiveSpooler..
	for /f %%c in ('curl localhost:8085/dpactivespooler/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:8085/dpactivespooler/Shutdown -s -o nul
		
	)
	set /a "isActiveSpoolerStarted=0"
	echo ActiveSpooler is stopped.
	
goto :eof


:stopXF
    echo Stopping XFService..
	call :checkXFIsRunning
	if %errorlevel% EQU 1 (
	    sc stop XFService > NUL 2>&1
	    for /l %%x in (1, 1, 10) do (
		    call :checkXFIsRunning
		    if !errorlevel! EQU 1 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    )
	    )	    
	)
	echo XFService is stopped.
	set /a "isXFStarted=0"
goto :eof

:checkXFIsRunning
for /F "tokens=3 delims=: " %%H in ('sc query "XFService" ^| findstr "        STATE"') do (
  if /I "%%H" NEQ "RUNNING" (
	exit /B 0
  ) else (
	exit /B 1
  )
)
goto :eof


:stopLicenseServer

    echo Stopping License Server..
    cd %licenseServerPath% > NUL 2>&1
    "%licenseServerJREPath%java" -jar dplicenseserver.jar -query > NUL 2>&1

    if !errorlevel! NEQ 0 (
	    "%licenseServerJREPath%java" -jar dplicenseserver.jar -stop > NUL 2>&1
	    for /l %%x in (1, 1, 10) do (
		    "%licenseServerJREPath%java" -jar dplicenseserver.jar -query > NUL 2>&1
		    if !errorlevel! NEQ 0 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) 
	    )
    )
	echo License Server is stopped.
	set /a "isLicenseServerStarted=0"
goto :eof


:stopController
    echo Stopping Controller..
	call :checkControllerIsRunning
	if %errorlevel% EQU 1 (
	    sc stop dpctrlsrv6 > NUL 2>&1
	    for /l %%x in (1, 1, 10) do (
		    call :checkControllerIsRunning
		    if !errorlevel! EQU 1 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    set /a "isControllerStarted=0"
		    )
	    )
	)
	echo Controller is stopped.
goto :eof



:stopSinclair

	echo Stopping Sinclair..
	for /f %%c in ('curl localhost:1806/dpsinclair/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl -X POST localhost:1806/dpsinclair/actuator/shutdown -s -o nul
	)
	
	echo Sinclair is stopped.
	set /a "isSinclairStarted=0"
goto :eof


:stopSinclairIndex

    echo Stopping Sinclair Index..
	for /f %%c in ('curl localhost:1807/dpsinclairindex/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl -X POST localhost:1807/dpsinclairindex/actuator/shutdown -s -o nul	
	)
    
	echo Sinclair Index is stopped.
	set /a "isSinclairIndexStarted=0"
goto :eof


:stopAIM
    echo Stopping AIM..
	for /f %%c in ('curl localhost:8080/aim/ping -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:8080/aim/shutdown -s -o nul
		
	)
	set /a "isAimStarted=0"
	echo AIM is stopped.
	
goto :eof


:stopInputAgent

	echo Stopping InputAgent..
	for /f %%c in ('curl localhost:1803/dpinputagent/status/isAlive -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:1803/dpinputagent/shutdown -s -o nul
	)
    
	echo InputAgent is stopped.
	set /a "isInputAgentStarted=0"
goto :eof



:checkControllerIsRunning
for /F "tokens=3 delims=: " %%H in ('sc query "dpctrlsrv6" ^| findstr "        STATE"') do (
  if /I "%%H" NEQ "RUNNING" (
	exit /B 0
  ) else (
	exit /B 1
  )
)
goto :eof

:stopJobProcessor

	echo Stopping JobProcessor..
	for /f %%c in ('curl localhost:1812/jobprocessor/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! EQU 200 (
		curl localhost:1812/jobprocessor/Shutdown -s -o nul
	)
	
	echo JobProcessor is stopped.
	set /a "isJobProcessorStarted=0"
goto :eof

