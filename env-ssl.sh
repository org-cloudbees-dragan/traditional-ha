#!/bin/bash

set +x

echo "#### Common SSL Options for Controllers and Cjoc"

export KEYSTORE="/tmp/jenkins.jks"
export CACERTS="/tmp/cacerts"
export KEYSTORE_PW="changeit"
export JENKINS_SSL_OPTS="--httpPort=-1 --httpsKeyStore=$KEYSTORE --httpsKeyStorePassword=$KEYSTORE_PW  --httpsPort=8443"
export JAVA_SSL_OPTS="-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true -DexecutableWar.jetty.disableCustomSessionIdCookieName=true  -Djavax.net.ssl.keyStore=$CACERTS -Djavax.net.ssl.keyStorePassword=$KEYSTORE_PW  -Djavax.net.ssl.trustStore=$CACERTS -Djavax.net.ssl.trustStorePassword=$KEYSTORE_PW -Djavax.net.ssl.trustStoreType=JKS"

########################################################################################################################

#For SSL
export CONTROLLER_JAVA_OPTS="$CONTROLLER_JAVA_OPTS $JAVA_SSL_OPTS"
export CONTROLLER_JENKINS_OPTS="$CONTROLLER_JENKINS_OPTS $JENKINS_SSL_OPTS"


export CJOC_JAVA_OPTS="$CJOC_JAVA_OPTS $JAVA_SSL_OPTS"
export CJOC_JENKINS_OPTS="$JENKINS_SSL_OPTS"

export HA_PROXY_BIND_PORT=443
export HTTP_PROTOCOL=https
export HTTP_PORT=8443
########################################################################################################################








