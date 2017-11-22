#!/bin/bash

CONFIG_REPO_URI=https://github.com/fahimfarookme/eureka-server-peer-update-issue
CONFIG_REPO_PATH=config-repo
CONFIG_SERVER_PORT=11001
DEBUG="-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=6005,suspend=n"

function wait_till_started {
	until [ "`curl --silent --show-error --connect-timeout 1 http://localhost:$1/health | grep 'UP'`" != "" ];
	do
	  echo "sleeping for 10 seconds..."
	  sleep 10
	done
}

function update_in_config_repo {

	if [[ -e .host ]] 
	then host=`cat .host`
	else host=-1
	fi
	
	((host++))
	echo $host > .host
	
	echo "eureka.client.service-url.defaultZone=http://host-${host}:888${host}/eureka" > ../config-repo/application.properties
	git add ../config-repo/application.properties
	git status
	git commit -m "Auto commit"
	git push origin master
	printf "\n\nUpdated defaultZone to http://host-${host}:888${host}/eureka in config-repo"
}

printf "\n\nPackaging...\n\n"
mvn clean package

printf "\n\nStarting the config-server...\n\n"
java -Dport=$CONFIG_SERVER_PORT -Dconfig.repo.uri=$CONFIG_REPO_URI -Dconfig.repo.path=$CONFIG_REPO_PATH -jar config-server/target/config-server-0.0.1-SNAPSHOT.jar &
wait_till_started   $CONFIG_SERVER_PORT

printf "\n\nStarting the eureka server...\n\n"
java $DEBUG -Dconfig.server.uri=http://localhost:$CONFIG_SERVER_PORT -Dport=14001 -jar eureka-server/target/eureka-server-0.0.1-SNAPSHOT.jar &
wait_till_started   14001

printf "\n\nBefore updating the service-urls in config-repo...\n\n"
curl -s http://localhost:14001/ | grep http

printf "\n\nUpdating the service-urls in config-repo...\n\n"
update_in_config_repo

printf "\n\nInvoking /refresh endpoint of Eureka Server...\n\n"
curl -X POST http://localhost:14001/refresh

printf "\n\nChecking whether the new date is reflected in Eureka Server...\n\n"
curl -s http://localhost:14001/ | grep http

