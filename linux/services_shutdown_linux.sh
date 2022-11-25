#!/bin/bash

### Script version ###
scriptVersion="1.0.0"
######################

echo "[Services Shutdown Script - v"$scriptVersion"]"

isLicenseServerStarted=1
isAimStarted=1
isControllerStarted=1
isResourceOnDemandStarted=1
isCacheServiceStarted=1
isDgeStarted=1
isActiveSpoolerStarted=1
isInputAgentStarted=1
isDocManagerServiceStarted=1
isDocManagerWebToolStarted=1
isDocManagerContentServerStarted=1

licenseServerPath=/usr/local/docpath/licenseserver/licenseserver/Bin
controllerPath=/usr/local/docpath/controllercorepack
docManagerServicePath=/usr/local/docpath/docmanagerarpack6/service

expected_status='isValid":true}],"name":"General_Status"'
expected_status2='"status":"running"'


function stopResourceOnDemand() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1782/DpRoD/)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:1782/DpRoD/Shutdown
	fi

	echo "Resources on Demand is stopped."
	isResourceOnDemandStarted=0
}



function stopCacheService {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1781/)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:1781/Shutdown
	fi

	echo "Cache Service is stopped."
	isCacheServiceStarted=0
}


function stopDge {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8084/dge/)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:8084/dge/Shutdown
	fi

	echo "DGE is stopped."
	isDgeStarted=0
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


function stopLicenseServer {

	cd $licenseServerPath >/dev/null 2>&1
	if [[ $? -ne 0 ]]; then echo "License Server is not installed or the path indicated is wrong."; return 1; fi
	java -jar dplicenseserver.jar -query >/dev/null

	if [[ $? -ne 0 ]]; then
		java -jar dplicenseserver.jar -stop >/dev/null &
		for ((i=0; i<10; i++)); do
			java -jar dplicenseserver.jar -query >/dev/null
			if [[ $? -ne 0 ]]; then
				sleep 1                   
			fi
		done
	fi
	echo "License Server is stopped."
	isLicenseServerStarted=0
}



function stopActiveSpooler() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8085/dpactivespooler/)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:8085/dpactivespooler/Shutdown
	fi

	echo "ActiveSpooler is stopped."
	isActiveSpoolerStarted=0
}



function stopInputAgent() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1803/dpinputagent/status/isAlive)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:1803/dpinputagent/shutdown
	fi

	echo "InputAgent is stopped."
	isInputAgentStarted=0
}



function stopDocManagerService() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1785/dpdocarsrv/status/isAlive)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:1785/dpdocarsrv/shutdown
	fi

	echo "DocManager Service is stopped."
	isDocManagerServiceStarted=0
}



function stopDocManagerContentServer() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8983/solr/docmanagerar/admin/ping)
	if [[ "$status_code" -eq 401 ]]; then
		cd $docManagerServicePath >/dev/null 2>&1
		if [[ $? -ne 0 ]]; then echo "DocManager Content Server is not installed or the path indicated is wrong."; return 1; fi
		nohup ./stopContentServer.sh >/dev/null 2>&1 &
	fi

	echo "DocManager Content Server is stopped."
	isDocManagerContentServerStarted=0
}



function stopDocManagerWebTool() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:1786/dpdocarwebtool/)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:1786/dpdocarwebtool/shutdown
	fi

	echo "DocManager WebTool is stopped."
	isDocManagerWebToolStarted=0
}

function stopAim() {

	status_code=$(curl --write-out %{http_code} -o /dev/null --silent localhost:8080/aim/ping/)
	if [[ "$status_code" -eq 200 ]]; then
		curl -o /dev/null --silent localhost:8080/aim/shutdown
	fi

	echo "AIM is stopped."
	isAimStarted=0
}


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
echo ""
