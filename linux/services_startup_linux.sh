#!/bin/bash

### Script version ###
scriptVersion="1.0.8"
######################

echo "[Services Startup Script - v"$scriptVersion"]"

isLicenseServerStarted=0
isAimStarted=0
isControllerStarted=0
isResourceOnDemandStarted=0
isCacheServiceStarted=0
isDgeStarted=0
isActiveSpoolerStarted=0
isInputAgentStarted=0
isDocManagerServiceStarted=0
isDocManagerWebToolStarted=0
isDocManagerContentServerStarted=0
isJobProcessorStarted=0
isSinclairStarted=0
isSinclairIndexStarted=0

licenseServerPath=/usr/local/docpath/licenseserver/licenseserver/Bin
aimPath="/usr/local/docpath/Access Identity Management/AccessIdentityManagement/Bin"
controllerPath=/usr/local/docpath/controllercorepack
resourceOnDemandPath=/usr/local/docpath/docgenerationexpansion/resourcesondemand/Bin
cacheServicePath=/usr/local/docpath/docgenerationexpansion/cacheservice/Bin
dgePath=/usr/local/docpath/generation
activeSpoolerPath=/usr/local/docpath/activespoolerpack/activespooler/Bin
inputAgentPath=/usr/local/docpath/inputagentpack2/inputagent/bin
docManagerServicePath=/usr/local/docpath/docmanagerarpack6/service
docManagerWebToolPath=/usr/local/docpath/docmanagerarpack6/webtool
jobProcessorPath=/usr/local/docpath/jobprocessorpack6/JobProcessor/Bin/
sinclairPath=/usr/local/docpath/sinclairpack6/sinclair/
sinclairIndexPath=/usr/local/docpath/sinclairpack6/sinclairindex/

#The JRE paths must end with the character '/'
licenseServerJREPath=
resourceOnDemandJREPath=
cacheServiceJREPath=
dgeJREPath=
activeSpoolerJREPath=
sinclairJREPath=
sinclairIndexJREPath=
aimJREPath=
inputAgentJREPath=
JobProcessorJREPath=
docManagerServiceJREPath=
docManagerWebToolJREPath=

user=
expected_status='isValid":true}],"name":"General_Status"'
expected_status2='"status":"running"'

function checkUser {

  if [ -z "$user" ]; then
	return 0;
  else
    loggedInUser=$(whoami)
    if [ "$user" != "$loggedInUser" ]; then
	   echo "The logged in user ($loggedInUser) is different than the script user ($user)"
	   return 1;
	else
	   return 0;
	fi
  fi
}

function startResourceOnDemand {
        echo ""
        echo "Starting Resources on Demand..."
        cd $resourceOnDemandPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "Resources on Demand is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1782/DpRoD/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${resourceOnDemandJREPath}java -jar dprodservice.war >/dev/null 2>&1 &
        echo "Resources on Demand is starting..."
    fi

        for ((i=0; i<10; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1782/DpRoD/rest/check/rodstarted/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "Resources on Demand is started."
                        isResourceOnDemandStarted=1
                        healthcheck_status=$(curl --silent localhost:1782/DpRoD/rest/check/rodstatus/)
                        if grep -q "$expected_status" <<< "$healthcheck_status"; then
                                echo "Resources on Demand is correctly configured and ready."
                                return 0;
                        else
                                echo "Resources on Demand is not correctly configured or ready."
                                return 1;
                        fi
                fi
        done
        echo "Resources on Demand is not started."
        return 1;
}

function stopResourceOnDemand() {

    curl -o /dev/null --silent localhost:1782/DpRoD/Shutdown
        echo "Resources on Demand is stopped."
        isResourceOnDemandStarted=0
}

function startCacheService {
        echo ""
        echo "Starting Cache Service..."
        cd $cacheServicePath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "Cache Service is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1781/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${cacheServiceJREPath}java -jar dpcacheservice.war >/dev/null 2>&1 &
        echo "Cache Service is starting..."
    fi

        for ((i=0; i<10; i++)); do
                status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1781/rest/check/cachestarted/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "Cache Service is started."
                        isCacheServiceStarted=1
                        healthcheck_status=$(curl --silent localhost:1781/rest/check/cachestatus/)
                        if grep -q "$expected_status" <<< "$healthcheck_status"; then
                                echo "Cache Service is correctly configured and ready."
                                return 0;
                        else
                                echo "Cache Service is not correctly configured or ready."
                                return 1;

                        fi
                fi
        done

        echo "Cache Service is not started."
        return 1;
}

function stopCacheService {

    curl -o /dev/null --silent localhost:1781/Shutdown
        echo "Cache Service is stopped."
        isCacheServiceStarted=0
}

function startDge {
        echo ""
        echo "Starting DGE..."
        cd $dgePath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "DGE is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8084/dge/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${dgeJREPath}java -jar dge.war >/dev/null 2>&1 &
        echo "DGE is starting..."
  fi

        for ((i=0; i<10; i++)); do
                status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8084/dge/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "DGE is started."
                        isDgeStarted=1
                        healthcheck_status=$(curl --silent localhost:8084/dge/rest/check/dgestatus/)
                        if grep -q "$expected_status" <<< "$healthcheck_status"; then
                                echo "DGE is correctly configured and ready."
                                return 0;
                        else
                                echo "DGE is not correctly configured or ready."
                                return 1;
                        fi
                fi
        done

        echo "DGE is not started."
        return 1;
}

function stopDge {

    curl -o /dev/null --silent localhost:8084/dge/Shutdown
        echo "DGE is stopped."
        isDgeStarted=0
}

function startController {
    echo ""
    echo "Starting Controller..."
    cd $controllerPath >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then echo "Controller is not installed or the path indicated is wrong."; return 1; fi
    ./dpctrlsrv -q -fwdir. >/dev/null 2>&1

    if [[ $? -ne 1 ]]; then
            echo "Controller is started."
        isControllerStarted=1
    fi

    if [ "$isControllerStarted" -ne 1 ]; then
            ./dpctrlsrv -s -fwdir. >/dev/null 2>&1
            sleep 1
            echo "Controller is starting..."
            for ((i=0; i<10; i++)); do
                    ./dpctrlsrv -q -fwdir. >/dev/null 2>&1
                    if [[ $? -eq 1 ]]; then
                            sleep 1
                    else
                            echo "Controller is started."
                            isControllerStarted=1
                            return 0;
                    fi
            done
            echo "Controller is not started."
            return 1;
    fi
}

function stopController {

    cd $controllerPath >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then echo "Controller is not installed or the path indicated is wrong."; return 1; fi
    ./dpctrlsrv -q -fwdir. >/dev/null &

    if [[ $? -eq 0 ]]; then
            ./dpctrlsrv -t -fwdir. >/dev/null &
            for ((i=0; i<10; i++)); do
                    ./dpctrlsrv -q -fwdir. >/dev/null &
                    if [[ $? -ne 0 ]]; then
                            sleep 1
                    fi
            done
    fi
    echo "Controller is stopped."
    isControllerStarted=0
}

function startLicenseServer {
    echo ""
    echo "Starting License Server..."

    cd $licenseServerPath >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then echo "License Server is not installed or the path indicated is wrong."; return 1; fi
    ${licenseServerJREPath}java -jar dplicenseserver.jar -query >/dev/null

    if [[ $? -ne 0 ]]; then
        echo "License Server is started."
        isLicenseServerStarted=1
    fi

    if [ "$isLicenseServerStarted" -ne 1 ]; then
            ${licenseServerJREPath}java -jar dplicenseserver.jar -start >/dev/null &
            echo "License Server is starting..."
            for ((i=0; i<10; i++)); do
                    ${licenseServerJREPath}java -jar dplicenseserver.jar -query >/dev/null
                    if [[ $? -eq 0 ]]; then
                            sleep 1
                    else
                            echo "License Server is started."
                            isLicenseServerStarted=1
                            return 0;
                    fi
            done
            echo "License Server is not started."
            return 1;
    fi
}

function stopLicenseServer {

    cd $licenseServerPath >/dev/null 2>&1
    ${licenseServerJREPath}java -jar dplicenseserver.jar -query >/dev/null

    if [[ $? -ne 0 ]]; then
            ${licenseServerJREPath}java -jar dplicenseserver.jar -stop >/dev/null &
            for ((i=0; i<10; i++)); do
                    ${licenseServerJREPath}java -jar dplicenseserver.jar -query >/dev/null
                    if [[ $? -ne 0 ]]; then
                            sleep 1
                    else
                            echo "License Server is stopped."
                            isLicenseServerStarted=0
                            return 0;
                    fi
            done
            return 1;
    fi
}

function startActiveSpooler {
        echo ""
        echo "Starting ActiveSpooler..."
        cd $activeSpoolerPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "ActiveSpooler is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8085/dpactivespooler/)
        if [[ "$status_code" -ne 200 ]]; then
        	nohup ${activeSpoolerJREPath}java -jar dpactivespooler.war >/dev/null 2>&1 &
       	 	echo "ActiveSpooler is starting..."
    	fi

        for ((i=0; i<30; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8085/dpactivespooler/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "ActiveSpooler is started."
                        isActiveSpoolerStarted=1
                        healthcheck_status=$(curl --silent localhost:8085/dpactivespooler/rest/check/server-status/)
                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "ActiveSpooler is correctly configured and ready."
                                return 0;
                        else
                                echo "ActiveSpooler is not correctly configured or ready."
                                return 1;
                        fi
                fi
        done
        echo "ActiveSpooler is not started."
        return 1;
}

function stopActiveSpooler() {

    curl -o /dev/null --silent localhost:8085/dpactivespooler/Shutdown
        echo "ActiveSpooler is stopped."
        isActiveSpoolerStarted=0
}

function startInputAgent {
        echo ""
        echo "Starting InputAgent..."
        cd $inputAgentPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "InputAgent is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1803/dpinputagent/status/isAlive)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${inputAgentJREPath}java -jar dpinputagent.war >/dev/null 2>&1 &
        echo "InputAgent is starting..."
    fi

        for ((i=0; i<30; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1803/dpinputagent/status/isAlive)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "InputAgent is started."
                        isInputAgentStarted=1
                        healthcheck_status=$(curl --silent localhost:1803/dpinputagent/status/service-status)

                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "InputAgent is correctly configured and ready."
                                return 0;
                        else
                                echo "InputAgent is not correctly configured or ready."
                                return 1;
                        fi
                fi
        done
        echo "InputAgent is not started."
        return 1;
}

function stopInputAgent() {

    curl -o /dev/null --silent localhost:1803/dpinputagent/shutdown
        echo "InputAgent is stopped."
        isInputAgentStarted=0
}

function startDocManagerService {
        echo ""
        echo "Starting DocManager Service..."
        cd $docManagerServicePath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "DocManager Service is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1785/dpdocarsrv/status/isAlive)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${docManagerServiceJREPath}java -jar dpdocarsrv.war >/dev/null 2>&1 &
        echo "DocManager Service is starting..."
    fi

        for ((i=0; i<30; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1785/dpdocarsrv/status/isAlive)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "DocManager Service is started."
                        isDocManagerServiceStarted=1
                        healthcheck_status=$(curl --silent localhost:1785/dpdocarsrv/status/service-status)
                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "DocManager Service is correctly configured and ready."
                                return 0;
                        else
                                echo "DocManager Service is not correctly configured or ready."
                                return 1;
                        fi
                fi
        done
        echo "DocManager Service is not started."
        return 1;
}

function stopDocManagerService() {

    curl -o /dev/null --silent localhost:1785/dpdocarsrv/shutdown
        echo "DocManager Service is stopped."
        isDocManagerServiceStarted=0
}

function startDocManagerContentServer {
        echo ""
        echo "Starting DocManager Content Server..."
        cd $docManagerServicePath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "DocManager Content Server is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8983/solr/docmanagerar/admin/ping)
        if [[ "$status_code" -ne 401 ]]; then
        nohup ./startContentServer.sh >/dev/null 2>&1 &
        echo "DocManager Content Server is starting..."
    fi

        for ((i=0; i<60; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8983/solr/docmanagerar/admin/ping)
                if [[ "$status_code" -ne 401 ]]; then
                        sleep 1
                else
                        echo "DocManager Content Server is started."
                        isDocManagerContentServerStarted=1
                        return 0;

                fi
        done
        echo "DocManager Content Server is not started."
        return 1;
}

function stopDocManagerContentServer() {

    cd $docManagerServicePath >/dev/null 2>&1
        nohup ./stopContentServer.sh >/dev/null 2>&1 &
        echo "DocManager Content Server is stopped."
        isDocManagerContentServerStarted=0
}

function startDocManagerWebTool {
        echo ""
        echo "Starting DocManager WebTool..."
        cd $docManagerWebToolPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "DocManager WebTool is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1786/dpdocarwebtool/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${docManagerWebToolJREPath}java -jar dpdocarwebtool.war >/dev/null 2>&1 &
        echo "DocManager WebTool is starting..."
    fi

        for ((i=0; i<30; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1786/dpdocarwebtool/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "DocManager WebTool is started."
                        isDocManagerWebToolStarted=1
                        return 0
                fi
        done
        echo "DocManager WebTool is not started."
        return 1;
}

function stopDocManagerWebTool() {

    curl -o /dev/null --silent localhost:1786/dpdocarwebtool/shutdown
        echo "DocManager WebTool is stopped."
        isDocManagerWebToolStarted=0
}

function startAim {
        echo ""
        echo "Starting AIM..."

        cd "$aimPath" >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "AIM is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8080/aim/ping/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${aimJREPath}java -jar aim.war >/dev/null 2>&1 &
        echo "AIM is starting..."
    fi

        for ((i=0; i<50; i++)); do
            status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8080/aim/ping/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "AIM is started."
                        isAimStarted=1
                        healthcheck_status=$(curl --silent localhost:8080/aim/healthcheck/)
                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "AIM is correctly configured and ready."
                                return 0;
                        else
                                echo "AIM is not correctly configured or ready."
                                return 1;
                        fi
                fi
        done
        echo "AIM is not started."
        return 1;
}

function stopAim() {

    curl -o /dev/null --silent localhost:8080/aim/shutdown
        echo "AIM is stopped."
        isAimStarted=0
}

function startJobProcessor {
        echo ""
        echo "Starting JobProcessor..."
        cd $jobProcessorPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "JobProcessor is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1812/jobprocessor/webresources/status/service-status/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${JobProcessorJREPath}java -jar jobprocessor.war >/dev/null 2>&1 &
        echo "JobProcessor is starting..."
    fi

        for ((i=0; i<60; i++)); do
                status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1812/jobprocessor/webresources/status/service-status/)
                if [[ "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "JobProcessor is started."
                        isJobProcessorStarted=1
                        healthcheck_status=$(curl --silent localhost:1812/jobprocessor/webresources/status/service-status/)
                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "JobProcessor is correctly configured and ready."
                                return 0;
                        else
                                echo "JobProcessor is not correctly configured or ready."
                                return 1;

                        fi
                fi
        done

        echo "JobProcessor is not started."
        return 1;
}

function stopJobProcessor {

    echo "JobProcessor is stopping."
	for ((i=0; i<60; i++)); do
    status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1812/jobprocessor/Shutdown)
	if [[ "$status_code" -ne 000 ]]; then
			sleep 1
	fi
	done
    echo "JobProcessor is stopped."
    isJobProcessorStarted=0
}

function startSinclair {
        echo ""
        echo "Starting Sinclair..."
        cd $sinclairPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "Sinclair is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1806/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${sinclairJREPath}java -jar dpsinclair.war >/dev/null 2>&1 &
        echo "Sinclair is starting..."
    fi

        for ((i=0; i<60; i++)); do
                status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1806/dpsinclair/status/service-status/)
                if [[ "$status_code" -ne 503 && "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "Sinclair is started."
                        isSinclairStarted=1
                        healthcheck_status=$(curl --silent localhost:1806/dpsinclair/status/service-status/)
                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "Sinclair is correctly configured and ready."
                                return 0;
                        else
                                echo "Sinclair is not correctly configured or ready."
                                return 1;

                        fi
                fi
        done

        echo "Sinclair is not started."
        return 1;
}

function stopSinclair {

    echo "Sinclair is stopping."
	for ((i=0; i<60; i++)); do
    status_code=$(curl -X POST -o /dev/null -w "%{http_code}" --silent localhost:1806/dpsinclair/actuator/shutdown)
	if [[ "$status_code" -ne 000 ]]; then
			sleep 1
	fi
	done
    echo "Sinclair is stopped."
    isSinclairStarted=0
}

function stopSinclairIndex {
	
    echo "Sinclair Index is stopping."
	for ((i=0; i<60; i++)); do
    status_code=$(curl -X POST -o /dev/null -w "%{http_code}" --silent localhost:1807/dpsinclairindex/actuator/shutdown)
	if [[ "$status_code" -ne 000 ]]; then
			sleep 1
	fi
	done
    echo "Sinclair Index is stopped."
    isSinclairIndexStarted=0
}

function startSinclairIndex {
        echo ""
        echo "Starting Sinclair Index..."
        cd $sinclairIndexPath >/dev/null 2>&1
        if [[ $? -ne 0 ]]; then echo "Sinclair Index is not installed or the path indicated is wrong."; return 1; fi

        status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1807/)
        if [[ "$status_code" -ne 200 ]]; then
        nohup ${sinclairIndexJREPath}java -jar dpsinclairindex.war >/dev/null 2>&1 &
        echo "Sinclair Index is starting..."
    fi

        for ((i=0; i<60; i++)); do
                status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1807/dpsinclairindex/status/service-status/)
                if [[ "$status_code" -ne 503 && "$status_code" -ne 200 ]]; then
                        sleep 1
                else
                        echo "Sinclair is started."
                        isSinclairIndexStarted=1
                        healthcheck_status=$(curl --silent localhost:1807/dpsinclairindex/status/service-status/)
                        if grep -q "$expected_status2" <<< "$healthcheck_status"; then
                                echo "Sinclair Index is correctly configured and ready."
                                return 0;
                        else
                                echo "Sinclair Index is not correctly configured or ready."
                                return 1;

                        fi
                fi
        done

        echo "Sinclair Index is not started."
        return 1;
}

function stopServices {
        echo ""
        echo "Stopping services..."
        if [ "$isAimStarted" -eq 1 ]; then stopAim; fi
        if [ "$isControllerStarted" -eq 1 ]; then stopController; fi
        if [ "$isResourceOnDemandStarted" -eq 1 ]; then stopResourceOnDemand; fi
        if [ "$isCacheServiceStarted" -eq 1 ]; then stopCacheService; fi
        if [ "$isDgeStarted" -eq 1 ]; then stopDge; fi
        if [ "$isActiveSpoolerStarted" -eq 1 ]; then stopActiveSpooler; fi
        if [ "$isInputAgentStarted" -eq 1 ]; then stopInputAgent; fi
        if [ "$isDocManagerServiceStarted" -eq 1 ]; then stopDocManagerService; fi
        if [ "$isDocManagerWebToolStarted" -eq 1 ]; then stopDocManagerWebTool; fi
        if [ "$isDocManagerContentServerStarted" -eq 1 ]; then stopDocManagerContentServer; fi
        if [ "$isLicenseServerStarted" -eq 1 ]; then stopLicenseServer; fi
        if [ "$isJobProcessorStarted" -eq 1 ]; then stopJobProcessor; fi
	if [ "$isSinclairStarted" -eq 1 ]; then stopSinclair; fi
	if [ "$isSinclairIndexStarted" -eq 1 ]; then stopSinclairIndex; fi
        echo ""
}

checkUser
if [[ $? -ne 0 ]]; then echo "Startup script cannot be started because the user is not correctly configured."; exit 15; fi

echo "Starting services..."
startLicenseServer
if [[ $? -ne 0 ]]; then echo "License Server cannot be started properly and will be stopped."; stopServices; exit 1; fi
startAim
if [[ $? -ne 0 ]]; then echo "AIM cannot be started properly and will be stopped."; stopServices; exit 10; fi
startResourceOnDemand
if [[ $? -ne 0 ]]; then echo "Resource On Demand cannot be started properly and will be stopped."; stopServices; exit 2; fi
startCacheService
if [[ $? -ne 0 ]]; then echo "Cache Service cannot be started properly and will be stopped."; stopServices; exit 3; fi
startDge
if [[ $? -ne 0 ]]; then echo "DGE cannot be started properly and will be stopped."; stopServices; exit 4; fi
startController
if [[ $? -ne 0 ]]; then echo "Controller cannot be started properly and will be stopped."; stopServices; exit 5; fi
startActiveSpooler
if [[ $? -ne 0 ]]; then echo "ActiveSpooler cannot be started properly and will be stopped."; stopServices; exit 6; fi
startInputAgent
if [[ $? -ne 0 ]]; then echo "InputAgent cannot be started properly and will be stopped."; stopServices; exit 7; fi
startDocManagerService
if [[ $? -ne 0 ]]; then echo "DocManager Service cannot be started properly and will be stopped."; stopServices; exit 8; fi
startDocManagerWebTool
if [[ $? -ne 0 ]]; then echo "DocManager WebTool cannot be started properly and will be stopped."; stopServices; exit 9; fi
startDocManagerContentServer
if [[ $? -ne 0 ]]; then echo "DocManager Content Server cannot be started properly and will be stopped."; stopServices; exit 11; fi
startJobProcessor
if [[ $? -ne 0 ]]; then echo "JobProcessor cannot be started properly and will be stopped."; stopServices; exit 12; fi
startSinclair
if [[ $? -ne 0 ]]; then echo "Sinclair cannot be started properly and will be stopped."; stopServices; exit 13; fi
startSinclairIndex
if [[ $? -ne 0 ]]; then echo "Sinclair Index cannot be started properly and will be stopped."; stopServices; exit 14; fi
