#! /bin/bash

source ../env.sh

echo "YOU NEED TO CREATE A ADMIN TOKEN ON THE OPERATIONS CENTER FIRST"
#ADMIN_USER and ADMIN_TOKEN combined
ADMINTOKEN="admin:<ADMINTOKEN>"

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

	#curl -i -u $TOKEN -X POST  $CONTROLLER_URL/job/$JOB/build
	#RESPONSE=$(curl  -si -w "\n%{size_header},%{size_download}" -u $TOKEN -X POST  $CONTROLLER_URL/job/$JOB/build)
	#see curl headers https://daniel.haxx.se/blog/2022/03/24/easier-header-picking-with-curl/
  #-b cookie-jar.txt

  # trigger our testpipeline
	curl --connect-timeout  $CONNECT_TIMEOUT  -s -IL -o $RESPONSEHEADERS  -u $ADMINTOKEN -X POST  "$CONTROLLER_URL/job/$JOB/build?delay=0sec"
  # check if we got a healthy HTTP response state in the response header
  # Response header gets written by each loop/request in the $RESPONSEHEADERS (heade) file
  if [ -z "$(cat $RESPONSEHEADERS |grep -oE 'HTTP/2 201|HTTP/ 200|HTTP/1.1 201')" ]
  then
      echo "Can not create job, Gateway/Endpoint not available with HTTP state:  $(cat $RESPONSEHEADERS |grep 'HTTP/2') "
      exit 1
	else
	    # read the wanted information like replica host and ip address in variables
	    LOCATION="$(cat $RESPONSEHEADERS    |grep -E "location.*"                  |  awk '{print $2}')"
	    REPLICA="$(cat $RESPONSEHEADERS     |grep -E "x-jenkins-replica-host.*"    |  awk '{print $2}')"
	    REPLICA_IP="$(cat $RESPONSEHEADERS  |grep -E "x-jenkins-replica-address.*" |  awk '{print $2}')"
	    echo "LOCATION:  $LOCATION"
	    echo "REPLICA:   $REPLICA"
	    echo "REPLICA:   $REPLICA_IP"
	    #curl -u $TOKEN  -IL $LOCATION/api/json?pretty=true
	fi
	# sleep
	sleep $CONNECT_TIMEOUT
done


