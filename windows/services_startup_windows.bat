@echo off
setlocal EnableDelayedExpansion
rem ### Script version ###
set scriptVersion=1.0.2
rem ######################

set currentFolder=%cd%

set /a "isLicenseServerStarted=0"
set /a "isControllerStarted=0"
set /a "isResourceOnDemandStarted=0"
set /a "isCacheServiceStarted=0"
set /a "isDgeStarted=0"
set /a "isActiveSpoolerStarted=0"
set /a "isXFStarted=0"
set /a "isSinclairStarted=0"
set /a "isSinclairIndexStarted=0"
set /a "isAimStarted=0"
set /a "isInputAgentStarted=0"

set licenseServerPath=C:\DocPath\DocPath License\DocPath License Server\Bin
set controllerPath=C:\DocPath\Controller Core Pack 6
set resourceOnDemandPath=C:\DocPath\DocGeneration Expansion 6\ResourcesOnDemand\Bin
set cacheServicePath=C:\DocPath\DocGeneration Expansion 6\CacheService\Bin
set dgePath=C:\DocPath\DocGeneration Pack 6
set activeSpoolerPath=C:\DocPath\ActiveSpooler Pack 2\ActiveSpooler\Bin
set sinclairPath=C:\DocPath\Sinclair Pack 6\Sinclair
set sinclairIndexPath=C:\DocPath\Sinclair Pack 6\SinclairIndex
set aimPath=C:\DocPath\Access Identity Management\AccessIdentityManagement\Bin
set inputAgentPath=C:\DocPath\InputAgent Pack 2\InputAgent\bin

set licenseServerJREPath=
set resourceOnDemandJREPath=
set cacheServiceJREPath=
set dgeJREPath=
set activeSpoolerJREPath=
set sinclairJREPath=
set sinclairIndexJREPath=
set aimJREPath=
set inputAgentJREPath=

echo [Services Startup Script - v"%scriptVersion%"]

echo Starting services...
call :startLicenseServer
if %errorlevel% NEQ 0 (
	echo License Server cannot be started properly and will be stopped. 
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 1
)	
call :startAIM
if %errorlevel% NEQ 0 (
	echo AIM cannot be started properly and will be stopped.
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 10
)
call :startSinclair
if %errorlevel% NEQ 0 (
	echo Sinclair cannot be started properly and will be stopped. 
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 8
)
call :startSinclairIndex
if %errorlevel% NEQ 0 (
	echo Sinclair Index cannot be started properly and will be stopped. 
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 9
)
call :startActiveSpooler
if %errorlevel% NEQ 0 (
	echo ActiveSpooler cannot be started properly and will be stopped.
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 6
)
call :startXF
if %errorlevel% NEQ 0 (
	echo XFService cannot be started properly and will be stopped.
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 7
)
call :startResourceOnDemand
if %errorlevel% NEQ 0 (
	echo Resources on Demand cannot be started properly and will be stopped. 
 	call :stopServices
 	cd %currentFolder% > NUL 2>&1
 	exit /B 2
)
call :startCacheService
if %errorlevel% NEQ 0 (
	echo Cache Service cannot be started properly and will be stopped. 
 	call :stopServices
 	cd %currentFolder% > NUL 2>&1
 	exit /B 3
 )
call :startDge
if %errorlevel% NEQ 0 (
	echo DGE cannot be started properly and will be stopped. 
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 4
)
call :startController
if %errorlevel% NEQ 0 (
	echo Controller cannot be started properly and will be stopped.
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 5
)
call :startInputAgent
if %errorlevel% NEQ 0 (
	echo InputAgent cannot be started properly and will be stopped.
	call :stopServices
	cd %currentFolder% > NUL 2>&1
	exit /B 11
)

cd %currentFolder%
exit /B 0

:startResourceOnDemand
	
	echo Starting Resources on Demand...
	if not defined resourceOnDemandPath (
		echo Resources on Demand is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %resourceOnDemandPath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo Resources on Demand is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:1782/DpRoD/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		start "" "%resourceOnDemandJREPath%javaw" -jar dprodservice.war > NUL 2>&1
		echo Resources on Demand is starting...
	)
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:1782/DpRoD/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			    echo Resources on Demand is started.
			    set /a "isResourceOnDemandStarted=1"
				for /f "delims=" %%i in ('curl localhost:1782/DpRoD/rest/check/rodstatus/ -s') do set healthcheck_status=%%i
				Set healthcheck_status=!healthcheck_status:}=!
				Set healthcheck_status=!healthcheck_status:]=!
				Set healthcheck_status=!healthcheck_status:,=!
				Set healthcheck_status=!healthcheck_status:"=!
				Set healthcheck_status=!healthcheck_status::=!
				echo !healthcheck_status! | (findstr "isValidtruenameGeneral")  >nul 2>&1
				if not errorlevel 1 (
					echo Resources on Demand is correctly configured and ready.					
					exit /B 0
				) else (
					echo Resources on Demand is not correctly configured or ready.
					exit /B 1
				)
		)
	)
	
	echo Resources on Demand is not started.
	exit /B 1
	
goto :eof

:stopResourceOnDemand

    curl localhost:1782/DpRoD/Shutdown -s -o nul
	echo Resources on Demand is stopped.
	set /a "isResourceOnDemandStarted=0"
goto :eof

:startCacheService
	
	echo Starting Cache Service...
	if not defined cacheServicePath (
		echo Cache Service is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %cacheServicePath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo Cache Service is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:1781/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		start "" "%cacheServiceJREPath%javaw" -jar dpcacheservice.war > NUL 2>&1
		echo Cache Service is starting...
	)
	
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:1781 -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			    echo Cache Service is started.
			    set /a "isCacheServiceStarted=1"
				for /f "delims=" %%i in ('curl localhost:1781/rest/check/cachestatus/ -s') do set healthcheck_status=%%i
				Set healthcheck_status=!healthcheck_status:}=!
				Set healthcheck_status=!healthcheck_status:]=!
				Set healthcheck_status=!healthcheck_status:,=!
				Set healthcheck_status=!healthcheck_status:"=!
				Set healthcheck_status=!healthcheck_status::=!
				echo !healthcheck_status! | (findstr "isValidtruenameGeneral")  >nul 2>&1
				if not errorlevel 1 (
					echo Cache Service is correctly configured and ready.					
					exit /B 0
				) else (
					echo Cache Service is not correctly configured or ready.
					exit /B 1
				)
		)
	)
	
	echo Cache Service is not started.
	exit /B 1
	
goto :eof

:stopCacheService

    curl localhost:1781/Shutdown -s -o nul
	echo Cache Service is stopped.
	set /a "isCacheServiceStarted=0"
goto :eof

:startDge
	
	echo Starting DGE...
	if not defined dgePath (
		echo DGE is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %dgePath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo DGE is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:8084/dge/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		start "" "%dgeJREPath%javaw" -jar dge.war > NUL 2>&1
		echo DGE is starting...
	)
	
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:8084/dge/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			    echo DGE is started.
			    set /a "isDgeStarted=1"
				for /f "delims=" %%i in ('curl localhost:8084/dge/rest/check/dgestatus/ -s') do set healthcheck_status=%%i
				Set healthcheck_status=!healthcheck_status:}=!
				Set healthcheck_status=!healthcheck_status:]=!
				Set healthcheck_status=!healthcheck_status:,=!
				Set healthcheck_status=!healthcheck_status:"=!
				Set healthcheck_status=!healthcheck_status::=!
				echo !healthcheck_status! | (findstr "isValidtruenameGeneral")  >nul 2>&1
				if not errorlevel 1 (
					echo DGE is correctly configured and ready.					
					exit /B 0
				) else (
					echo DGE is not correctly configured or ready.
					exit /B 1
				)
		)
	)
	
	echo DGE is not started.
	exit /B 1
	
goto :eof

:stopDge

    curl localhost:8084/dge/Shutdown -s -o nul
	echo DGE is stopped.
	set /a "isDgeStarted=0"
goto :eof

:startActiveSpooler
	
	echo Starting ActiveSpooler...
	if not defined activeSpoolerPath (
		echo ActiveSpooler is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %activeSpoolerPath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo ActiveSpooler is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:8085/dpactivespooler/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		start "" "%activeSpoolerJREPath%javaw" -jar dpactivespooler.war > NUL 2>&1
		echo ActiveSpooler is starting...
	)
	
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:8085/dpactivespooler/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			    echo ActiveSpooler is started.
			    set /a "isActiveSpoolerStarted=1"
				for /f "delims=" %%i in ('curl localhost:8085/dpactivespooler/rest/check/server-status/ -s') do set healthcheck_status=%%i
				Set healthcheck_status=!healthcheck_status:}=!
				Set healthcheck_status=!healthcheck_status:]=!
				Set healthcheck_status=!healthcheck_status:,=!
				Set healthcheck_status=!healthcheck_status:"=!
				Set healthcheck_status=!healthcheck_status::=!
				echo !healthcheck_status! | (findstr "statusrunning")  >nul 2>&1
				if not errorlevel 1 (
					echo ActiveSpooler is correctly configured and ready.					
					exit /B 0
				) else (
					echo ActiveSpooler is not correctly configured or ready.
					exit /B 1
				)
		)
	)
	
	echo ActiveSpooler is not started.
	exit /B 1
	
goto :eof

:stopActiveSpooler

    curl localhost:8085/dpactivespooler/Shutdown -s -o nul
	echo ActiveSpooler is stopped.
	set /a "isActiveSpoolerStarted=0"
goto :eof

:startXF

	echo Starting XFService...
	
	sc query XFService > nul 2>&1
	if %errorlevel% NEQ 0 (
		echo XFService is not installed or the path indicated is wrong.
		exit /B 1
	)
	call :checkXFIsRunning
	if %errorlevel% EQU 1 (
		echo XFService is started.
        set /a "isXFStarted=1"
		exit /B 0
	)
	if !isXFStarted! NEQ 1 (
	    sc start XFService > NUL 2>&1
	    echo XFService is starting...
	    for /l %%x in (1, 1, 10) do (
		    call :checkXFIsRunning
		    if !errorlevel! EQU 0 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    echo XFService is started.
				set /a "isXFStarted=1"
			    exit /B 0
		    )
	    )
	    echo XFService is not started.
	    exit /B 1
	)
	
goto :eof

:stopXF
	call :checkXFIsRunning
	if %errorlevel% EQU 1 (
	    sc stop XFService > NUL 2>&1
	    for /l %%x in (1, 1, 10) do (
		    call :checkXFIsRunning
		    if !errorlevel! EQU 1 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    echo XFService is stopped.
			    set /a "isXFStarted=0"
			    exit /B 0
		    )
	    )
	    exit /B 1
	)
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

:startLicenseServer

    echo Starting License Server...
	if not defined licenseServerPath (
		echo License Server is not installed or the path indicated is wrong.
		exit /B 1
	)

    cd %licenseServerPath% > NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo License Server is not installed or the path indicated is wrong.
		exit /B 1
	)

    "%licenseServerJREPath%java" -jar dplicenseserver.jar -query > NUL 2>&1
	
	if %errorlevel% NEQ 0 (
		echo License Server is started.
        set /a "isLicenseServerStarted=1"
		exit /B 0
	)

	if !isLicenseServerStarted! NEQ 1 (
	    start "" "%licenseServerJREPath%javaw" -jar dplicenseserver.jar -start
	    echo License Server is starting... 
	    for /l %%x in (1, 1, 10) do (
		    "%licenseServerJREPath%java" -jar dplicenseserver.jar -query > NUL 2>&1
		    if !errorlevel! EQU 0 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    echo License Server is started.
				set /a "isLicenseServerStarted=1"
			    exit /B 0
		    )
	    )
	    echo License Server is not started.
	    exit /B 1
	)
goto :eof

:stopLicenseServer

    cd %licenseServerPath% > NUL 2>&1
    "%licenseServerJREPath%java" -jar dplicenseserver.jar -query > NUL 2>&1

    if !errorlevel! NEQ 0 (
	    "%licenseServerJREPath%java" -jar dplicenseserver.jar -stop > NUL 2>&1
	    for /l %%x in (1, 1, 10) do (
		    "%licenseServerJREPath%java" -jar dplicenseserver.jar -query > NUL 2>&1
		    if !errorlevel! NEQ 0 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    echo License Server is stopped.
			    set /a "isLicenseServerStarted=0"
			    exit /B 0
		    )
	    )
	    exit /B 1
    )
goto :eof

:startController

	echo Starting Controller...
	
	sc query dpctrlsrv6 > nul 2>&1
	if %errorlevel% NEQ 0 (
		echo Controller is not installed or the path indicated is wrong.
		exit /B 1
	)
	call :checkControllerIsRunning
	if %errorlevel% EQU 1 (
		echo Controller is started.
        set /a "isControllerStarted=1"
		exit /B 0
	)
	if !isControllerStarted! NEQ 1 (
	    sc start dpctrlsrv6 > NUL 2>&1
	    echo Controller is starting...
	    for /l %%x in (1, 1, 10) do (
		    call :checkControllerIsRunning
		    if !errorlevel! EQU 0 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    echo Controller is started.
				set /a "isControllerStarted=1"				
			    exit /B 0
		    )
	    )
	    echo Controller is not started.
	    exit /B 1
	)
	
goto :eof

:stopController
	call :checkControllerIsRunning
	if %errorlevel% EQU 1 (
	    sc stop dpctrlsrv6 > NUL 2>&1
	    for /l %%x in (1, 1, 10) do (
		    call :checkControllerIsRunning
		    if !errorlevel! EQU 1 (
			    timeout /t 1 /nobreak > NUL 2>&1
		    ) else (
			    echo Controller is stopped.
			    set /a "isControllerStarted=0"
			    exit /B 0
		    )
	    )
	    exit /B 1
	)
goto :eof

:startSinclair
	
	echo Starting Sinclair...
	if not defined sinclairPath (
		echo Sinclair is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %sinclairPath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo Sinclair is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:1806/dpsinclair/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		echo Sinclair is starting...
		start "" "%sinclairJREPath%javaw" -jar dpsinclair.war > NUL 2>&1
	)
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:1806/dpsinclair/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			echo Sinclair is started.
			set /a "isSinclairStarted=1"
			exit /B 0
				
		)
	)
	
	echo Sinclair is not started.
	exit /B 1
	
goto :eof

:stopSinclair

	cd %sinclairPath% >NUL 2>&1
    "%sinclairJREPath%javaw" -jar dpsinclair.war -shutdown
	echo Sinclair is stopped.
	set /a "isSinclairStarted=0"
goto :eof
	
:startSinclairIndex
	
	echo Starting Sinclair Index...
	if not defined sinclairIndexPath (
		echo Sinclair Index is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %sinclairIndexPath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo Sinclair Index is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:1807/dpsinclairindex/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		echo Sinclair Index is starting...		
		start "" "%sinclairIndexJREPath%javaw" -jar dpsinclairindex.war > NUL 2>&1
	)
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:1807/dpsinclairindex/ -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			echo Sinclair Index is started.
			set /a "isSinclairIndexStarted=1"
			exit /B 0
				
		)
	)
	
	echo Sinclair Index is not started.
	exit /B 1
	
goto :eof

:stopSinclairIndex

    cd %sinclairIndexPath% >NUL 2>&1
    "%sinclairIndexJREPath%javaw" -jar dpsinclairindex.war -shutdown	
	echo Sinclair Index is stopped.
	set /a "isSinclairIndexStarted=0"
goto :eof

:startAIM
	
	echo Starting AIM...
	if not defined aimPath (
		echo AIM is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %aimPath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo AIM is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:8080/aim/ping -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		start "" "%aimJREPath%javaw" -jar aim.war > NUL 2>&1
		echo AIM is starting...
	)
	
	for /l %%x in (1, 1, 45) do (
		for /f %%c in ('curl localhost:8080/aim/ping -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			    echo AIM is started.
			    set /a "isAimStarted=1"
				for /f "delims=" %%i in ('curl localhost:8080/aim/healthcheck/ -s') do set healthcheck_status=%%i
				Set healthcheck_status=!healthcheck_status:}=!
				Set healthcheck_status=!healthcheck_status:]=!
				Set healthcheck_status=!healthcheck_status:,=!
				Set healthcheck_status=!healthcheck_status:"=!
				Set healthcheck_status=!healthcheck_status::=!
				echo !healthcheck_status! | (findstr "statusrunning")  >nul 2>&1
				if not errorlevel 1 (
					echo AIM is correctly configured and ready.					
					exit /B 0
				) else (
					echo AIM is not correctly configured or ready.
					exit /B 1
				)
		)
	)
	
	echo AIM is not started.
	exit /B 1
	
goto :eof

:stopAIM
	curl localhost:8080/aim/shutdown -s -o nul
	echo AIM is stopped.
	set /a "isAimStarted=0"
goto :eof

:startInputAgent
	
	echo Starting InputAgent...
	if not defined inputAgentPath (
		echo InputAgent is not installed or the path indicated is wrong.
		exit /B 1
	)
	cd %inputAgentPath% >NUL 2>&1
	if %errorlevel% NEQ 0 (
		echo InputAgent is not installed or the path indicated is wrong.
		exit /B 1
	)
	
	for /f %%c in ('curl localhost:1803/dpinputagent/status/isAlive -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
	
	if !http_code! NEQ 200 (
		start "" "%inputAgentJREPath%javaw" -jar dpinputagent.war > NUL 2>&1
		echo InputAgent is starting...
	)
	
	for /l %%x in (1, 1, 20) do (
		for /f %%c in ('curl localhost:1803/dpinputagent/status/isAlive -s -w "%%{http_code}\r\n" -o nul') do set /a "http_code=%%c"
		if !http_code! NEQ 200 (
			timeout /t 1 /nobreak > NUL 2>&1
		) else (
			    echo InputAgent is started.
			    set /a "isInputAgentStarted=1"
				for /f "delims=" %%i in ('curl localhost:1803/dpinputagent/status/service-status -s') do set healthcheck_status=%%i
				Set healthcheck_status=!healthcheck_status:}=!
				Set healthcheck_status=!healthcheck_status:]=!
				Set healthcheck_status=!healthcheck_status:,=!
				Set healthcheck_status=!healthcheck_status:"=!
				Set healthcheck_status=!healthcheck_status::=!
				echo !healthcheck_status! | (findstr "statusrunning")  >nul 2>&1
				if not errorlevel 1 (
					echo InputAgent is correctly configured and ready.					
					exit /B 0
				) else (
					echo InputAgent is not correctly configured or ready.
					exit /B 1
				)
		)
	)
	
	echo InputAgent is not started.
	exit /B 1
	
goto :eof

:stopInputAgent

    curl localhost:1803/dpinputagent/shutdown -s -o nul
	echo InputAgent is stopped.
	set /a "isInputAgentStarted=0"
goto :eof

:stopServices

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



