#!/bin/bash
set +x
source env.sh

# Define the file paths to SSH Key
private_key="$HOME/.ssh/id_rsa"
public_key="$HOME/.ssh/id_rsa.pub"

echo  "verify SSH Key exist"
checkSSHKeyExist () {
  if [[ -f "$2" ]]; then
      echo "$1 key exists: $2"
  else
      echo "$1 key not found: $2"
      echo "Create a ssh key first: run 'ssh-keygen -t rsa -f $private_key'"
      exit 1
  fi
}

checkSSHKeyExist "Private SSH Key" $private_key
checkSSHKeyExist "Public SSH Key" $public_key

echo "Creating volumes..."

# Create cache dirs for HA Controller
# see https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional#_java_options
# see https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional#_jenkins_args
createCaches () {
  mkdir -p ${1}/caches/git
  mkdir -p ${1}/caches/github-branch-source
  mkdir -p ${1}/plugins
  mkdir -p ${1}/war
}

#create cache dirs for controllers
createCaches ${CONTROLLER1_CACHES}
createCaches ${CONTROLLER2_CACHES}

# create dor for browser persistence
mkdir -p ${BROWSER_PERSISTENCE}

#create shared JENKINS_HOME
mkdir -p ${CONTROLLER_PERSISTENCE}
# create dir for controller casc bundle
mkdir -p ${CONTROLLER_PERSISTENCE}/cascbundle
# copy controller casc bundle to JENKINS_HOME/cascbundle
cp -Rf casc/controller/*.yaml ${CONTROLLER_PERSISTENCE}/cascbundle/

# create JENKINS_HOME dir for cjoc
mkdir -p ${OC_PERSISTENCE}
# create dir for controller casc bundle
mkdir -p ${OC_PERSISTENCE}/cascbundle
# copy controller casc bundle to JENKINS_HOME/cascbundle
cp -Rf casc/cjoc/*.yaml ${OC_PERSISTENCE}/cascbundle/

# create dir for agent
mkdir -p ${AGENT_PERSISTENCE}

# chmod to jenkins id, not required yet, maybe later when using NFS
#chown -R 1000:1000 ${CONTROLLER2_CACHES}
#chown -R 1000:1000 ${CONTROLLER1_CACHES}
#chown -R 1000:1000 ${CONTROLLER_PERSISTENCE}
#chown -R 1000:1000 ${OC_PERSISTENCE}
#chown -R 1000:1000 ${AGENT_PERSISTENCE}

# Not sure if we need to chmod
chmod -R 700 ${CONTROLLER2_CACHES}
chmod -R 700 ${CONTROLLER1_CACHES}
chmod 700 ${CONTROLLER_PERSISTENCE}
chmod 700 ${OC_PERSISTENCE}
chmod 700 ${AGENT_PERSISTENCE}

echo "###############################"
# render the compose template
envsubst < docker-compose.yaml.template > docker-compose.yaml

# start the containers
docker compose up -d
# open browser in a box
#open http://localhost:3000
echo "OPEN CJOC IN YOUR BROWSER. Verify if you have updated your /etc/hosts file with the local DNS names for oc.ha and client.ha."
for domain in ${OC_URL} ${CLIENT_URL}; do
    if ping -c 1 "$domain" > /dev/null 2>&1; then
        echo "DNS resolution successful for $domain."
    else
        echo "DNS resolution failed for $domain."
        echo """
          open you /etc/hosts file and add
          127.0.0.1	localhost ${OC_URL} ${CLIENT_URL}
        """
        exit 1
    fi
done
open "http://${OC_URL}"




