#!/bin/bash

# Hostnames for Operations Center and Controllers
# The controllers are in HA mode, listening on a single CLIENTS_URL
# HAProxy listens for this URL and load balances between the controllers
export OC_URL=oc.ha
export CLIENTS_URL=client.ha

# CB CI version for Operations Center and Controllers
#export DOCKER_IMAGE_OC=cloudbees/cloudbees-core-oc:2.426.3.3
export DOCKER_IMAGE_OC=cloudbees/cloudbees-core-oc:latest
#export DOCKER_IMAGE_CLIENT=cloudbees/cloudbees-core-cm:2.426.3.3
export DOCKER_IMAGE_CLIENT=cloudbees/cloudbees-core-cm:latest

# We put static IP addresses for docker containers
export IP_PREFIX=172.47
export HAPROXY_IP=$IP_PREFIX.0.5
export OC_IP=$IP_PREFIX.0.6
export CLIENT1_IP=$IP_PREFIX.0.7
export CLIENT2_IP=$IP_PREFIX.0.8
export AGENT_IP=$IP_PREFIX.0.9
export BROWSER_IP=$IP_PREFIX.0.10

# Paths on Docker host for mapped volumes
export PERSISTENCE_PREFIX=$(pwd)/jenkins_ha
export BROWSER_PERSISTENCE=$PERSISTENCE_PREFIX/browser
export OC_PERSISTENCE=$PERSISTENCE_PREFIX/oc
export CONTROLLER_PERSISTENCE=$PERSISTENCE_PREFIX/controllers
export CONTROLLER1_CACHES=$PERSISTENCE_PREFIX/controller1_caches
export CONTROLLER2_CACHES=$PERSISTENCE_PREFIX/controller2_caches
export AGENT_PERSISTENCE=$PERSISTENCE_PREFIX/ssh-agent1
#export JENKINS_AGENT_SSH_PUBKEY="ssh-rsa AD_YOUR_JENKINS_AGENT_SSH_PUBKEY"
export JENKINS_AGENT_SSH_PUBKEY=$(cat ~/.ssh/id_rsa.pub)

