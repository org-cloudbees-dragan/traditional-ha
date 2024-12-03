#!/bin/bash

set +x

echo "#### SSH Key settings"
# An SSH key gets generated under this path when you run up.sh
export SSH_KEY_ID="agent_id_rsa"
export SSH_PRIVATE_KEY_PATH="secrets/$SSH_KEY_ID"
export SSH_PUBLIC_KEY_PATH="secrets/$SSH_KEY_ID.pub"

#export SSH_PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
#export SSH_PUBLIC_KEY_PATH="$HOME/.ssh/id_rsa.pub"

########################################################################################################################

echo "#### CHECK LICENCE AVAILABLE"
# This is optional and not mandatory but helps you to avoid requesting a trial license on the welcome screen for each new startup in case the oc volume was deleted/recreated
# If you have a CloudBees wildcard license, add it to this files. They will be assigned  by casc during the startup to to the operations center
export CJOC_LICENSE_PRIVATE_KEY=secrets/cb-wildcard-license.key
export CJOC_LICENSE_CERTIFICATE=secrets/cb-wildcard-license.cert


########################################################################################################################

echo "#### Docker image settings"

# CB CI version for Operations Center and Controllers
export DOCKER_IMAGE_OC=cloudbees/cloudbees-core-oc:latest
export DOCKER_IMAGE_CLIENT_CONTROLLER=cloudbees/cloudbees-core-cm:latest
# SSH AGENT see https://hub.docker.com/r/jenkins/ssh-agent
export DOCKER_IMAGE_JENKINS_SSH_AGENT=jenkins/ssh-agent:jdk17
#export DOCKER_IMAGE_JENKINS_INBOUND_AGENT=jenkins/inbound-agent:latest-jdk17
export DOCKER_IMAGE_JENKINS_INBOUND_AGENT=eclipse-temurin:17
# ha Proxy image
export DOCKER_IMAGE_HAPROXY=haproxy:alpine
# see https://docs.linuxserver.io/images/docker-webtop/#version-tags
export DOCKER_IMAGE_BROWSER_BOX=lscr.io/linuxserver/webtop:latest

########################################################################################################################

echo "#### Docker network settings"

#### We put static IP addresses for docker containers
export IP_PREFIX=172.47
export HAPROXY_IP=$IP_PREFIX.0.5
export OC_IP=$IP_PREFIX.0.6
export CLIENT1_IP=$IP_PREFIX.0.7
export CLIENT2_IP=$IP_PREFIX.0.8
export AGENT_IP=$IP_PREFIX.0.9
export AGENT_INBOUND_1_IP=$IP_PREFIX.0.10
export BROWSER_IP=$IP_PREFIX.0.12

########################################################################################################################

echo "#### DNS/URL settings"

# Hostnames for Operations Center and Controllers
# The controllers are in HA mode, listening on a single CLIENTS_URL
# HAProxy listens for this URL and load balances between the controllers
export OC_URL=oc.ha
export CLIENTS_URL=client.ha

########################################################################################################################

echo "#### Docker host volume settings"

#### Paths on Docker host for mapped volumes
export PERSISTENCE_PREFIX=$(pwd)/cloudbees_ci_ha_volumes
export BROWSER_PERSISTENCE=$PERSISTENCE_PREFIX/browser
export OC_PERSISTENCE=$PERSISTENCE_PREFIX/oc
export CONTROLLER_PERSISTENCE=$PERSISTENCE_PREFIX/controllers
export CONTROLLER1_CACHES=$PERSISTENCE_PREFIX/controller1_caches
export CONTROLLER2_CACHES=$PERSISTENCE_PREFIX/controller2_caches
export AGENT_PERSISTENCE=$PERSISTENCE_PREFIX/ssh-agent1
export AGENT_INBOUND_1_PERSISTENCE=$PERSISTENCE_PREFIX/inbound-agent1

echo "#### Common SSL Options for Controllers and Cjoc"

export KEYSTORE="/tmp/jenkins.jks"
export CACERTS="/tmp/cacerts"
export KEYSTORE_PW="changeit"
export JENKINS_SSL_OPTS="--httpPort=-1 --httpsKeyStore=$KEYSTORE --httpsKeyStorePassword=$KEYSTORE_PW  --httpsPort=8443"
export JAVA_SSL_OPTS="-Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true -DexecutableWar.jetty.disableCustomSessionIdCookieName=true  -Djavax.net.ssl.keyStore=$CACERTS -Djavax.net.ssl.keyStorePassword=$KEYSTORE_PW  -Djavax.net.ssl.trustStore=$CACERTS -Djavax.net.ssl.trustStorePassword=$KEYSTORE_PW -Djavax.net.ssl.trustStoreType=JKS"

########################################################################################################################

echo "#### Controller settings"

#https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional#_jenkins_args
#For Docker we must set JENKINS_OPTS instead of JENKINS_ARGS
export CONTROLLER_JENKINS_OPTS="--webroot=/var/cache/cloudbees-core-cm/war --pluginroot=/var/cache/cloudbees-core-cm/plugins"
#https://docs.cloudbees.com/docs/cloudbees-ci/latest/ha/specific-ha-installation-traditional#_java_options
export CONTROLLER_JAVA_OPTS="--add-exports=java.base/jdk.internal.ref=ALL-UNNAMED --add-modules=java.se --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.management/sun.management=ALL-UNNAMED --add-opens=jdk.management/com.sun.management.internal=ALL-UNNAMED -Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true -DexecutableWar.jetty.disableCustomSessionIdCookieName=true -Dcom.cloudbees.jenkins.ha=false -Dcom.cloudbees.jenkins.replication.warhead.ReplicationServletListener.enabled=true -Djenkins.plugins.git.AbstractGitSCMSource.cacheRootDir=/var/cache/cloudbees-core-cm/caches/git -Dorg.jenkinsci.plugins.github_branch_source.GitHubSCMSource.cacheRootDir=/var/cache/cloudbees-core-cm/caches/github-branch-source -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC"

#For SSL
export CONTROLLER_JAVA_OPTS="$CONTROLLER_JAVA_OPTS $JAVA_SSL_OPTS"
export CONTROLLER_JENKINS_OPTS="$CONTROLLER_JENKINS_OPTS $JENKINS_SSL_OPTS"

#For CasC
# https://docs.cloudbees.com/docs/cloudbees-ci/latest/casc-oc/configure-oc-traditional#_adding_the_java_system_property
# We assign the controller casc bundle directly, comment out if you don't want to use casc
export CONTROLLER_JAVA_OPTS="$CONTROLLER_JAVA_OPTS -Dcore.casc.config.bundle=/var/jenkins_home/cascbundle"

########################################################################################################################

echo "#### Operations center setting"
export CJOC_JAVA_OPTS="-XX:+AlwaysPreTouch -XX:+UseStringDeduplication -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -Dcom.cloudbees.jenkins.ha=false"

#For SSL
export CJOC_JAVA_OPTS="$CJOC_JAVA_OPTS $JAVA_SSL_OPTS"
export CJOC_JENKINS_OPTS="$JENKINS_SSL_OPTS"

#For CasC
# https://docs.cloudbees.com/docs/cloudbees-ci/latest/casc-oc/configure-oc-traditional#_adding_the_java_system_property
# We assign the cjoc casc bundle, comment out if you don't want to use casc
export CJOC_JAVA_OPTS="$CJOC_JAVA_OPTS -Dcore.casc.config.bundle=/var/jenkins_home/cascbundle"
# Cjoc login user and password
export CJOC_LOGIN_USER="admin"
export CJOC_LOGIN_PW="admin"

########################################################################################################################