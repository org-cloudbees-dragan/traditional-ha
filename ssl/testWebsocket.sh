#! /bin/bash

HOSTNAME=oc.ha
JENKINS_URL=https://${HOSTNAME}:443
#curl --http1.1 -i -N --header "Connection: Upgrade" --header "Upgrade: websocket" \
# --header "Host: $HOSTNAME" --header "Origin: $HOSTNAME" --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
# --header "Sec-WebSocket-Version: 13" --header "Secret-Key:SECRET" \
# --header "Node-Name:my-agent" $JENKINS_URL/wscontrollers/

 # --header "X-Remoting-Capability:rO0ABXNyABpodWRzb24ucmVtb3RpbmcuQ2FwYWJpbGl0eQAAAAAAAAABAgABSgAEbWFza3hwAAAAAAAAAf4=" \



#websocat -v --basic-auth "admin:1159bbc243a046c3f85e73a67c0bbe1546" wss://oc.ha:443/wsecho/ 2>&1


export KEYSTORE=$(realpath ./jenkins.jks)
export CACERTS=$(realpath ./cacerts)
export KS_PW="changeit"
# #-Djavax.net.debug=ssl
# -Djavax.net.debug=all
java \
-Djavax.net.ssl.keyStore=$CACERTS \
-Djavax.net.ssl.keyStorePassword=$KS_PW \
-Djavax.net.ssl.trustStore=$CACERTS \
-Djavax.net.ssl.trustStorePassword=$KS_PW \
-Djavax.net.ssl.trustStoreType=JKS \
-jar jenkins-cli.jar -auth "admin:XXXXX"  -webSocket -s https://client.ha/   help
