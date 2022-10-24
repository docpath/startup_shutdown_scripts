#!/bin/bash

### Script version ###
scriptVersion="1.0.1"
######################

echo "[Services Startup Script - v"$scriptVersion"]"

isLicenseServerStarted=0
isControllerStarted=0
isResourceOnDemandStarted=0
isCacheServiceStarted=0
isDgeStarted=0

licenseServerPath=/usr/local/docpath/licenseserver/licenseserver/Bin
controllerPath=/usr/local/docpath/controllercorepack
resourceOnDemandPath=/usr/local/docpath/docgenerationexpansion/resourcesondemand/Bin
cacheServicePath=/usr/local/docpath/docgenerationexpansion/cacheservice/Bin
dgePath=/usr/local/docpath/generation

expected_status='isValid":true}],"name":"General_Status"'

function startResourceOnDemand {
	
	echo "Starting Resources on Demand..."
	cd $resourceOnDemandPath >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then echo "Resources on Demand is not installed or the path indicated is wrong."; return 1; fi
	
	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1782/DpRoD/)
	if [[ "$status_code" -ne 200 ]]; then
        nohup java -jar dprodservice.war >/dev/null 2>&1 &
    	echo "Resources on Demand is starting..."
    fi

	for ((i=0; i<10; i++)); do
	    status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1782/DpRoD/)
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
	
	echo "Starting Cache Service..."
	cd $cacheServicePath >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then echo "Cache Service is not installed or the path indicated is wrong."; return 1; fi
	
	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1781/)
	if [[ "$status_code" -ne 200 ]]; then
        nohup java -jar dpcacheservice.war >/dev/null 2>&1 &
    	echo "Cache Service is starting..."
    fi

	for ((i=0; i<10; i++)); do
		status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1781/)
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
	
	echo "Starting DGE..."
	cd $dgePath >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then echo "DGE is not installed or the path indicated is wrong."; return 1; fi
	
	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8084/dge/)
	if [[ "$status_code" -ne 200 ]]; then
        nohup java -jar dge.war >/dev/null 2>&1 &
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
    ./dpctrlsrv -q -fwdir.

    if [[ $? -eq 1 ]]; then
	    ./dpctrlsrv -t -fwdir.
	    for ((i=0; i<10; i++)); do
		    ./dpctrlsrv -q -fwdir.
		    if [[ $? -ne 1 ]]; then
			    sleep 1
		    else
			    echo "Controller is stopped."
			    isControllerStarted=0
			    break
		    fi
	    done
    fi
}

function startLicenseServer {

    echo "Starting License Server..."

    cd $licenseServerPath >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then echo "License Server is not installed or the path indicated is wrong."; return 1; fi
    java -jar dplicenseserver.jar -query >/dev/null

    if [[ $? -ne 0 ]]; then
        echo "License Server is started."
        isLicenseServerStarted=1
    fi

    if [ "$isLicenseServerStarted" -ne 1 ]; then 
	    java -jar dplicenseserver.jar -start >/dev/null &
	    echo "License Server is starting..." 
	    for ((i=0; i<10; i++)); do
		    java -jar dplicenseserver.jar -query >/dev/null
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
    java -jar dplicenseserver.jar -query >/dev/null

    if [[ $? -ne 0 ]]; then
	    java -jar dplicenseserver.jar -stop >/dev/null &
	    for ((i=0; i<10; i++)); do
		    java -jar dplicenseserver.jar -query >/dev/null
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

function stopServices {

	echo "Stopping services..."
	if [ "$isLicenseServerStarted" -eq 1 ]; then stopLicenseServer; fi
	if [ "$isControllerStarted" -eq 1 ]; then stopController; fi
	if [ "$isResourceOnDemandStarted" -eq 1 ]; then stopResourceOnDemand; fi
	if [ "$isCacheServiceStarted" -eq 1 ]; then stopCacheService; fi
	if [ "$isDgeStarted" -eq 1 ]; then stopDge; fi
}

echo "Starting services..."
startLicenseServer
if [[ $? -ne 0 ]]; then echo "License Server cannot be started properly and will be stopped."; stopServices; exit 1; fi
startResourceOnDemand
if [[ $? -ne 0 ]]; then echo "Resource On Demand cannot be started properly and will be stopped."; stopServices; exit 2; fi
startCacheService
if [[ $? -ne 0 ]]; then echo "Cache Service cannot be started properly and will be stopped."; stopServices; exit 3; fi
startDge
if [[ $? -ne 0 ]]; then echo "DGE cannot be started properly and will be stopped."; stopServices; exit 4; fi
startController
if [[ $? -ne 0 ]]; then echo "Controller cannot be started properly and will be stopped."; stopServices; exit 5; fi

