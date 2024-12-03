#! /bin/bash
#cat jenkins.crt > jenkins.pem
cat jenkins.crt jenkins.key > jenkins.pem
keytool -delete -alias jenkins -keystore cacerts
keytool -import -noprompt -keystore cacerts -file jenkins.pem -storepass changeit -alias jenkins;