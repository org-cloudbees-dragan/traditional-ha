#! /bin/bash

source ../env.sh

#see curl headers https://daniel.haxx.se/blog/2022/03/24/easier-header-picking-with-curl/

echo "YOU NEED TO CREATE A ADMIN TOKEN ON THE OPERATIONS CENTER FIRST"

JENKINS_TOKEN=${1:-"YOUR_ADMIN_TOKEN"}
JENKINS_USER_TOKEN="admin:$JENKINS_TOKEN"
#CONTROLLER_URL=http://client.ha
CONTROLLER_URL=http://${CLIENTS_URL}
#JOBNAME
JOB=testpipeline
#curl connect_timeout
CONNECT_TIMEOUT=5
# File where to write the header
RESPONSEHEADERS=headers

while true
do
 	echo "#######################################"
	echo "start build of Job: $JOB"
  # trigger our testpipeline
	curl --connect-timeout  $CONNECT_TIMEOUT  -s -IL -o $RESPONSEHEADERS  -u $JENKINS_USER_TOKEN -X POST  "$CONTROLLER_URL/job/$JOB/build?delay=0sec"
  # check if we got a healthy HTTP response state in the response header
  # Response header gets written by each loop/request in the $RESPONSEHEADERS (heade) file
  if [ -z "$(cat $RESPONSEHEADERS |grep -oE 'HTTP/2 201|HTTP/ 200|HTTP/1.1 201')" ]
  then
      echo "Can not create job, Gateway/Endpoint not available with HTTP state:  $(cat $RESPONSEHEADERS |grep 'HTTP/2') "
      exit 1
	else
	    # read the wanted information like replica host and ip address in variables
	    LOCATION="$(cat $RESPONSEHEADERS        |grep -E "location.*"                  |  awk '{print $2}')"
	    REPLICA="$(cat $RESPONSEHEADERS         |grep -E "x-jenkins-replica-host.*"    |  awk '{print $2}')"
	    REPLICA_IP="$(cat $RESPONSEHEADERS      |grep -E "x-jenkins-replica-address.*" |  awk '{print $2}')"
	    STICKY_COOKIE="$(cat $RESPONSEHEADERS   |grep -E "set-cookie:.*"               |  awk '{print $2}')"
	    echo "LOCATION:                    $LOCATION"
	    echo "CONTROLLER_REPLICA:          $REPLICA"
	    echo "CONTROLLER_REPLICA_IP:       $REPLICA_IP"
	    echo "CONTROLLER_STICKY_COOKIE:    $STICKY_COOKIE"
	    #curl -u $TOKEN  -IL $LOCATION/api/json?pretty=true
	fi
	sleep $CONNECT_TIMEOUT
done


