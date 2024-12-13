#!/bin/bash
set +x

echo "#### Verify if Docker Desktop is running"
if docker info >/dev/null 2>&1
then
 echo "Docker is running"
else
 echo "DOCKER IS NOT RUNNING. Start Docker Desktop first!!"
 exit 2
fi

echo "#### Source default settings file "
source ./env.sh

echo "#### Verify if SSL is enabled"
SSL=false
for arg in "$@"; do
  if [[ $arg == "ssl=true" ]]; then
    SSL=true
  fi
done
if [[ $SSL == true ]]; then
  echo "SSL is enabled: source ssl settings file"
  SSL_DIR="ssl"
  # Check each file individually
  for file in cacerts jenkins.jks jenkins.pem; do
    if [[ ! -f "$SSL_DIR/$file" ]]; then
      echo "Missing file: $SSL_DIR/$file"
      echo "Create a certificate first to run in SSL mode. Run:"
      echo "cd $SSL_DIR && ./01-createSelfSigned.sh"
      exit 2
    fi
  done
  #Sorce SSl specific overrides
  source ./env-ssl.sh
else
  echo "SSL is disabled."
fi

echo "#### Generate SSH key to secrets/${SSH_KEY_ID}"
if [[ -e "$SSH_PRIVATE_KEY_PATH" && -e "$SSH_PUBLIC_KEY_PATH" ]]; then
    echo "$SSH_PUBLIC_KEY_PATH and $SSH_PUBLIC_KEY_PATH exist already. Delete them manually if you want to re-generate the SSH keys"
else
    echo "$SSH_PRIVATE_KEY_PATH or $SSH_PUBLIC_KEY_PATH file do not exist. They will be generated now"
    ssh-keygen -t rsa -b 2048 -f secrets/${SSH_KEY_ID} -N ""
fi

echo "#### Assign $SSH_PUBLIC_KEY_PATH to JENKINS_AGENT_SSH_PUBKEY"
# Expose SSH PUP_KEY  to Agent authorized_key , see https://hub.docker.com/r/jenkins/ssh-agent for details
export JENKINS_AGENT_SSH_PUBKEY=$(cat $SSH_PUBLIC_KEY_PATH)
echo $JENKINS_AGENT_SSH_PUBKEY

echo "#### Create browser volume in ${BROWSER_PERSISTENCE}"
# create dir for browser persistence
mkdir -p ${BROWSER_PERSISTENCE}

echo "#### Create Controller related volumes like JENKINS_HOME and cache dirs in $PERSISTENCE_PREFIX"
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

echo "#### Create Operations Center related volumes JENKINS_HOME in ${OC_PERSISTENCE}"
# create JENKINS_HOME dir for cjoc
mkdir -p ${OC_PERSISTENCE}
# create dir for cjoc casc bundle
mkdir -p ${OC_PERSISTENCE}/cascbundle
# copy cjoc casc bundle to JENKINS_HOME/cascbundle
cp -Rf casc/cjoc/*.yaml ${OC_PERSISTENCE}/cascbundle/

echo "#### Check if a wildcard license exist: $CJOC_LICENSE_PRIVATE_KEY and $CJOC_LICENSE_CERTIFICATE"
#TODO: This can be improved
# If no wild card license exist in the secrets directory, we create a dummy placeholder.
# If we don`t do this, the Casc process complains
if [[ ! -e "$CJOC_LICENSE_PRIVATE_KEY" && ! -e "$CJOC_LICENSE_CERTIFICATE" ]]; then

cat << EOF > $CJOC_LICENSE_PRIVATE_KEY
-----BEGIN RSA PRIVATE KEY-----
Placeholder DO NOT CHANGE HERE
-----END RSA PRIVATE KEY-----
EOF

cat << EOF > $CJOC_LICENSE_CERTIFICATE
-----BEGIN CERTIFICATE-----
Placeholder DO NOT CHANGE HERE
-----END CERTIFICATE-----
EOF

fi

# Copy license to cjoc JENKINS_HOME, regardless if it is the CB Wildcard license or the dummy license from above
# We will apply the license during casc startup to the operations center
# If the license is not valid (dummy license from above), you will see the License welcome screen in Cjoc where you can request a trial license
cp -f $CJOC_LICENSE_PRIVATE_KEY ${OC_PERSISTENCE}/$(basename "$CJOC_LICENSE_PRIVATE_KEY")
cp -f $CJOC_LICENSE_CERTIFICATE ${OC_PERSISTENCE}/$(basename "$CJOC_LICENSE_CERTIFICATE")

echo "#### Create Agent volume in ${AGENT_PERSISTENCE}"
# create dir for agent
mkdir -p ${AGENT_PERSISTENCE}

echo "#### Set volume permissions"
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

echo "#### Render the docker compose template "
envsubst < docker-compose.yaml.template > docker-compose.yaml

echo "#### Start the containers"
docker compose up -d

echo "#### All containers are started now. Data is persisted in ${PERSISTENCE_PREFIX}"

echo "#### Open ${OC_URL} "
echo "Verify if you have updated your /etc/hosts with  ${OC_URL} and  ${CLIENTS_URL}"
if ping -c 1 "${OC_URL}" > /dev/null 2>&1 && ping -c 1 "${CLIENTS_URL}" > /dev/null 2>&1
then
    echo "Host name resolution successful for ${OC_URL} and ${CLIENTS_URL}."
    open ${HTTP_PROTOCOL}://${OC_URL}
else
    echo """
         Host name resolution failed for ${OC_URL} and ${CLIENTS_URL} om Docker host in /etc/hosts
         That's fine, so we open a browser in a container box in your browser:
         * There: Open Firefox from the 'APPLICATIONS' menu top to the left
         * Then open ${HTTP_PROTOCOL}://${OC_URL} in the URL bar
         """
    open http://localhost:3000
fi




