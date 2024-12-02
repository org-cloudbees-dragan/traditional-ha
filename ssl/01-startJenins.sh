#! /bin/bash

#Download war
#curl -O https://downloads.cloudbees.com/cloudbees-core/traditional/client-master/rolling/war/2.462.2.2/cloudbees-core-cm.war

export JENKINS_HOME="./jenkins-home"
export JENKINS_URL=http://client.ha:8444
export KEYSTORE=$(realpath ./jenkins.jks)
java \
-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true \
-DexecutableWar.jetty.disableCustomSessionIdCookieName=true \
-Dcom.cloudbees.jenkins.ha=false \
-jar cloudbees-core-cm.war \
--httpPort=-1 \
--httpsKeyStore=$KEYSTORE \
--httpsKeyStorePassword=changeit \
--httpsPort=8444