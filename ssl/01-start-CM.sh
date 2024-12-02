#! /bin/bash

#Download war
VERSION=2.479.2.3
#curl -O https://downloads.cloudbees.com/cloudbees-core/traditional/client-master/rolling/war/2.479.2.3/cloudbees-core-cm.war

export JENKINS_HOME="./jenkins-home-controller"
export JENKINS_URL=http://client.ha:8444
export KEYSTORE=$(realpath ./jenkins.jks)
export KS_PW="changeit"
java \
-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true \
-DexecutableWar.jetty.disableCustomSessionIdCookieName=true \
-Dcom.cloudbees.jenkins.ha=false \
-Djavax.net.ssl.keyStore=$KEYSTORE \
-Djavax.net.ssl.keyStorePassword=$KS_PW \
-Djavax.net.ssl.trustStore=$KEYSTORE \
-Djavax.net.ssl.trustStorePassword=$KS_PW \
-Djavax.net.ssl.trustStoreType=JKS \
-jar cloudbees-core-cm.war \
--httpPort=-1 \
--httpsKeyStore=$KEYSTORE \
--httpsKeyStorePassword=$KS_PW \
--httpsPort=8444


#-Djavax.net.ssl.keyStore=…/cacerts
#-Djavax.net.ssl.keyStorePassword=…
#-Djavax.net.ssl.trustStore=…/cacerts
#-Djavax.net.ssl.trustStorePassword=…
#-Djavax.net.ssl.trustStoreType=JKS
#…/jenkins.war
#--httpPort=-1
#--httpsKeyStore=…/cacerts
#--httpsKeyStorePassword=…
#--httpsPort=8443