# Test for demo

## Test Pipeline 

[Jenkinsfile-ssh-agent.groovy](Jenkinsfile-ssh-agent.groovy) is a simple test pipeline that prints out the agent host name as wel as the controller replica hostname

## Test script 

* Running the [testJobTrigger.sh](testJobTrigger.sh]) will trigger the Test Pipeline job in a loop by curl
* Curl doesnt send the cookie back in the next request so that each new request will get balanced by HAProxy to the Controller with less workload available. 



You need to create an ADMIN TOKEN on the Operations Center first.

Run the script:

> ./testJobTrigger.sh <ADMIN_TOKEN>

output:  (You can se each request  passes another controller replica) 

```
#######################################
start build of Job: testpipeline
LOCATION:                 http://client.ha/queue/item/1661113525441582349/
CONTROLLER_REPLICA:       8f09fe15eb03@7
CONTROLLER_REPLICA_IP:    172.47.0.7
#######################################
start build of Job: testpipeline
LOCATION:                 http://client.ha/queue/item/1042037895850911901/
CONTROLLER_REPLICA:       ca6d130f20e4@6
CONTROLLER_REPLICA_IP:    172.47.0.8
#######################################
start build of Job: testpipeline
LOCATION:                 http://client.ha/queue/item/724259527559776060/
CONTROLLER_REPLICA:       8f09fe15eb03@7
CONTROLLER_REPLICA_IP:    172.47.0.7
#######################################
start build of Job: testpipeline
LOCATION:                 http://client.ha/queue/item/5229488099980267107/
CONTROLLER_REPLICA:       ca6d130f20e4@6
CONTROLLER_REPLICA_IP:    172.47.0.8
...
```