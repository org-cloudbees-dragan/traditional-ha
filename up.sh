#!/bin/bash
set +x
source env.sh

echo "############################### generate SSH key to secrets/${SSH_KEY_ID}"
if [[ -e "$SSH_PRIVATE_KEY_PATH" && -e "$SSH_PUBLIC_KEY_PATH" ]]; then
    echo "$SSH_PUBLIC_KEY_PATH and $SSH_PUBLIC_KEY_PATH exist already. Delete them manually if you want to re-generate the SSH keys"
else
    echo "$SSH_PUBLIC_KEY_PATH or $SSH_PUBLIC_KEY_PATH file do not exist. They will be generated now"
    ssh-keygen -t rsa -b 2048 -f secrets/${SSH_KEY_ID} -N ""
fi

echo "############################### Assign $SSH_PUBLIC_KEY_PATH to JENKINS_AGENT_SSH_PUBKEY"
# THE FOLLOWING IS NOT VERY SECURED, AS LONG AS WE DO SO JUST ON LOCALHOST FOR DEMO PURPOSE IT SHOULD BE OK
# Expose SSH PUP_KEY  to Agent authorized_key , see https://hub.docker.com/r/jenkins/ssh-agent for details
export JENKINS_AGENT_SSH_PUBKEY=$(cat $SSH_PUBLIC_KEY_PATH)

echo  "############################### Verify DNS"
echo "Verify if you have updated your /etc/hosts file with the local DNS names for ${OC_URL} and  ${CLIENTS_URL}"
checkNameResolution () {
  HOSTNAME=$1
  if ping -c 1 "$HOSTNAME" > /dev/null 2>&1
  then
      echo "Host name resolution successful for $HOSTNAME."
  else
      echo "Host name resolution failed for $HOSTNAME."
      echo """
        If you access the Operations Center from the browser in a box (http://localhost:3000) you can ignore this message.
        However, if you want to access the Operations Center for your browser (on Docker Host):
        # Open you /etc/hosts file and add/update the following line:

        127.0.0.1	localhost ${OC_URL} ${CLIENTS_URL}

        # Then, optional (MacOs): flush your DNS cache running this command:

        sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
      """
  fi
}

checkNameResolution ${OC_URL}
checkNameResolution ${CLIENTS_URL}

echo "############################### Create all volumes under $PERSISTENCE_PREFIX"

echo "############################### Create browser volume in ${BROWSER_PERSISTENCE}"

# create dir for browser persistence
mkdir -p ${BROWSER_PERSISTENCE}

echo "############################### Create Controller related volumes like JENKINS_HOME and cache dirs in $PERSISTENCE_PREFIX"

##### Create caches

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
#create shared JENKINS_HOME
mkdir -p ${CONTROLLER_PERSISTENCE}
# create dir for controller casc bundle
mkdir -p ${CONTROLLER_PERSISTENCE}/cascbundle
# copy controller casc bundle to JENKINS_HOME/cascbundle
cp -Rf casc/controller/*.yaml ${CONTROLLER_PERSISTENCE}/cascbundle/
# We copy the $SSH_PRIVATE_KEY_PATH to the JENKINS_HOME dir so we can used it in casc controller bundle to initialize the ssh-agent credential
cp -vf $SSH_PRIVATE_KEY_PATH $CONTROLLER_PERSISTENCE/id_rsa
chmod 600 $CONTROLLER_PERSISTENCE/id_rsa

echo  "############################### Create Operations Center related volumes JENKINS_HOME in ${OC_PERSISTENCE}"

# create JENKINS_HOME dir for cjoc
mkdir -p ${OC_PERSISTENCE}
# create dir for cjoc casc bundle
mkdir -p ${OC_PERSISTENCE}/cascbundle
# copy cjoc casc bundle to JENKINS_HOME/cascbundle
cp -Rf casc/cjoc/*.yaml ${OC_PERSISTENCE}/cascbundle/

# copy cloudbees wildcard license to cjoc JENKINS_HOME
# We will apply the license during casc startup to the operations center
#cp -f $CJOC_LICENSE_PRIVATE_KEY ${OC_PERSISTENCE}/cb-wildcard-license.key
cp -f $CJOC_LICENSE_PRIVATE_KEY ${OC_PERSISTENCE}/$(basename "$CJOC_LICENSE_PRIVATE_KEY")
#cp -f $CJOC_LICENSE_CERTIFICATE ${OC_PERSISTENCE}/cb-wildcard-license.cert
cp -f $CJOC_LICENSE_CERTIFICATE ${OC_PERSISTENCE}/$(basename "$CJOC_LICENSE_CERTIFICATE")

echo  "############################### Create Agent volume in ${AGENT_PERSISTENCE}"

# create dir for agent
mkdir -p ${AGENT_PERSISTENCE}

echo  "############################### Set volume permissions"

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

echo "All containers are started now. Data is persisted in ${PERSISTENCE_PREFIX}"

echo """
Two browser tabs will be opened now in your Web browser:

One tab with a browser in a box http://localhost:3000
In this, open Firefox from the top left 'Applications' menu and type http://${OC_URL} in the browser bar

Another tab tah point directly to http://${OC_URL}
You can decide in which one to continue. This option requires you have names entries in /etc/hosts done
"""
# open browser on docker host
open http://${OC_URL}
# open browser in a box
open http://localhost:3000


