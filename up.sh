#!/bin/bash
set -x
source env.sh

#echo ${HAPROXY_IP}
rm -Rf ${PERSISTENCE_PREFIX}

# If this is the first run, the persistent dirs should be created
#if [ ! -d "${OC_PERSISTENCE}" ]; then
  echo "Creating volumes..."
  mkdir -p ${BROWSER_PERSISTENCE}
  mkdir -p ${CONTROLLER2_CACHES}
  mkdir -p ${CONTROLLER1_CACHES}
  mkdir -p ${CONTROLLER_PERSISTENCE}
  mkdir -p ${OC_PERSISTENCE}
  mkdir -p ${AGENT_PERSISTENCE}
  #chown -R 1000:1000 ${CONTROLLER2_CACHES}
  #chown -R 1000:1000 ${CONTROLLER1_CACHES}
  #chown -R 1000:1000 ${CONTROLLER_PERSISTENCE}
  #chown -R 1000:1000 ${OC_PERSISTENCE}
  #chown -R 1000:1000 ${AGENT_PERSISTENCE}
  chmod 700 ${CONTROLLER2_CACHES}
  chmod 700 ${CONTROLLER1_CACHES}
  chmod 700 ${CONTROLLER_PERSISTENCE}
  chmod 700 ${OC_PERSISTENCE}
  chmod 700 ${AGENT_PERSISTENCE}
#fi


echo Using Docker host IP: ${DOCKER_HOST_IP}
echo "###"

envsubst < docker-compose.yaml.template > docker-compose.yaml

docker compose up #-d

